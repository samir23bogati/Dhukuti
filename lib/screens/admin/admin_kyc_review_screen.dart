import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminKYCReviewScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminKYCReviewScreen({
    super.key,
    required this.uid,
    required this.userData,
  });

  @override
  State<AdminKYCReviewScreen> createState() => _AdminKYCReviewScreenState();
}

class _AdminKYCReviewScreenState extends State<AdminKYCReviewScreen> {
  bool _isProcessing = false;
  final _reasonController = TextEditingController();

  Future<void> _updateStatus(String status) async {
    if (status == 'rejected' && _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a rejection reason")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await context.read<UserProvider>().updateKYCStatus(
        uid: widget.uid,
        status: status,
        rejectionReason: status == 'rejected' ? _reasonController.text : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User KYC $status successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject KYC"),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: "Reason for rejection",
            hintText: "e.g., ID image not clear",
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('rejected');
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      appBar: AppBar(title: const Text("KYC Review")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "User: ${widget.userData['name'] ?? 'N/A'}",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Phone: ${widget.userData['phone']}"),
            Divider(height: screenHeight * 0.04),

            Text(
              "Citizenship Front",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _KycImage(
              uid: widget.uid,
              imageType: 'front',
              height: screenHeight * 0.22,
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.03),
            Text(
              "Citizenship Back",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _KycImage(
              uid: widget.uid,
              imageType: 'back',
              height: screenHeight * 0.22,
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.03),
            Text(
              "Selfie",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _KycImage(
              uid: widget.uid,
              imageType: 'selfie',
              height: screenHeight * 0.28,
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.04),
            if (_isProcessing)
              Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      onPressed: _showRejectDialog,
                      child: Text(
                        "REJECT",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      onPressed: () => _updateStatus('verified'),
                      child: Text(
                        "APPROVE",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }
}

class _KycImage extends StatelessWidget {
  final String uid;
  final String imageType;
  final double height;
  final double screenWidth;

  const _KycImage({
    required this.uid,
    required this.imageType,
    required this.height,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = screenWidth * 0.03;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('kyc')
          .doc(imageType)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: Text(
                "Image not available",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final base64String = data['data'] as String? ?? '';
        final imageBytes = base64Decode(base64String);

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: InteractiveViewer(child: Image.memory(imageBytes)),
              ),
            );
          },
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.broken_image, size: screenWidth * 0.1),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
