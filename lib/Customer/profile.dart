import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/paymentOption.dart';
import '../Authentication/loginPage.dart';

//todo profil ekranı

class Profile extends StatefulWidget {
  const Profile({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _selectedOption = 'Option 1'; //DropDown button için

  final List<TextEditingController> _controllers = [
    TextEditingController()
  ]; //Comment kısmı için

  void _addTextField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeTextField(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Name"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: ClipOval(
                child: Container(
                  height: 150,
                  width: 150,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://images.unsplash.com/photo-1517849845537-4d257902454a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1935&q=80"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const PaymentOption())); //boş sayfaya yönlendiriyor amaç hata vermemesi
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(150, 50),
                  ),
                  child: const Text("Payment Settings"),
                ),
                DropdownButtonWidget(
                  selectedOption: _selectedOption,
                  onOptionChanged: (newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 50),
            Column(
              children: [
                for (var i = 0; i < _controllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: TextFormField(
                              controller: _controllers[i],
                              decoration: InputDecoration(
                                labelText: 'Comment ${i + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () => _removeTextField(i),
                            icon: Icon(Icons.delete)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addTextField,
                  child: const Text('Yorum Ekleme'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      )),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DropdownButtonWidget extends StatelessWidget {
  const DropdownButtonWidget({
    Key? key,
    required this.selectedOption,
    required this.onOptionChanged,
  }) : super(key: key);

  final String selectedOption;
  final Function(String?) onOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 50,
      child: DropdownButton<String>(
        value: selectedOption,
        onChanged: onOptionChanged,
        items: <String>['Option 1', 'Option 2', 'Option 3', 'Option 4']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}
