import 'package:flutter/services.dart';

/// 통화 형식으로 포맷 (억/만/원)
String formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  if (absolute >= 100000000) {
    final eok = absolute / 100000000;
    return '$sign₩${formatNumber(eok)}억';
  }
  if (absolute >= 10000) {
    final man = absolute / 10000;
    return '$sign₩${formatNumber(man)}만';
  }
  return '$sign₩${formatNumber(absolute)}';
}

/// 1원 단위까지 표시하는 원화 포맷
String formatCurrencyFull(double value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  return '$sign₩${formatNumber(absolute.roundToDouble())}';
}

/// 날짜 시간 포맷
String formatTime(DateTime time) {
  final hour = time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final ampm = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:$minute $ampm';
}

/// 숫자에 콤마 추가
String formatNumber(double value) {
  final rounded =
      value.abs() >= 100 ? value.round().toString() : value.toStringAsFixed(1);
  final parts = rounded.split('.');
  final chars = parts.first.split('').reversed.toList();
  final buffer = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) buffer.write(',');
    buffer.write(chars[i]);
  }
  final whole = buffer.toString().split('').reversed.join();
  if (parts.length == 1 || parts.last == '0') return whole;
  return '$whole.${parts.last}';
}

/// 텍스트 필드용 숫자 콤마 포매터
class NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 숫자와 소수점만 허용
    final numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numericOnly.isEmpty) return newValue.copyWith(text: '');

    // 소수점이 여러개면 마지막 것만 유지 등 복잡하므로 간단히 처리
    final parts = numericOnly.split('.');
    String wholeNumber = parts.first;
    String decimalPart = parts.length > 1 ? '.${parts.skip(1).join('')}' : '';

    final chars = wholeNumber.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    
    final formatted = buffer.toString().split('').reversed.join() + decimalPart;

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
