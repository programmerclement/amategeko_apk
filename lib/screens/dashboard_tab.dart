import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;
  String errorMessage = '';

  // User data
  String userId = '';
  String username = 'User';
  String firstName = '';
  String lastName = '';

  // Statistics from profile
  int totalExamsTaken = 0;
  double averageScore = 0.0;
  double bestScore = 0.0;
  bool isPremium = false;
  String planName = 'Free';

  // Statistics from exam history
  int passedExams = 0;
  int failedExams = 0;
  double passRate = 0.0;

  List<dynamic> recentExams = [];
  List<dynamic> recentPayments = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Step 1: Fetch user profile
      final profileResponse = await ApiService.fetchUserProfile();

      // Check if response has error field or missing _id
      if (profileResponse.containsKey('message') && !profileResponse.containsKey('_id')) {
        if (mounted) {
          setState(() {
            errorMessage =
                profileResponse['message'] ?? 'Failed to load profile';
            isLoading = false;
          });
        }
        return;
      }

      // Parse user profile - backend returns data directly with _id
      userId = profileResponse['_id'] ?? '';
      username = profileResponse['username'] ?? 'User';
      isPremium = profileResponse['isPremium'] ?? false;
      planName = profileResponse['planName'] ?? 'Free';

      // Extract profile details
      final profile = profileResponse['profile'] ?? {};
      firstName = profile['firstName'] ?? '';
      lastName = profile['lastName'] ?? '';

      // Parse stats from profile
      final stats = profileResponse['stats'] ?? {};
      totalExamsTaken = stats['totalExamsTaken'] ?? 0;
      averageScore = (stats['averageScore'] ?? 0).toDouble();
      bestScore = (stats['bestScore'] ?? 0).toDouble();

      // Step 2: Fetch exam history
      final examResponse = await ApiService.fetchExamHistory();

      if (!mounted) return;

      // Step 3: Fetch payments
      final paymentResponse = userId.isNotEmpty
          ? await ApiService.fetchUserPayments(userId)
          : {'success': false};

      if (mounted) {
        setState(() {
          // Parse exam history
          if (examResponse['success'] == true) {
            recentExams = examResponse['exams'] ?? [];
            _calculateExamStats();
          }

          // Parse payment history
          if (paymentResponse['success'] == true) {
            recentPayments = paymentResponse['payments'] ?? [];
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  String _getDisplayName() {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return username;
    }
  }

  void _calculateExamStats() {
    passedExams = recentExams.where((e) => e['passed'] == true).length;
    failedExams = recentExams.length - passedExams;
    passRate = recentExams.isNotEmpty
        ? (passedExams / recentExams.length) * 100
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.green.shade600),
      );
    }

    if (errorMessage.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red.shade400),
                  SizedBox(height: 16),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Pull to refresh",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with premium badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back! 👋",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          _getDisplayName(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            planName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),

              // Stats Grid - Real Data from API
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: "Total Exams",
                    value: "$totalExamsTaken",
                    icon: Icons.assignment,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: "Passed",
                    value: "$passedExams",
                    icon: Icons.check_circle,
                    color: Colors.green,
                    subtitle: "${passRate.toStringAsFixed(1)}%",
                  ),
                  StatCard(
                    title: "Failed",
                    value: "$failedExams",
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                  StatCard(
                    title: "Best Score",
                    value: "${bestScore.toStringAsFixed(0)}%",
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Average Score Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Average Score",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        Icon(Icons.trending_up, color: Colors.white, size: 20),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "${averageScore.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Recent Exams Section
              Text(
                "Recent Exams",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 12),
              if (recentExams.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "No exams yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...recentExams.take(3).map((exam) => _ExamListItem(exam)),

              SizedBox(height: 24),

              // Recent Payments Section
              Text(
                "Recent Payments",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 12),
              if (recentPayments.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "No payments yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...recentPayments
                    .take(3)
                    .map((payment) => _PaymentListItem(payment)),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamListItem extends StatelessWidget {
  final dynamic exam;

  const _ExamListItem(this.exam);

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final passed = exam['passed'] ?? false;
    final statusColor = passed ? Colors.green : Colors.red;
    final score = exam['score'] ?? 0;
    final category = exam['category'] ?? 'General';
    final difficulty = exam['difficulty'] ?? 'N/A';
    final date = _formatDate(exam['createdAt']);

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  passed ? "PASSED" : "FAILED",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScoreBadge("Score", "$score%", Colors.blue),
              _ScoreBadge("Difficulty", difficulty, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentListItem extends StatelessWidget {
  final dynamic payment;

  const _PaymentListItem(this.payment);

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = payment['amount'] ?? 0;
    final status = payment['status'] ?? 'pending';
    final planName = payment['planName'] ?? payment['description'] ?? 'Plan';
    final date = _formatDate(payment['createdAt'] ?? payment['date']);

    final statusColor = status == 'completed' || status == 'success'
        ? Colors.green
        : status == 'failed'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payment, color: Colors.orange, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${(amount is int ? amount.toDouble() : amount).toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade600,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
