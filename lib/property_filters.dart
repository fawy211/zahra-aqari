enum TransactionType { all, rent, sale }

enum PropertyCategory { all, residential, commercial }

class FilterState {
  final TransactionType transactionType;
  final PropertyCategory propertyCategory;

  FilterState({
    required this.transactionType,
    required this.propertyCategory,
  });
}
