import 'package:flutter/material.dart';

/// Utility class for formatting currency values consistently across the app
class CurrencyFormatter {
  // Currency symbols mapping
  static const Map<String, String> currencySymbols = {
    'AED': 'د.إ', // UAE Dirham Arabic symbol
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  // Default currency (can be changed based on user settings)
  static String defaultCurrency = 'AED';

  /// Formats a currency value with the symbol before the amount
  /// Example: formatCurrency(15.00) returns "د.إ 15.00"
  static String formatCurrency(
    double? value, {
    String? currency,
    int decimalDigits = 2,
    bool showSymbol = true,
  }) {
    if (value == null) return formatCurrency(0.0, currency: currency, decimalDigits: decimalDigits, showSymbol: showSymbol);
    
    final currencyCode = currency ?? defaultCurrency;
    final symbol = showSymbol ? (currencySymbols[currencyCode] ?? currencyCode) : '';
    final formattedValue = value.toStringAsFixed(decimalDigits);
    
    // For Arabic RTL currencies, symbol comes after, but we'll keep it before for consistency
    return symbol.isNotEmpty ? '$symbol $formattedValue' : formattedValue;
  }

  /// Formats a currency value without decimal places (for whole numbers)
  /// Example: formatCurrencyWhole(15) returns "د.إ 15"
  static String formatCurrencyWhole(
    double? value, {
    String? currency,
    bool showSymbol = true,
  }) {
    return formatCurrency(value, currency: currency, decimalDigits: 0, showSymbol: showSymbol);
  }

  /// Formats a currency value with custom decimal places
  /// Example: formatCurrencyWithDecimals(15.5, decimals: 1) returns "د.إ 15.5"
  static String formatCurrencyWithDecimals(
    double? value, {
    String? currency,
    int decimals = 2,
    bool showSymbol = true,
  }) {
    return formatCurrency(value, currency: currency, decimalDigits: decimals, showSymbol: showSymbol);
  }

  /// Widget that displays currency with proper styling
  /// The symbol appears before the amount with appropriate spacing
  static Widget formatCurrencyWidget(
    double? value, {
    String? currency,
    int decimalDigits = 2,
    bool showSymbol = true,
    TextStyle? style,
    BuildContext? context,
  }) {
    final currencyCode = currency ?? defaultCurrency;
    final symbol = showSymbol ? (currencySymbols[currencyCode] ?? currencyCode) : '';
    final formattedValue = value?.toStringAsFixed(decimalDigits) ?? '0.00';
    
    if (symbol.isEmpty) {
      return Text(
        formattedValue,
        style: style,
      );
    }

    return RichText(
      text: TextSpan(
        style: style ?? (context != null ? Theme.of(context).textTheme.bodyLarge : null),
        children: [
          TextSpan(
            text: '$symbol ',
            style: (style ?? (context != null ? Theme.of(context).textTheme.bodyLarge : null))?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: formattedValue,
          ),
        ],
      ),
    );
  }
}



