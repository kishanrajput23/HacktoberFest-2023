import 'package:flutter/material.dart';
import 'package:hive_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  TextEditingController names = TextEditingController();

  String _name = 'ww';

  Future<void> saveShared() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('nameFixed', _name);
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome to Hive Todo"),
              const SizedBox(
                height: 20,
              ),
              const Text("Please input your name"),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: names,
                maxLength: 15,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(),
                    ),
                  );
                  if (names.text.isNotEmpty) {
                    setState(() {
                      _name = names.text;
                      saveShared();
                    });
                  } else {
                    //show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Data tidak boleh kosong!"),
                      ),
                    );
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
