import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

class ExamHistoryScreen extends StatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen> {
  List<dynamic> exams = [];
  Map<String, dynamic>? selectedExamDetails;
  bool isLoading = true;
  bool isLoadingDetails = false;
  String errorMessage = '';
  String filterStatus = 'all'; // 'all' | 'passed' | 'failed'
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadExamHistory();
  }

  Future<void> _loadExamHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('📚 [ExamHistory] Loading exam history - page: $currentPage');
      final response = await ApiService.fetchExamHistory();

      if (!mounted) return;

      List<dynamic> filteredExams = response['exams'] ?? [];

      // Sort by date (newest first)
      filteredExams.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      // Apply filter
      if (filterStatus == 'passed') {
        filteredExams = filteredExams
            .where((exam) => exam['passed'] == true)
            .toList();
      } else if (filterStatus == 'failed') {
        filteredExams = filteredExams
            .where((exam) => exam['passed'] == false)
            .toList();
      }

      setState(() {
        exams = filteredExams;
        totalPages = response['pagination']?['totalPages'] ?? 1;
        isLoading = false;
      });

      print('✅ [ExamHistory] Loaded ${exams.length} exams');
    } catch (e) {
      print('❌ [ExamHistory] Error loading: $e');
      setState(() {
        errorMessage = 'Failed to load exam history';
        isLoading = false;
      });
    }
  }

  Future<void> _loadExamDetails(String examId) async {
    setState(() {
      isLoadingDetails = true;
    });

    try {
      print('📖 [ExamHistory] Loading exam details for: $examId');
      final response = await ApiService.getExamResult(examId);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          selectedExamDetails = response['examResult'];
          isLoadingDetails = false;
        });
        print('✅ [ExamHistory] Exam details loaded successfully');
      } else {
        throw Exception(response['message'] ?? 'Failed to load exam details');
      }
    } catch (e) {
      print('❌ [ExamHistory] Error loading details: $e');
      AppSnackbar.error(context, 'Failed to load exam details');
      setState(() {
        isLoadingDetails = false;
      });
    }
  }

  void _backToList() {
    setState(() {
      selectedExamDetails = null;
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      final timeStr =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      if (difference.inDays == 0) {
        return 'Today at $timeStr';
      } else if (difference.inDays == 1) {
        return 'Yesterday at $timeStr';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago at $timeStr';
      } else {
        return '${date.day}/${date.month}/${date.year} at $timeStr';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  // Exam Details View
  Widget _buildExamDetailsView() {
    final exam = selectedExamDetails;
    if (exam == null) {
      return SizedBox.expand(
        child: Center(
          child: CircularProgressIndicator(color: Colors.green.shade600),
        ),
      );
    }

    final passed = exam['passed'] == true;
    final results = exam['results'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToList,
        ),
      ),
      body: isLoadingDetails
          ? Center(
              child: CircularProgressIndicator(color: Colors.green.shade600),
            )
          : RefreshIndicator(
              onRefresh: () => _loadExamDetails(exam['_id']),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score Overview Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: passed
                              ? [Colors.green.shade600, Colors.green.shade700]
                              : [Colors.red.shade600, Colors.red.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (passed ? Colors.green : Colors.red)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exam Result',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${exam['score'] ?? 0}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  passed ? '✓ Passed' : '✗ Failed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.8,
                            children: [
                              _buildStatItem(
                                '${exam['correctAnswers'] ?? 0}/${exam['totalQuestions'] ?? 0}',
                                'Correct',
                              ),
                              _buildStatItem(
                                _formatTime(exam['timeSpent'] ?? 0),
                                'Time Spent',
                              ),
                              _buildStatItem(
                                '${((exam['correctAnswers'] ?? 0) / (exam['totalQuestions'] ?? 1) * 5).toStringAsFixed(1)}/20',
                                'Mark',
                              ),
                              _buildStatItem(
                                '${exam['totalQuestions'] ?? 0}',
                                'Questions',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Exam Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Date',
                            _formatDate(exam['createdAt'] ?? ''),
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Category',
                            (exam['category'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Difficulty',
                            (exam['difficulty'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question Review Section
                    Text(
                      'Question Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (results.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Text(
                            'No question details available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ...results.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value as Map<String, dynamic>;
                        final isCorrect = result['isCorrect'] == true;
                        final userAnswer = result['userAnswer'] ?? '';
                        final correctAnswer = result['correctAnswer'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(
                                color: isCorrect ? Colors.green : Colors.red,
                                width: 4,
                              ),
                            ),
                            color: isCorrect
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Question ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCorrect ? '✓ Correct' : '✗ Wrong',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isCorrect
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Question Text
                                Text(
                                  result['questionText'] ??
                                      'Question not available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Question Image
                                if (result['image'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        result['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                height: 150,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),

                                // Options
                                Text(
                                  'Options:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...((result['options'] ?? []) as List)
                                    .asMap()
                                    .entries
                                    .map((optEntry) {
                                      final optIndex = optEntry.key;
                                      final option = optEntry.value;
                                      final optLabel = String.fromCharCode(
                                        97 + optIndex,
                                      );
                                      final isUserAnswer = option == userAnswer;
                                      final isCorrectOpt =
                                          option == correctAnswer;

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isCorrectOpt
                                                ? Colors.green
                                                : isUserAnswer
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                            width: isCorrectOpt || isUserAnswer
                                                ? 2
                                                : 1,
                                          ),
                                          color: isCorrectOpt
                                              ? Colors.green.shade100
                                              : isUserAnswer
                                              ? Colors.red.shade100
                                              : Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$optLabel)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                            ),
                                            if (isCorrectOpt)
                                              Text(
                                                '✓',
                                                style: TextStyle(
                                                  color: Colors.green.shade600,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            else if (isUserAnswer)
                                              Text(
                                                '✗',
                                                style: TextStyle(
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    })
                                    ,

                                // Explanation
                                if (result['explanation'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Explanation',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            result['explanation'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  // Main Exam List View
  Widget _buildExamListView() {
    // Calculate stats from all exams (before filtering)
    int totalExams = exams.length;
    int passedExams = exams.where((exam) => exam['passed'] == true).length;
    int failedExams = exams.where((exam) => exam['passed'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam History'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green.shade600),
            )
          : Column(
              children: [
                // Stats Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          icon: Icons.assignment,
                          label: 'Total Exams',
                          value: '$totalExams',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          icon: Icons.check_circle,
                          label: 'Passed',
                          value: '$passedExams',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          icon: Icons.cancel,
                          label: 'Failed',
                          value: '$failedExams',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _buildFilterButton('All', 'all')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFilterButton('✓ Passed', 'passed')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFilterButton('✗ Failed', 'failed')),
                    ],
                  ),
                ),
                // Exam List
                Expanded(
                  child: exams.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No exams found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                filterStatus == 'all'
                                    ? 'Start your first exam!'
                                    : 'No $filterStatus exams yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadExamHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: exams.length,
                            itemBuilder: (context, index) {
                              final exam = exams[index];
                              final passed = exam['passed'] == true;

                              return GestureDetector(
                                onTap: () => _loadExamDetails(exam['_id']),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: passed
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Exam',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                passed
                                                    ? '✓ Passed'
                                                    : '✗ Failed',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: passed
                                                      ? Colors.green.shade600
                                                      : Colors.red.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${exam['score'] ?? 0}%',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: passed
                                                  ? Colors.green.shade600
                                                  : Colors.red.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Stats Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildExamStat(
                                              Icons.check_circle_outline,
                                              '${exam['correctAnswers'] ?? 0}/${exam['totalQuestions'] ?? 0}',
                                              'Correct',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildExamStat(
                                              Icons.access_time,
                                              _formatTime(
                                                exam['timeSpent'] ?? 0,
                                              ),
                                              'Time',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(
                                              exam['createdAt'] ?? '',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String status) {
    final isActive = filterStatus == status;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          filterStatus = status;
          currentPage = 1;
        });
        _loadExamHistory();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Colors.green.shade600
            : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 40),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildExamStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return selectedExamDetails != null
        ? _buildExamDetailsView()
        : _buildExamListView();
  }
}
