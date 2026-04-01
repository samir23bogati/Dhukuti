import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am the Dhukuti Assistant. How can I help you with your gold and silver investments today?'
    },
  ];

  final String _knowledgeBase = """
Dhukuti AI Assistant Knowledge Base:
- Identity: You are the Dhukuti Assistant. You help users navigate gold/silver investments in Nepal.
- Products: 
  * 24K Gold: 99.9% pure physical gold.
  * .999 Fine Silver: High-purity investment-grade silver.
- Trading Rules: 
  * Hours: 11:00 AM to 5:00 PM Nepal time.
  * Days: Sunday to Friday (Closed on Saturdays).
- Fee Disclosure: 
  * Every transaction (both Buy and Sell) includes a 1% service charge. 
  * This fee is used for vaulting, insurance, and platform maintenance.
- Safety & Storage: 
  * 1:1 Backed: Every gram of metal you own is physically stored in our secure vault.
  * Physical Delivery: You can request home delivery or pickup of your physical gold/silver once your holdings reach standard weights.
- Verification (KYC): 
  * Required: You must be verified to start trading.
  * Process: Go to the 'Profile' tab, upload your Citizenship (Front & Back) and a Selfie holding your ID.
  * Approval: Admin usually reviews and approves KYC within 24-48 business hours.
- Contact: Support is available via WhatsApp for payment inquiries or technical help.
""";

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
    });

    // Detailed AI Response logic based on expanded knowledge
    String response = "I'm sorry, I don't have information on that topic. I can help with trading hours, products (Gold/Silver), fees, or the KYC verification process. What would you like to know?";
    
    final lowerText = text.toLowerCase();

    if (lowerText.contains('hour') || lowerText.contains('time') || lowerText.contains('when') || lowerText.contains('open') || lowerText.contains('close')) {
      response = "Our trading hours are 11:00 AM to 5:00 PM Nepal Time, Sunday through Friday. We are closed on Saturdays and some public holidays.";
    } 
    else if (lowerText.contains('gold') || lowerText.contains('silver') || lowerText.contains('product') || lowerText.contains('24k') || lowerText.contains('metal')) {
      response = "We offer 24K (99.9%) pure physical Gold and .999 Fine Silver. You can buy and sell these metals digitally, and they are backed 1:1 by physical reserves in our vault.";
    } 
    else if (lowerText.contains('fee') || lowerText.contains('charge') || lowerText.contains('cost') || lowerText.contains('tax') || lowerText.contains('commission')) {
      response = "Dhukuti charges a 1% service fee on every buy and sell transaction. This covers the cost of secure vaulting, insurance, and platform operations.";
    } 
    else if (lowerText.contains('verify') || lowerText.contains('kyc') || lowerText.contains('approve') || lowerText.contains('document') || lowerText.contains('citizenship') || lowerText.contains('selfie')) {
      response = "To start trading, you must complete KYC verification in the 'Profile' tab. You'll need to upload the front and back of your Citizenship ID and a selfie holding your ID. Our team usually approves it within 24-48 hours.";
    } 
    else if (lowerText.contains('safety') || lowerText.contains('vault') || lowerText.contains('physical') || lowerText.contains('secure') || lowerText.contains('delivery')) {
      response = "Safety is our priority. Your assets are stored in a high-security vault and are fully insured. Once your holdings reach a standard weight, you can even request physical delivery to your doorstep!";
    } 
    else if (lowerText.contains('price') || lowerText.contains('rate') || lowerText.contains('how much')) {
      response = "You can see the current live rates for Gold and Silver directly on the 'Trade' tab. These rates are updated frequently based on market prices.";
    }
    else if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('hey') || lowerText.contains('help')) {
      response = "Hello! I can help you with questions about trading hours, our gold and silver products, transaction fees, and the verification process. Ask away!";
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dhukuti Assistant"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your question...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
