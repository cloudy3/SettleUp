import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _selectedAvatar; // Holds the selected avatar
  bool _isLoading = false;

  // List of preset avatars (use asset paths or URLs)
  final List<String> _avatars = [
    "assets/avatars/dog.jpg",
    "assets/avatars/pig.jpg",
    "assets/avatars/panda.jpg",
    "assets/avatars/fox.jpg",
    "assets/avatars/penguin.jpg",
    "assets/avatars/llama.jpg",
    "assets/avatars/monkey.jpg",
    "assets/avatars/deer.jpg",
    "assets/avatars/sloth.jpg",
    "assets/avatars/lion.jpg",
    "assets/avatars/rabbit.jpg",
    "assets/avatars/tiger.jpg",
    "assets/avatars/cat.jpg",
    "assets/avatars/bear.jpg",
    "assets/avatars/koala.jpg",
  ];

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required.")),
      );
      return;
    }

    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an avatar.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user signed in");

      // Save user details to Firestore
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .update({
        "name": _nameController.text,
        "avatarName": _selectedAvatar,
        "onboardingCompleted": true,
      });

      // Navigate to the home screen or another screen
      Navigator.of(context).pushReplacementNamed("/home");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Selection
                const Text(
                  "Select an Avatar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _avatars.map((avatar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(avatar),
                        child: _selectedAvatar == avatar
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 30)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Name Input Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Your Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save and Continue"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
