import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogon = true;
  var email = "";
  var password = "";
  var username = "";
  File? selectedImage;
  var _isUploading = false;

  void _submit() async {
    print("is submitting ....");
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogon && selectedImage == null) {
      return;
    }

    _formKey.currentState!.save();
    try {
      setState(() {
        _isUploading = true;
      });
      if (_isLogon) {
        final response = await _firebase.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: email, password: password);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredentials.user!.uid}.jpg");
        await storageRef.putFile(selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredentials.user!.uid)
            .set({
          "username": username,
          "email": email,
          "image_url": imageUrl,
        });
      }
    } on FirebaseAuthException catch (e) {
      print(e);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Authentication failed"),
        ),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            margin:
                const EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
            width: 200,
            child: Image.asset("assets/images/chat.png"),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLogon)
                      UserImagePicker(onSelectImage: (image) {
                        selectedImage = image;
                      }),
                    Text(_isLogon
                        ? "Sign in to your account"
                        : "Create an account"),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: "Email Address"),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains("@")) {
                          return "Please enter a valid email address.";
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        email = newValue.toString();
                      },
                    ),
                    if (!_isLogon)
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Username"),
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return "Username must be at least 6 characters long!";
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          username = newValue.toString();
                        },
                      ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return "Password must be at least 6 characters long!";
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        password = newValue.toString();
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (_isUploading) const CircularProgressIndicator(),
                    if (!_isUploading)
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            fixedSize: const Size(250, 45)),
                        child: Text(_isLogon ? "sign in" : "sign up"),
                      ),
                    if (!_isUploading)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogon = !_isLogon;
                          });
                        },
                        child: Text(_isLogon
                            ? "Create an account"
                            : "I already have an account"),
                      ),
                  ],
                ),
              ),
            ),
          )
        ]),
      )),
    );
  }
}
