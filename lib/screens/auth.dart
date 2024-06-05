import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _enyteredEmail = '';
  var _enteredPassword = '';
  var _isLogin = true;
  File? _selectedImage;
  var _isAuthincating = false;
  var _enterusername = '';

  void _submit() async {
    final isvalid = _form.currentState!.validate();

    if (!isvalid || !_isLogin && _selectedImage == null) {
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthincating = true;
      });
      if (_isLogin) {
        final UserCredential = await _firebase.signInWithEmailAndPassword(
            email: _enyteredEmail, password: _enteredPassword);
        print(UserCredential);
      } else {
        final UserCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enyteredEmail, password: _enteredPassword);
        print(UserCredential);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${UserCredential.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageurl = await storageRef.getDownloadURL();
        print(imageurl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(UserCredential.user!.uid)
            .set({
          'username': _enterusername,
          'email': _enyteredEmail,
          'image-url': imageurl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Auth failed')));
      setState(() {
        _isAuthincating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enyteredEmail = value!;
                              },
                            ),
                            if(!_isLogin)
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'username'),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length < 4) {
                                  return 'Please enter at least 4characters';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enterusername = value!;
                              },
                            ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (_isAuthincating)
                              const CircularProgressIndicator(),
                            if (!_isAuthincating)
                              ElevatedButton(
                                onPressed: _submit,
                                child: Text(_isLogin ? 'Login' : 'SignUp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                              ),
                            if (!_isAuthincating)
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(_isLogin
                                      ? 'Create an account'
                                      : 'I already have an account'))
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
