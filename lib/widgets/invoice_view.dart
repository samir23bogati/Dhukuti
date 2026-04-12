import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/services/invoice_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceView extends StatefulWidget {
  final TransactionModel transaction;
  final String userName;
  final String userPhone;

  const InvoiceView({
    super.key,
    required this.transaction,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
  bool _isGeneratingPdf = false;

  Future<void> _downloadInvoice() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final invoiceService = InvoiceService();
      final file = await invoiceService.generateInvoice(
        transaction: widget.transaction,
        userName: widget.userName,
        userPhone: widget.userPhone,
      );
      await invoiceService.shareInvoice(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating invoice: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isBuy = widget.transaction.type == TransactionType.buy;
    final color = isBuy ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DHUKUTI",
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Official Invoice",
                    style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _isGeneratingPdf ? null : _downloadInvoice,
                    icon: _isGeneratingPdf
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    tooltip: "Download Invoice",
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.transaction.type.name.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 40),
          _buildRow("Customer", widget.userName, screenWidth),
          _buildRow("Phone", widget.userPhone, screenWidth),
          _buildRow("Date", DateFormat('MMM d, yyyy h:mm a').format(widget.transaction.timestamp), screenWidth),
          _buildRow("Transaction ID", "#${widget.transaction.id.toUpperCase().substring(0, 8)}", screenWidth),
          
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${widget.transaction.metalType.toUpperCase()} (${widget.transaction.quantityTola.toStringAsFixed(2)} Tola)",
                style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
              ),
              Text(
                "Rs. ${widget.transaction.ratePerTola.toStringAsFixed(2)} / Tola",
                style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (!isBuy) ...[
             _buildRow("Subtotal", "Rs. ${(widget.transaction.quantityTola * widget.transaction.ratePerTola).toStringAsFixed(2)}", screenWidth),
             _buildRow("Service Fee (1%)", "- Rs. ${(widget.transaction.quantityTola * widget.transaction.ratePerTola * 0.01).toStringAsFixed(2)}", screenWidth, valueColor: Colors.red),
             const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NET TOTAL",
                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
              ),
              Text(
                "Rs. ${widget.transaction.totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          Text(
            "Thank you for choosing Dhukuti!",
            style: TextStyle(fontSize: screenWidth * 0.03, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, double screenWidth, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }
}
