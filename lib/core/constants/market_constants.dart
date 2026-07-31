import 'package:decimal/decimal.dart';

/// Starting prices for each stock symbol.
final Map<String, Decimal> kStartingPrices = {
  'RELIANCE': Decimal.parse('1400'),
  'TCS': Decimal.parse('3200'),
  'INFY': Decimal.parse('1500'),
  'HDFCBANK': Decimal.parse('1650'),
  'ICICIBANK': Decimal.parse('1100'),
  'SBIN': Decimal.parse('780'),
  'ITC': Decimal.parse('420'),
  'LT': Decimal.parse('3500'),
  'BHARTIARTL': Decimal.parse('1300'),
  'AXISBANK': Decimal.parse('1050'),
};

/// Initial wallet balance (₹) as a string to be parsed into Decimal at runtime.
const String kInitialWalletBalance = '100000'; // ₹1,00,000

const Map<String, String> kStockCompanyNames = {
  'RELIANCE':    'Reliance Industries Ltd.',
  'TCS':         'Tata Consultancy Services',
  'INFY':        'Infosys Ltd.',
  'HDFCBANK':    'HDFC Bank Ltd.',
  'ICICIBANK':   'ICICI Bank Ltd.',
  'SBIN':        'State Bank of India',
  'ITC':         'ITC Limited',
  'LT':          'Larsen & Toubro Ltd.',
  'BHARTIARTL':  'Bharti Airtel Ltd.',
  'AXISBANK':    'Axis Bank Ltd.',
};
