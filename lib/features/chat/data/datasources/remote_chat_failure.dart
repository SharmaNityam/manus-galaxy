import 'package:dio/dio.dart';
import '../../domain/entities/chat_service_failure.dart';

ChatServiceFailure describeRemoteFailure(
  DioException error,
) => ChatServiceFailure(switch (error.response?.statusCode) {
  401 =>
    'The API key was rejected. Check the account connection before retrying.',
  403 =>
    'The provider denied this request. Check account access or rephrase your message.',
  429 =>
    'The model is temporarily rate limited. Wait a moment, then tap Try again.',
  400 || 413 =>
    'The provider could not accept this message. Try a smaller attachment or a shorter prompt.',
  500 ||
  502 ||
  503 ||
  504 => 'The model service is unavailable. Please try again shortly.',
  _ =>
    error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout
        ? 'The connection was interrupted. Check your network, then try again.'
        : 'The request could not complete. Please try again.',
});
