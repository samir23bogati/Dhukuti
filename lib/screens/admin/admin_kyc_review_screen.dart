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
    
    return Scaffold(
      appBar: AppBar(title: const Text("KYC Review")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "User: ${widget.userData['name'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Phone: ${widget.userData['phone']}"),
            const Divider(height: 40),
            
            const Text("Citizenship Front", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildImage(widget.userData['citizenshipFrontUrl'], size.height * 0.25),
            
            const SizedBox(height: 30),
            const Text("Citizenship Back", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildImage(widget.userData['citizenshipBackUrl'], size.height * 0.25),
            
            const SizedBox(height: 30),
            const Text("Selfie", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildImage(widget.userData['selfieUrl'], size.height * 0.3),
            
            const SizedBox(height: 40),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _showRejectDialog,
                      child: const Text("REJECT"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => _updateStatus('verified'),
                      child: const Text("APPROVE"),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url, double height) {
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("Image not available")),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}
