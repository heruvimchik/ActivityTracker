import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';

import 'settings_provider.dart';

class AuthProvider with ChangeNotifier {
  GoogleSignInAccount? googleSignInAccount;
  late GoogleHttpClient _client;
  late ga.DriveApi _drive;
  Timer? _authTimer;
  final SettingsProvider _settingsProvider;

  final auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.appdata']);
  Future<ga.FileList>? filesLoaded;

  bool _isLoadingFiles = false;

  AuthProvider(this._settingsProvider);

  bool get isLoadingFiles => _isLoadingFiles;

  Future<void> logoutFromGoogle() async {
    if (_authTimer != null) _authTimer!.cancel();

    await googleSignIn.signOut();
    await auth.signOut();
  }

  Future<void> _init() async {
    googleSignInAccount = googleSignIn.currentUser;
    if (googleSignInAccount == null)
      googleSignInAccount = await googleSignIn.signInSilently();
    _client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    _drive = ga.DriveApi(_client);
  }

  Future<void> uploadFileToGoogleDrive() async {
    _isLoadingFiles = true;
    notifyListeners();
    try {
      await _init();
      ga.File request = ga.File();
      Directory dbPath = await getApplicationDocumentsDirectory();
      final file = path.join(dbPath.path, 'projects.db');
      final fileToUpload = File(file);
      request.parents = ["appDataFolder"];
      request.name = DateTime.now().millisecondsSinceEpoch.toString();
      //request.createdTime = DateTime.parse(timeFormat.format(DateTime.now()));
      await _drive.files.create(
        request,
        uploadMedia:
            ga.Media(fileToUpload.openRead(), fileToUpload.lengthSync()),
      );
      filesLoaded = _drive.files.list(spaces: 'appDataFolder');
    } catch (error) {
      throw error.toString();
    } finally {
      _isLoadingFiles = false;
      notifyListeners();
    }
  }

  void fetchFiles(bool isPro) {
    if (isPro) launchAutoBackup();
    filesLoaded = listGoogleDriveFiles();
  }

  Future<ga.FileList> listGoogleDriveFiles() async {
    await _init();
    return _drive.files.list(spaces: 'appDataFolder');
  }

  Future<void> silentLogin() async {
    googleSignInAccount = googleSignIn.currentUser;
    if (googleSignInAccount == null)
      googleSignInAccount = await googleSignIn.signInSilently();

    if (googleSignInAccount == null) {
      googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount == null) return;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleSignInAccount!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await auth.signInWithCredential(credential);
  }

  Future<void> downloadGoogleDriveFile(
      {required String gdID, required ProjectsProvider projects}) async {
    await _init();
    Directory dbPath = await getApplicationDocumentsDirectory();
    final filepath = path.join(dbPath.path, 'projects.db');
    ga.Media file = await _drive.files
        .get(gdID, downloadOptions: ga.DownloadOptions.fullMedia) as ga.Media;

    final saveFile = File(filepath);
    List<int> dataStore = [];
    file.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () async {
      await saveFile.writeAsBytes(dataStore);
      projects.fetchProjects(initNotification: false);
    }, onError: (error) {});
  }

  Future<void> deleteGoogleDriveFile({required String gdID}) async {
    await _init();
    await _drive.files.delete(gdID);
    filesLoaded = _drive.files.list(spaces: 'appDataFolder');
    notifyListeners();
  }

  void launchAutoBackup() async {
    if (_authTimer != null) _authTimer!.cancel();
    await _settingsProvider.settingsLoaded;
    if (auth.currentUser == null ||
        _settingsProvider.expireDate == null ||
        _settingsProvider.autoBackup == 0) return;
    final timeToExpire =
        _settingsProvider.expireDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer.periodic(Duration(seconds: timeToExpire), (timer) async {
      _authTimer!.cancel();
      try {
        await uploadFileToGoogleDrive();
        await _settingsProvider.setAutoExpire(_settingsProvider.autoBackup);
      } catch (e) {}
      setTimerAuto();
    });
  }

  void setTimerAuto() {
    if (_authTimer != null) _authTimer!.cancel();
    if (_settingsProvider.autoBackup == 0 || auth.currentUser == null) return;
    _authTimer = Timer.periodic(
        _settingsProvider.autoExpireList[_settingsProvider.autoBackup],
        (timer) async {
      try {
        await uploadFileToGoogleDrive();
        await _settingsProvider.setAutoExpire(_settingsProvider.autoBackup);
      } catch (e) {}
    });
  }
}

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;
  GoogleHttpClient(this._headers) : super();
  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));
  @override
  Future<http.Response> head(Object url, {Map<String, String>? headers}) =>
      super.head(url as Uri, headers: headers!..addAll(_headers));
}
