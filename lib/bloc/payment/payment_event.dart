part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class PaymentStart extends PaymentEvent {}

class PaymentCreateIntent extends PaymentEvent {
  final BillingDetails billingDetails;
  final double amount;

  const PaymentCreateIntent({
  required this.billingDetails,
  required this.amount,
  });

  @override
  List<Object> get props => [billingDetails, amount];
  }

  class PaymentConfirmIntent extends PaymentEvent {
  final String clientSecret;

  const PaymentConfirmIntent({required this.clientSecret});

  @override
  List<Object> get props => [clientSecret];
  }

