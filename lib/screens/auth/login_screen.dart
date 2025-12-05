import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';
  UserRole _role = UserRole.student;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLogin) {
        await auth.login(_email, _password);
      } else {
        await auth.signUp(
          name: _name,
          email: _email,
          password: _password,
          role: _role,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r == UserRole.student ? 'Student' : 'Teacher'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                  onSaved: (v) => _email = v!,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter password';
                    if (!_isLogin) {
                      // Password validation logic is in AuthService, but good to have UI feedback too
                      // We can rely on AuthService error or duplicate logic here.
                      // For better UX, let's keep it simple here and let service throw error,
                      // OR implement the regex check here too.
                      // The prompt asked for "Password Validation Logic", so I'll add it here for immediate feedback.
                       if (v.length < 8) return 'Min 8 chars';
                       if (!v.contains(RegExp(r'[A-Z]'))) return 'Needs 1 Upper';
                       if (!v.contains(RegExp(r'[a-z]'))) return 'Needs 1 Lower';
                       if (!v.contains(RegExp(r'[0-9]'))) return 'Needs 1 Numeric';
                       if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Needs 1 Special';
                    }
                    return null;
                  },
                  onSaved: (v) => _password = v!,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Create Account' : 'I have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
