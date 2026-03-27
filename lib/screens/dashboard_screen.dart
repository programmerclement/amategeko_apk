import 'package:flutter/material.dart';
import '../services/exam_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> examHistory = [];
  List<dynamic> paymentHistory = [];
  int totalExams = 0;
  int passedExams = 0;
  int failedExams = 0;
  double successRate = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'No authentication token found';
          isLoading = false;
        });
        return;
      }

      // Fetch exam history
      final examResponse = await ExamService.fetchExamHistory(token);
      if (examResponse['success']) {
        examHistory = examResponse['data'] ?? [];
        calculateStatistics();
      } else {
        errorMessage = examResponse['message'] ?? 'Failed to fetch exam history';
      }

      // Fetch payment history
      final paymentResponse = await PaymentService.fetchPaymentHistory(token);
      if (paymentResponse['success']) {
        paymentHistory = paymentResponse['data'] ?? [];
      } else {
        if (errorMessage.isEmpty) {
          errorMessage = paymentResponse['message'] ?? 'Failed to fetch payment history';
        }
      }
    } catch (e) {
      errorMessage = 'Network error occurred';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void calculateStatistics() {
    totalExams = examHistory.length;
    passedExams = examHistory.where((exam) => exam['status'] == 'passed').length;
    failedExams = totalExams - passedExams;
    successRate = totalExams > 0 ? (passedExams / totalExams) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage, style: TextStyle(color: Colors.red)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchData,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Section
                        Text(
                          'Statistics',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Total Exams', totalExams.toString(), Colors.blue),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard('Passed', passedExams.toString(), Colors.green),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Failed', failedExams.toString(), Colors.red),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard('Success Rate', '${successRate.toStringAsFixed(1)}%', Colors.orange),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // Exam History Section
                      Text(
                        'Exam History',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      examHistory.isEmpty
                          ? Text('No exam history available')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: examHistory.length,
                              itemBuilder: (context, index) {
                                final exam = examHistory[index];
                                return Card(
                                  child: ListTile(
                                    title: Text('Exam ${index + 1}'),
                                    subtitle: Text('Status: ${exam['status'] ?? 'Unknown'}'),
                                    trailing: Text(exam['date'] ?? ''),
                                  ),
                                );
                              },
                            ),
                      SizedBox(height: 32),

                      // Payment History Section
                      Text(
                        'Payment History',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      paymentHistory.isEmpty
                          ? Text('No payment history available')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: paymentHistory.length,
                              itemBuilder: (context, index) {
                                final payment = paymentHistory[index];
                                return Card(
                                  child: ListTile(
                                    title: Text('Payment ${index + 1}'),
                                    subtitle: Text('Amount: ${payment['amount'] ?? 'N/A'}'),
                                    trailing: Text(payment['date'] ?? ''),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}