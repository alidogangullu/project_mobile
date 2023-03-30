import 'package:flutter/material.dart';

//boş sayfa dolması lazım
class PaymentOption extends StatelessWidget {
  const PaymentOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Option'),
      ),
      body: Center(
        child: Text(
          'Bomboş buralar',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
