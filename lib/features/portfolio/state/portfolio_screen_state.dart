import 'package:flutter/foundation.dart';

@immutable
class PortfolioScreenState {
  final bool sellAllLoading;

  const PortfolioScreenState({
    this.sellAllLoading = false,
  });

  PortfolioScreenState copyWith({
    bool? sellAllLoading,
  }) {
    return PortfolioScreenState(
      sellAllLoading: sellAllLoading ?? this.sellAllLoading,
    );
  }
}
