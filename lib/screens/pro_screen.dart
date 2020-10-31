import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:activityTracker/helpers/const.dart';
import 'package:activityTracker/providers/premium_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ProScreen extends StatefulWidget {
  @override
  _ProScreenState createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    Provider.of<PremiumProvider>(context, listen: false).refreshPurchases();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PremiumProvider>().isPro;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(LocaleKeys.Premium.tr(), style: TextStyle(fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                height: 130,
                child: Image.asset(
                  'assets/upgrade.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                LocaleKeys.OfferPro.tr(),
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            isPro
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      LocaleKeys.Thankyou.tr(),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 15,
                      ),
                    ),
                  )
                : UpsellScreen()
          ],
        ),
      ),
    );
  }
}

class UpsellScreen extends StatefulWidget {
  @override
  _UpsellScreenState createState() => _UpsellScreenState();
}

class _UpsellScreenState extends State<UpsellScreen> {
  @override
  Widget build(BuildContext context) {
    final premium = Provider.of<PremiumProvider>(context, listen: false);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 15,
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: RaisedButton(
            shape: StadiumBorder(),
            color: Colors.indigo,
            child: Text(
              '${LocaleKeys.Upgrade.tr()} ${premium.offerings?.current?.lifetime?.product?.priceString ?? ''}',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            onPressed: () async {
              try {
                await premium.makePurchase();
              } catch (error) {
                if (mounted)
                  FlushBarMy.errorBar(text: error.toString())..show(context);
              }
            },
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: RaisedButton(
            shape: StadiumBorder(),
            color: Colors.grey[300],
            child: Text(
              LocaleKeys.RestorePurchase.tr(),
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            onPressed: () async {
              try {
                await premium.restorePurchase();
              } catch (error) {
                if (mounted)
                  FlushBarMy.errorBar(text: error.toString())..show(context);
              }
            },
          ),
        ),
      ],
    );
  }
}
