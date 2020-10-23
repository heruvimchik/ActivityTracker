import 'package:activityTracker/helpers/const.dart';
import 'package:activityTracker/providers/premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
        title: Text('Pro version'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get access to all the app content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          //isPro ? Text('Pro') : UpsellScreen()
          Text('Pro'), UpsellScreen()
        ],
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
        Padding(
          padding: const EdgeInsets.all(8.0),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: RaisedButton(
            shape: StadiumBorder(),
            color: Colors.indigo,
            child: Text(
              'Upgrade for ${premium.offerings?.current?.lifetime?.product?.priceString ?? ''}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            onPressed: () async {
              try {
                await premium.makePurchase();
              } catch (error) {
                FlushBarMy.errorBar(text: error.toString())..show(context);
              }
            },
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: RaisedButton(
            shape: StadiumBorder(),
            color: Colors.indigo,
            child: Text(
              'Restore Purchase',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            onPressed: () async {
              try {
                await premium.restorePurchase();
              } catch (error) {
                FlushBarMy.errorBar(text: error.toString())..show(context);
              }
            },
          ),
        ),
      ],
    );
  }
}
