import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

class ExamsTab extends StatefulWidget {
  const ExamsTab({super.key});

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  bool isChecking = false;
  List<dynamic> availableExams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    // Dummy data for available exams
    setState(() {
      availableExams = [
        {
          'id': '1',
          'title': 'Road Signs & Markings',
          'description': 'Learn about traffic signs and road markings',
          'duration': '20 mins',
          'questions': '50',
          'difficulty': 'Beginner',
        },
        {
          'id': '2',
          'title': 'Traffic Rules',
          'description': 'Essential traffic rules and regulations',
          'duration': '25 mins',
          'questions': '50',
          'difficulty': 'Intermediate',
        },
        {
          'id': '3',
          'title': 'Safe Driving',
          'description': 'Safe driving techniques and best practices',
          'duration': '30 mins',
          'questions': '50',
          'difficulty': 'Intermediate',
        },
        {
          'id': '4',
          'title': 'Emergency Procedures',
          'description': 'Handling emergency situations on road',
          'duration': '20 mins',
          'questions': '50',
          'difficulty': 'Advanced',
        },
      ];
    });
  }

  Future<void> _startExam(String examId, String examTitle) async {
    setState(() => isChecking = true);

    try {
      // Check eligibility from real API
      final response = await ApiService.checkExamEligibility();

      if (!mounted) return;

      // Check if canTakeExam field exists (backend returns data directly)
      if (response['canTakeExam'] == true) {
        // User is eligible, start exam
        AppSnackbar.success(context, "You are eligible! Starting exam...");
        // TODO: Navigate to exam screen
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => ExamScreen(examId: examId, title: examTitle),
        // ));
      } else {
        // Not eligible
        final message = response['message'] ?? "You are not eligible for this exam";
        final remainingExams = response['remainingExams'] ?? 0;
        
        AppSnackbar.error(
          context,
          remainingExams > 0
              ? "$message (Remaining: $remainingExams)"
              : message,
        );
      }
    } catch (e) {
      AppSnackbar.error(context, "Error checking eligibility: $e");
    } finally {
      if (mounted) {
        setState(() => isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Available Exams 📝",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Practice and master driving skills",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            SizedBox(height: 22),

            // Exams List
            ...availableExams.map(
              (exam) => _ExamCard(
                exam: exam,
                onStart: () => _startExam(exam['id'], exam['title']),
                isLoading: isChecking,
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final dynamic exam;
  final VoidCallback onStart;
  final bool isLoading;

  const _ExamCard({
    required this.exam,
    required this.onStart,
    required this.isLoading,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Difficulty
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        exam['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      exam['difficulty'],
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exam['difficulty'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyColor(exam['difficulty']),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Stats
            Row(
              children: [
                _StatBadge(icon: Icons.timer, label: exam['duration']),
                SizedBox(width: 16),
                _StatBadge(
                  icon: Icons.quiz,
                  label: "${exam['questions']} Questions",
                ),
              ],
            ),
            SizedBox(height: 16),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Start Exam",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
