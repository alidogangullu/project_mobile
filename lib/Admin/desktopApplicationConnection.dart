import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_mobile/customWidgets.dart';

class DesktopAppConnect extends StatefulWidget {
  const DesktopAppConnect({Key? key, required this.restaurantId})
      : super(key: key);
  final String restaurantId;

  @override
  _DesktopAppConnectState createState() => _DesktopAppConnectState();
}

class _DesktopAppConnectState extends State<DesktopAppConnect> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isAccountAvailable = false;
  String _waiterEmail = '';

  @override
  void initState() {
    super.initState();
    _checkWaiterAccountAvailability();
  }

  Future<void> _checkWaiterAccountAvailability() async {
    DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(widget.restaurantId)
        .get();

    if (restaurantSnapshot.exists &&
        restaurantSnapshot['waiterAppAccount'] != null) {
      String waiterUserId = restaurantSnapshot['waiterAppAccount'];
      DocumentSnapshot waiterSnapshot = await FirebaseFirestore.instance
          .collection('waiterAppLogins')
          .doc(waiterUserId)
          .get();

      if (waiterSnapshot.exists) {
        setState(() {
          _isAccountAvailable = true;
          _waiterEmail = waiterSnapshot['email'];
        });
      }
    }
  }

  Future<void> _connectWaiterAccount() async {
    setState(() {
      _isLoading = true;
    });
    final waiterAppLogins = await FirebaseFirestore.instance
        .collection('waiterAppLogins')
        .where('email', isEqualTo: _emailController.text)
        .get();
    final userDoc = waiterAppLogins.docs.first;

    FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(widget.restaurantId)
        .update({
      'waiterAppAccount' : userDoc.id,
    });

    FirebaseFirestore.instance
        .collection('waiterAppLogins')
        .doc(userDoc.id)
        .update({
      'restaurantId' : widget.restaurantId,
    });

    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _waiterEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccountAvailable) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            "Connect Waiter Application",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'Waiter account already exists for this restaurant:',
                style: TextStyle(fontSize: 16),
              ),
            ),
            Text(
              _waiterEmail,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            _isLoading
                ? const CircularProgressIndicator()
                : menuButton('Send Password Reset Link', _sendPasswordResetEmail),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            "Connect Waiter Application",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Account Email Address',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            textInputField(context, 'Waiter Application Account Email', _emailController, false),
            _isLoading
                ? const CircularProgressIndicator()
                : menuButton("Connect Waiter Application Account", _connectWaiterAccount)
          ],
        ),
      );
    }
  }
}