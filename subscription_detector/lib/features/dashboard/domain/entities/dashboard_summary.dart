class DashboardSummary {
  const DashboardSummary({
    required this.totalSubscriptions,
    required this.monthlySpend,
    required this.annualSpend,
    required this.forgottenSubscriptions,
    required this.potentialSavings,
  });

  final int totalSubscriptions;
  final double monthlySpend;
  final double annualSpend;
  final int forgottenSubscriptions;
  final double potentialSavings;

  static const empty = DashboardSummary(
    totalSubscriptions: 0,
    monthlySpend: 0,
    annualSpend: 0,
    forgottenSubscriptions: 0,
    potentialSavings: 0,
  );
}
