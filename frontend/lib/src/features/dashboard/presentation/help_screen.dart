import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("How can we help you?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildHelpItem(Icons.chat_bubble_outline, "Chat with us", "Get instant support from our team"),
          _buildHelpItem(Icons.email_outlined, "Email us", "support@foodapp.com"),
          _buildHelpItem(Icons.phone_outlined, "Call us", "+91 1234567890"),
          const Divider(height: 48),
          const Text("FAQs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqItem("How to cancel an order?", "You can cancel your order within 5 minutes of placing it."),
          _buildFaqItem("Refund policy", "Refunds are processed within 3-5 business days."),
          _buildFaqItem("Payment issues", "We accept all major credit cards and UPI."),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(answer, style: TextStyle(color: Colors.grey[600])),
        )
      ],
    );
  }
}
