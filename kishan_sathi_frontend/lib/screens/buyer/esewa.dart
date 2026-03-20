import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:esewa_flutter_sdk/payment_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'esewa_key.dart';


class Esewa {
  final BuildContext context;
  final String productId;
  final String productName;
  final String totalAmount;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  Esewa({
    required this.context,
    required this.productId,
    required this.productName,
    required this.totalAmount,
    this.onSuccess,
    this.onFailure,
  });

  void pay() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          clientId: KEsewaClientId,
          secretId: KEsewaSecretKey,
          environment: Environment.test,
        ),
        esewaPayment: EsewaPayment(
          productId: productId,
          productName: productName,
          productPrice: totalAmount,
          callbackUrl: "",
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) {
          debugPrint(":::eSewa SUCCESS::: => $result");
          debugPrint("Product ID: ${result.productId}");
          debugPrint("Product Name: ${result.productName}");
          debugPrint("Total Amount: ${result.totalAmount}");
          debugPrint("Reference ID: ${result.refId}");
          debugPrint("Status: ${result.status}");
          
          // Clear cart first
          if (onSuccess != null) onSuccess!();
          
          // Then show success dialog
          _showSuccessDialog(result);
        },
        onPaymentFailure: (EsewaPaymentFailure result) {
          debugPrint(":::eSewa FAILURE::: => $result");
          _showFailureDialog("Payment failed. Please try again.");
          if (onFailure != null) onFailure!();
        },
        onPaymentCancellation: () {
          debugPrint(':::eSewa CANCELLATION:::');
          _showFailureDialog("Payment was cancelled.");
          if (onFailure != null) onFailure!();
        },
      );
    } catch (e) {
      debugPrint("eSewa EXCEPTION: ${e.toString()}");
      _showFailureDialog("Error: ${e.toString()}");
      if (onFailure != null) onFailure!();
    }
  }

  void _showSuccessDialog(EsewaPaymentSuccessResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title:const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your payment has been completed successfully!'),
              SizedBox(height: 12),
              Text('Reference ID: ${result.refId ?? "N/A"}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Amount: Rs. ${result.totalAmount}'),
              Text('Status: ${result.status ?? "COMPLETE"}'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your cart has been cleared.',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Payment Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}



