import 'dart:convert';
import 'dart:ui';

class Record {
  final String recordID;
  DateTime endTime;
  DateTime startTime;
  Record({this.recordID, this.startTime, this.endTime});

  Record copyWith({DateTime startTime, DateTime endTime}) {
    return Record(
      recordID: this.recordID,
      endTime: endTime ?? this.endTime,
      startTime: startTime ?? this.startTime,
    );
  }
}

class Project {
  final String projectID;
  String description;
  final List<Record> records;
  Color color;

  Project({this.projectID, this.description, this.records, this.color});

  Project copyWith(
      {String updDescription, Color updColor, List<Record> updRecords}) {
    return Project(
        projectID: this.projectID,
        description: updDescription ?? this.description,
        records: updRecords ?? this.records,
        color: updColor ?? this.color);
  }

  factory Project.fromDB(Map<String, dynamic> parsedJson) {
    final List<dynamic> rec = jsonDecode(parsedJson['records']);
    final listRecords = rec
        .map((item) => Record(
              recordID: item['recordID'],
              endTime: (item['endTime'] != null)
                  ? DateTime.parse(item['endTime'])
                  : null,
              startTime: (item['startTime'] != null)
                  ? DateTime.parse(item['startTime'])
                  : null,
            ))
        .toList();
    return Project(
      projectID: parsedJson['projectID'],
      description: parsedJson['description'],
      records: listRecords,
      color: Color(parsedJson['color'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'projectID': projectID,
      'description': description,
      'records': jsonEncode(records
          .map((item) => {
                'recordID': item.recordID,
                'endTime': item.endTime?.toIso8601String(),
                'startTime': item.startTime?.toIso8601String(),
              })
          .toList()),
      'color': color.value,
    };
  }
}
