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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
            ),
            Text("Phone: ${widget.userData['phone']}"),
            Divider(height: screenHeight * 0.04),
            
            Text("Citizenship Front", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
            SizedBox(height: screenHeight * 0.01),
            _buildImage(widget.userData['citizenshipFrontUrl'], screenHeight * 0.22, screenWidth),
            
            SizedBox(height: screenHeight * 0.03),
            Text("Citizenship Back", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
            SizedBox(height: screenHeight * 0.01),
            _buildImage(widget.userData['citizenshipBackUrl'], screenHeight * 0.22, screenWidth),
            
            SizedBox(height: screenHeight * 0.03),
            Text("Selfie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
            SizedBox(height: screenHeight * 0.01),
            _buildImage(widget.userData['selfieUrl'], screenHeight * 0.28, screenWidth),
            
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
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      ),
                      onPressed: _showRejectDialog,
                      child: Text("REJECT", style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      ),
                      onPressed: () => _updateStatus('verified'),
                      child: Text("APPROVE", style: TextStyle(fontSize: screenWidth * 0.04)),
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

  Widget _buildImage(String? url, double height, double screenWidth) {
    final borderRadius = screenWidth * 0.03;
    
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(child: Text("Image not available", style: TextStyle(fontSize: screenWidth * 0.04))),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
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
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null));
            },
            errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: screenWidth * 0.1)),
          ),
        ),
      ),
    );
  }
}
