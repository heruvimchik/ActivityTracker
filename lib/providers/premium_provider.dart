import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'auth_provider.dart';

const String revenueKey = 'YVaAsDlsahIBDqnOGVYgMwCDZfAhRzJG';

class PremiumProvider with ChangeNotifier {
  bool _isPro = false;
  Offerings? offerings;
  PurchaserInfo? _purchaserInfo;
  final AuthProvider _authProvider;

  PremiumProvider(this._authProvider) {
    initPremium();
  }
  bool get isPro => _isPro;

  void _getPro() {
    if (_purchaserInfo != null) {
      if (_purchaserInfo!.entitlements.all.isNotEmpty) {
        _isPro = _purchaserInfo!.entitlements.all['Pro']!.isActive;
      } else {
        _isPro = false;
      }
    }
    notifyListeners();
  }

  Future<void> initPremium() async {
    await Purchases.setup(revenueKey);
    try {
      _purchaserInfo = await Purchases.getPurchaserInfo();
      offerings = await Purchases.getOfferings();
    } catch (e) {}
    _getPro();
    if (_isPro) {
      _authProvider.launchAutoBackup();
    }
  }

  Future<void> refreshPurchases() async {
    try {
      _purchaserInfo = await Purchases.getPurchaserInfo();
      offerings = await Purchases.getOfferings();
    } catch (e) {}
    _getPro();
  }

  Future<void> restorePurchase() async {
    try {
      _purchaserInfo = await Purchases.restoreTransactions();
    } on PlatformException catch (e) {
      if (int.parse(e.code) != PurchasesErrorCode.purchaseCancelledError.index)
        throw _getErrorMessage(e);
    } catch (e) {}
    _getPro();
  }

  Future<void> makePurchase() async {
    try {
      offerings = await Purchases.getOfferings();
      _purchaserInfo =
          await Purchases.purchasePackage(offerings!.current!.lifetime!);
    } on PlatformException catch (e) {
      if (int.parse(e.code) != PurchasesErrorCode.purchaseCancelledError.index)
        throw _getErrorMessage(e);
    } catch (e) {}
    _getPro();
  }

  String _getErrorMessage(PlatformException error) {
    final errorCode = PurchasesErrorHelper.getErrorCode(error);
    String message = '';
    switch (errorCode) {
      case PurchasesErrorCode.invalidAppleSubscriptionKeyError:
        message = "Invalid apple subscription key error";
        break;
      case PurchasesErrorCode.unknownBackendError:
        message = "Unknown backend error";
        break;
      case PurchasesErrorCode.unexpectedBackendResponseError:
        message = "Unexpected backend response error";
        break;
      case PurchasesErrorCode.storeProblemError:
        message = "Store problem error";
        break;
      case PurchasesErrorCode.receiptInUseByOtherSubscriberError:
        message = "Receipt in use by other subscriber error";
        break;
      case PurchasesErrorCode.receiptAlreadyInUseError:
        message = "Receipt already in use error";
        break;
      case PurchasesErrorCode.purchaseNotAllowedError:
        message = "Purchase not allowed error";
        break;
      case PurchasesErrorCode.purchaseInvalidError:
        message = "Purchase invalid error";
        break;
      case PurchasesErrorCode.purchaseCancelledError:
        message = "Purchase cancelled error";
        break;
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        message = "Product not available for purchase error";
        break;
      case PurchasesErrorCode.productAlreadyPurchasedError:
        message = "Product already purchased error";
        break;
      case PurchasesErrorCode.paymentPendingError:
        message = "Payment pending error";
        break;
      case PurchasesErrorCode.operationAlreadyInProgressError:
        message = "Operation already in progress error";
        break;
      case PurchasesErrorCode.networkError:
        message = "Network error";
        break;
      case PurchasesErrorCode.missingReceiptFileError:
        message = "Missing receipt file error";
        break;
      case PurchasesErrorCode.invalidSubscriberAttributesError:
        message = "Invalid subscriber attributes error";
        break;
      case PurchasesErrorCode.invalidReceiptError:
        message = "Invalid receipt error";
        break;
      case PurchasesErrorCode.invalidAppUserIdError:
        message = "Invalid app user id error";
        break;
      case PurchasesErrorCode.invalidCredentialsError:
        message = "invalid credentials error";
        break;
      case PurchasesErrorCode.insufficientPermissionsError:
        message = "Insufficient permissions error";
        break;
      case PurchasesErrorCode.ineligibleError:
        message = "Ineligible error";
        break;
      default:
        message = "Unknown error";
        break;
    }
    return message;
  }
}
