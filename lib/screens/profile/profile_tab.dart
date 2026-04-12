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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userModel;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (userProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: screenWidth * 0.12),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Failed to load profile",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(userProvider.errorMessage!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (user == null) return Center(child: CircularProgressIndicator());

    if (_lastSyncedUid != user.uid ||
        (_lastSyncedUid == null && user != null)) {
      if (!_editing) {
        _nameController.text = user.name ?? '';
        _addressController.text = user.address ?? '';
        _emailController.text = user.email ?? '';
        _lastSyncedUid = user.uid;
      }
    }

    final headerHeight = screenHeight * 0.2;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(screenWidth * 0.08),
                      bottomRight: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -screenHeight * 0.07,
                  child: CircleAvatar(
                    radius: screenWidth * 0.15,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: screenWidth * 0.14,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: screenWidth * 0.15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (!_editing)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () => setState(() => _editing = true),
                    ),
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.08),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  Text(
                    user.name ?? "Set Name",
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.006),
                  Text(
                    user.phone,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                  Divider(height: screenHeight * 0.05),

                  _buildField(
                    "Name",
                    _nameController,
                    Icons.person,
                    screenWidth,
                    screenHeight,
                  ),
                  _buildField(
                    "Address",
                    _addressController,
                    Icons.location_on,
                    screenWidth,
                    screenHeight,
                  ),
                  _buildField(
                    "Email",
                    _emailController,
                    Icons.email,
                    screenWidth,
                    screenHeight,
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  if (!_editing) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "KYC Verification",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _getStatusBadge(
                                user.verificationStatus,
                                screenWidth,
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.012),
                          Text(
                            _getStatusMessage(user.verificationStatus),
                            style: TextStyle(
                              fontSize: screenWidth * 0.033,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.verificationStatus != 'verified' &&
                              user.verificationStatus != 'pending') ...[
                            SizedBox(height: screenHeight * 0.02),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const KYCScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.shield_outlined,
                                  size: screenWidth * 0.045,
                                ),
                                label: Text(
                                  user.verificationStatus == 'rejected'
                                      ? "Re-submit KYC"
                                      : "Complete KYC",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.025,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
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
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(fontSize: screenWidth * 0.035),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.05),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                            child: Text(
                              "Save Changes",
                              style: TextStyle(fontSize: screenWidth * 0.035),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(height: screenHeight * 0.025),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status, double screenWidth) {
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
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenWidth * 0.012,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: screenWidth * 0.035, color: color),
          SizedBox(width: screenWidth * 0.012),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    double screenWidth,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
      child: TextField(
        controller: controller,
        enabled: _editing,
        style: TextStyle(fontSize: screenWidth * 0.04),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: screenWidth * 0.05),
          labelText: label,
          filled: !_editing,
          fillColor: _editing ? null : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}
