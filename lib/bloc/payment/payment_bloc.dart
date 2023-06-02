import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<PaymentStart>(_onPaymentStart);
    on<PaymentCreateIntent>(_onPaymentCreateIntent);
    on<PaymentConfirmIntent>(_onPaymentConfirmIntent);
  }

  // Your event handlers would look something like this:
  void _onPaymentStart(PaymentStart event, Emitter<PaymentState> emit) {
    emit(state.copyWith(status: PaymentStatus.initial));
  }

  void _onPaymentCreateIntent(PaymentCreateIntent event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(status: PaymentStatus.loading));

    final paymentMethod = await Stripe.instance.createPaymentMethod(params:
    PaymentMethodParams.card(paymentMethodData: PaymentMethodData(billingDetails: event.billingDetails)));

    final paymentIntentResults = await _callPayEndPointMethodId(
      useStripeSdk: true,
      paymentMethodId: paymentMethod.id,
      currency: 'usd',
      amount: event.amount,
    );

    if (paymentIntentResults['error'] != null) {
      emit(state.copyWith(status: PaymentStatus.failure));
    }

    if (paymentIntentResults['clientSecret'] != null
        && paymentIntentResults['requiresAction'] == null) {
      emit(state.copyWith(status: PaymentStatus.success));
    }

    if (paymentIntentResults['clientSecret'] != null
        && paymentIntentResults['requiresAction'] == true) {
      final String clientSecret = paymentIntentResults['clientSecret'];
      add(PaymentConfirmIntent(clientSecret: clientSecret));
    }
  }

  void _onPaymentConfirmIntent(PaymentConfirmIntent event, Emitter<PaymentState> emit) async {
    try {
      final paymentIntent =
      await Stripe.instance.handleNextAction(event.clientSecret);

      if(paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation){
        Map<String, dynamic> results = await _callPayEndpointIntent(
          paymentIntentId: paymentIntent.id,
        );
        if(results['error'] != null){
          emit(state.copyWith(status: PaymentStatus.failure));
        } else {
          emit(state.copyWith(status: PaymentStatus.success));
        }
      }

    } catch (e) {
      print(e);
      emit(state.copyWith(status: PaymentStatus.failure));
    }
  }
  Future <Map<String,dynamic>> _callPayEndpointIntent({
    required String paymentIntentId,
  }) async {
    final url = Uri.parse("https://us-central1-restaurantapp-2a43d.cloudfunctions.net/StripePayEndpointIntentId");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'paymentIntentId': paymentIntentId,
      }),
    );
    return json.decode(response.body);
  }

  Future <Map<String,dynamic>> _callPayEndPointMethodId({
    required bool useStripeSdk,
    required String paymentMethodId,
    required String currency,
    required double amount,
  }) async {
    final url = Uri.parse("https://us-central1-restaurantapp-2a43d.cloudfunctions.net/StripePayEndpointMethodId");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'useStripeSdk': useStripeSdk,
        'paymentMethodId': paymentMethodId,
        'currency': currency,
        'amount': amount,
      },),
    );
    return json.decode(response.body);
  }
}
