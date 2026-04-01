import 'package:dhukuti/screens/kyc/kyc_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dhukuti/models/user_model.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  bool _editing = false;
  
  String? _lastSyncedUid;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await context.read<UserProvider>().updateUserProfile(
        name: _nameController.text,
        address: _addressController.text,
        email: _emailController.text,
      );
      setState(() => _editing = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userModel;

    if (userProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text("Failed to load profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(userProvider.errorMessage!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (user == null) return const Center(child: CircularProgressIndicator());

    if (_lastSyncedUid != user.uid || (_lastSyncedUid == null && user != null)) {
       if (!_editing) {
          _nameController.text = user.name ?? '';
          _addressController.text = user.address ?? '';
          _emailController.text = user.email ?? '';
          _lastSyncedUid = user.uid;
       }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.2;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎨 Header with Avatar
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                if (!_editing)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => setState(() => _editing = true),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 60),
            
            // 📝 User Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   Text(
                    user.name ?? "Set Name",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.phone,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Divider(height: 40),
                  
                  _buildField("Address", _addressController, Icons.location_on),
                  _buildField("Email", _emailController, Icons.email),
                  
                  const SizedBox(height: 30),

                  // 🛡️ KYC Verification Section
                  if (!_editing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "KYC Verification",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              _getStatusBadge(user.verificationStatus),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getStatusMessage(user.verificationStatus),
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          if (user.verificationStatus != 'verified' && user.verificationStatus != 'pending') ...[
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                   Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const KYCScreen()),
                                  );
                                },
                                icon: const Icon(Icons.shield_outlined, size: 18),
                                label: Text(user.verificationStatus == 'rejected' ? "Re-submit KYC" : "Complete KYC"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  
                  if (_editing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _editing = false;
                                _nameController.text = user.name ?? '';
                                _addressController.text = user.address ?? '';
                                _emailController.text = user.email ?? '';
                              });
                            },
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text("Save Changes"),
                          ),
                        ),
                      ],
                    )
                  else
                     const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'verified':
        color = Colors.green;
        label = "Verified";
        icon = Icons.verified;
        break;
      case 'pending':
        color = Colors.orange;
        label = "Pending";
        icon = Icons.hourglass_empty;
        break;
      case 'rejected':
        color = Colors.red;
        label = "Rejected";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = "Unverified";
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'verified':
        return "Your account is fully verified. You can now trade Gold and Silver.";
      case 'pending':
        return "Your documents are under review. This usually takes 24-48 hours.";
      case 'rejected':
        return "Your verification was rejected. Please check the reason and re-submit.";
      default:
        return "Complete your KYC verification to start trading Gold and Silver.";
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        enabled: _editing,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: !_editing,
          fillColor: _editing ? null : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}
