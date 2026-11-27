import 'package:flutter/material.dart';

/// Payment and featured-listing activation remain disabled until a verified
/// server-side payment flow is connected.
class PaymentScreen extends StatelessWidget {
  final String propertyId;

  const PaymentScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'تمييز الإعلان',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  size: 44,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'خدمة تمييز الإعلانات غير متاحة حالياً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF003366),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'سيتم إتاحة الباقات والأسعار بعد ربط وسيلة دفع آمنة والتحقق من الدفع على الخادم. لم يتم خصم أي مبلغ أو تغيير حالة إعلانك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة إلى الإعلان'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
