import 'package:equatable/equatable.dart';

class TreeOrderModel extends Equatable {
  final String id;
  final String userId;
  final int treeCount;
  final double amount;
  final double finalAmount;
  final double discountPercentage;
  final String status;
  final bool isGift;
  final String? recipientName;
  final String? recipientEmail;
  final String? message;
  final String? occasion;
  final String? plantingLocation;
  final String? certificateUrl;
  final DateTime createdAt;
  // Optional joined fields (filled when the query joins users / payments)
  final String? userName;
  final String? userEmail;
  final TreePaymentSummary? payment;

  const TreeOrderModel({
    required this.id,
    required this.userId,
    required this.treeCount,
    required this.amount,
    required this.finalAmount,
    required this.discountPercentage,
    required this.status,
    required this.isGift,
    this.recipientName,
    this.recipientEmail,
    this.message,
    this.occasion,
    this.plantingLocation,
    this.certificateUrl,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.payment,
  });

  factory TreeOrderModel.fromSupabase(Map<String, dynamic> data) {
    final user = data['users'] is Map ? data['users'] as Map : null;
    final paymentsRaw = data['tree_payments'];
    TreePaymentSummary? paymentSummary;
    if (paymentsRaw is List && paymentsRaw.isNotEmpty) {
      paymentSummary =
          TreePaymentSummary.fromSupabase(paymentsRaw.first as Map<String, dynamic>);
    } else if (paymentsRaw is Map) {
      paymentSummary =
          TreePaymentSummary.fromSupabase(paymentsRaw as Map<String, dynamic>);
    }

    return TreeOrderModel(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      treeCount: (data['tree_count'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (data['final_amount'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (data['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Pending',
      isGift: data['is_gift'] ?? false,
      recipientName: data['recipient_name'],
      recipientEmail: data['recipient_email'],
      message: data['message'],
      occasion: data['occasion'],
      plantingLocation: data['planting_location'],
      certificateUrl: data['certificate_url'],
      createdAt: DateTime.parse(data['created_at'].toString()),
      userName: user?['name']?.toString(),
      userEmail: user?['email']?.toString(),
      payment: paymentSummary,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        treeCount,
        amount,
        finalAmount,
        discountPercentage,
        status,
        isGift,
        recipientName,
        recipientEmail,
        message,
        occasion,
        plantingLocation,
        certificateUrl,
        createdAt,
        userName,
        userEmail,
        payment,
      ];
}

class TreePaymentSummary extends Equatable {
  final String id;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final double amount;
  final String status;
  final DateTime? verifiedAt;

  const TreePaymentSummary({
    required this.id,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    required this.amount,
    required this.status,
    this.verifiedAt,
  });

  factory TreePaymentSummary.fromSupabase(Map<String, dynamic> data) {
    return TreePaymentSummary(
      id: data['id'] ?? '',
      razorpayPaymentId: data['razorpay_payment_id'],
      razorpayOrderId: data['razorpay_order_id'],
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      verifiedAt: data['verified_at'] != null
          ? DateTime.parse(data['verified_at'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, razorpayPaymentId, razorpayOrderId, amount, status, verifiedAt];
}
