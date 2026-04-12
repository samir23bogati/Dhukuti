import 'dart:io';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        if (type == 'front') {
          _frontImage = File(pickedFile.path);
        } else if (type == 'back') {
          _backImage = File(pickedFile.path);
        } else if (type == 'selfie') {
          _selfieImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null || _backImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<UserProvider>().submitKYC(
        citizenshipFront: _frontImage!,
        citizenshipBack: _backImage!,
        selfie: _selfieImage!,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("KYC documents submitted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting KYC: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final user = context.watch<UserProvider>().userModel;
    final status = user?.verificationStatus ?? 'unverified';

    if (status == 'pending') {
      return Scaffold(
        appBar: AppBar(title: const Text("KYC Verification")),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: screenWidth * 0.2, color: Colors.orange),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  "Verification Pending",
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.015),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Text(
                    "Your documents are being reviewed by the admin. This usually takes 24-48 hours.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Go Back", style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (status == 'verified') {
      return Scaffold(
        appBar: AppBar(title: const Text("KYC Verification")),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: screenWidth * 0.2, color: Colors.green),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  "Verified",
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text("Your account is verified and ready for trading.", style: TextStyle(fontSize: screenWidth * 0.035)),
                SizedBox(height: screenHeight * 0.04),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Go Back", style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Submit KYC")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == 'rejected') ...[
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: screenWidth * 0.06),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: Text(
                        "Rejected: ${user?.rejectionReason ?? 'Please re-upload clear documents.'}",
                        style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
            ],
            Text(
              "Upload Citizenship (Nagarikta)",
              style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Expanded(
                  child: _UploadCard(
                    title: "Front Side",
                    image: _frontImage,
                    onTap: () => _pickImage(ImageSource.gallery, 'front'),
                    height: screenHeight * 0.15,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: _UploadCard(
                    title: "Back Side",
                    image: _backImage,
                    onTap: () => _pickImage(ImageSource.gallery, 'back'),
                    height: screenHeight * 0.15,
                    screenWidth: screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              "Upload Selfie",
              style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
            _UploadCard(
              title: "Selfie Holding ID",
              image: _selfieImage,
              onTap: () => _pickImage(ImageSource.camera, 'selfie'),
              height: screenHeight * 0.25,
              width: double.infinity,
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenHeight * 0.05),
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.07,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? SizedBox(width: screenWidth * 0.06, height: screenWidth * 0.06, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Submit Documents", style: TextStyle(fontSize: screenWidth * 0.04)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final File? image;
  final VoidCallback onTap;
  final double height;
  final double? width;
  final double screenWidth;

  const _UploadCard({
    required this.title,
    required this.image,
    required this.onTap,
    required this.height,
    this.width,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.grey.shade400),
          image: image != null
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey, size: screenWidth * 0.08),
                  SizedBox(height: screenWidth * 0.02),
                  Text(title, style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.03)),
                ],
              )
            : Container(
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: screenWidth * 0.03,
                  child: Icon(Icons.edit, size: screenWidth * 0.035, color: Colors.blue),
                ),
              ),
      ),
    );
  }
}
