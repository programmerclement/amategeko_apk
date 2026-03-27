import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/exam_service.dart';
import '../widgets/app_snackbar.dart';
import 'exam_screen.dart';

class ExamsTab extends StatefulWidget {
  const ExamsTab({super.key});

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  bool isLoading = false;
  bool isChecking = false;
  String? userId;

  // Eligibility data
  Map<String, dynamic>? eligibilityData;
  bool canTakeExam = false;
  String statusMessage = '';

  // Exam history
  List<dynamic> recentExams = [];
  bool isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    print('📝 [ExamsTab] Init state - loading user data');
    _loadUserData();
    // Don't call _loadExamHistory() here - it will be called after userId loads
  }

  @override
  void activate() {
    print('👋 [ExamsTab] Tab activated - reloading user data');
    super.activate();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔄 [ExamsTab] Loading user ID...');
      final loadedUserId = await AuthService.getUserId();
      final token = await AuthService.getToken();

      if (mounted) {
        setState(() {
          userId = loadedUserId;
        });
        // Load exam eligibility and history AFTER userId and token are set
        if (loadedUserId != null && loadedUserId.isNotEmpty && token != null) {
          print('✅ [ExamsTab] User ID loaded, checking eligibility and history');
          await _checkExamEligibility();
          await _loadExamHistory(token);
        }
      }
      return;
    } catch (e) {
      print('❌ [ExamsTab] Error loading user data: $e');
    }
  }

  Future<void> _checkExamEligibility() async {
    if (userId == null || userId!.isEmpty) {
      print('⚠️ [ExamsTab] No userId to check eligibility');
      return;
    }

    setState(() => isChecking = true);

    try {
      print('🔍 [ExamsTab] Checking exam eligibility...');
      final response = await ApiService.checkExamEligibility();

      print('📊 [ExamsTab] Eligibility response: $response');

      if (mounted) {
        setState(() {
          eligibilityData = response;
          canTakeExam = response['canTakeExam'] ?? false;
          statusMessage = response['message'] ?? 'Unable to check eligibility';
          isChecking = false;
        });
      }

      if (canTakeExam) {
        print('✅ [ExamsTab] User can take exam');
      } else {
        print('⚠️ [ExamsTab] User cannot take exam: $statusMessage');
      }
    } catch (e) {
      print('❌ [ExamsTab] Error checking eligibility: $e');
      if (mounted) {
        setState(() => isChecking = false);
        AppSnackbar.error(context, 'Error checking exam eligibility: $e');
      }
    }
  }

  Future<void> _startExam() async {
    if (userId == null || userId!.isEmpty) {
      AppSnackbar.error(context, '❌ Please log in to take an exam');
      return;
    }

    if (!canTakeExam) {
      AppSnackbar.error(context, '❌ $statusMessage');
      return;
    }

    setState(() => isLoading = true);

    try {
      print('🚀 [ExamsTab] Navigating to exam screen...');

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamScreen(),
          ),
        );

        if (result == true && mounted) {
          print('📊 [ExamsTab] Exam completed, reloading eligibility');
          await _checkExamEligibility();
        }
      }
    } catch (e) {
      print('❌ [ExamsTab] Error navigating to exam: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadExamHistory(String token) async {
    setState(() {
      isLoadingHistory = true;
    });

    try {
      print('[ExamsTab] 📡 Fetching recent exam history from API...');
      
      // Fetch real exam history from backend
      final response = await ExamService.fetchExamHistory(token);

      if (response['success'] == true && response['data'] != null) {
        final examList = response['data'] as List? ?? [];
        
        // Transform API response to match our UI format
        final transformedExams = examList.map((exam) {
          return {
            'score': exam['score'] ?? exam['correctAnswers'] ?? 0,
            'totalQuestions': exam['totalQuestions'] ?? exam['questionsCount'] ?? 20,
            'category': exam['category'] ?? exam['examCategory'] ?? 'General',
            'passed': exam['passed'] ?? (exam['status'] == 'passed'),
            'createdAt': exam['createdAt'] ?? exam['attemptDate'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        if (mounted) {
          setState(() {
            recentExams = transformedExams.take(5).toList(); // Get last 5 exams
          });
        }

        print('[ExamsTab] ✅ Exam history loaded: ${recentExams.length} exams');
      } else {
        print('[ExamsTab] ⚠️ API returned no data: ${response['message']}');
        if (mounted) {
          setState(() {
            recentExams = [];
          });
        }
      }
    } catch (e) {
      print('[ExamsTab] ❌ Error loading exam history: $e');
      if (mounted) {
        setState(() {
          recentExams = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [ExamsTab] build() called - userId: $userId, canTakeExam: $canTakeExam');

    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: Colors.green.shade600,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Practice Exam 📝",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Test your knowledge and improve driving skills",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: 24),

              // Login Check
              if (userId == null || userId!.isEmpty)
                _buildLoginRequiredCard()
              else
                ...[
                  // Plan Information Card
                  _buildPlanInfoCard(),
                  SizedBox(height: 20),

                  // Eligibility Status Card
                  _buildEligibilityCard(),
                  SizedBox(height: 24),

                  // Start Exam Button (BIG)
                  _buildStartExamButton(),
                  SizedBox(height: 32),

                  // Recent Exams History (at bottom when scrolling)
                  if (recentExams.isNotEmpty) ...[
                    Text(
                      '📊 Recent Exams',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildRecentExamsCard(),
                  ],
                ],

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequiredCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.lock, size: 48, color: Colors.orange.shade400),
          SizedBox(height: 16),
          Text(
            'Login Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You need to be logged in to take exams',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade700,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _loadUserData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
              child: Text('Try Loading Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfoCard() {
    if (isChecking || eligibilityData == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            SizedBox(height: 16),
            Text('Loading plan information...'),
          ],
        ),
      );
    }

    final planInfo = eligibilityData?['planInfo'] ?? {};
    final planName = planInfo['planName'] ?? 'No Plan';
    final isPremium = planInfo['isPremium'] ?? false;
    final subscriptionStatus = planInfo['subscriptionStatus'] ?? 'expired';

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade300),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium
                      ? Colors.purple.shade200
                      : subscriptionStatus == 'active'
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium
                      ? '⭐ PREMIUM'
                      : subscriptionStatus == 'active'
                          ? '✅ ACTIVE'
                          : '⏱️ EXPIRED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPremium
                        ? Colors.purple.shade900
                        : subscriptionStatus == 'active'
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildPlanDetail('Plan Name', planName),
          SizedBox(height: 8),
          _buildPlanDetail('Type', planInfo['planType'] ?? 'none'),
          SizedBox(height: 8),
          if (planInfo['hasUnlimitedExams'] != true && !isPremium)
            Column(
              children: [
                _buildPlanDetail(
                  'Remaining Exams',
                  '${eligibilityData?['remainingExams'] ?? 0}',
                ),
                SizedBox(height: 8),
              ],
            ),
          if (planInfo['planExpiresAt'] != null && !isPremium)
            _buildPlanDetail('Expires', _formatDate(planInfo['planExpiresAt'])),
        ],
      ),
    );
  }

  Widget _buildPlanDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEligibilityCard() {
    final color = canTakeExam ? Colors.green : Colors.red;
    final icon = canTakeExam ? Icons.check_circle : Icons.error;
    final title = canTakeExam ? 'You Are Eligible' : 'Not Eligible';

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color, semanticLabel: title),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartExamButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || isChecking || !canTakeExam) ? null : _startExam,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canTakeExam ? Colors.green.shade600 : Colors.grey.shade400,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading || isChecking)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else
              Icon(Icons.play_arrow, size: 40, color: Colors.white),
            SizedBox(height: 12),
            Text(
              canTakeExam ? 'Start Exam' : 'Exam Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!canTakeExam)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Complete your plan to take an exam',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExamsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: isLoadingHistory
          ? Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.green.shade600),
              ),
            )
          : Column(
              children: List.generate(
                recentExams.length,
                (index) {
                  final exam = recentExams[index];
                  final score = exam['score'] ?? 0;
                  final totalQuestions = exam['totalQuestions'] ?? 20;
                  final category = exam['category'] ?? 'General';
                  final date = _formatExamDate(exam['createdAt'] ?? '');
                  final passed = exam['passed'] ?? false;
                  final percentage = totalQuestions > 0
                      ? (score / totalQuestions * 100).round()
                      : 0;

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Score Circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: passed
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                border: Border.all(
                                  color: passed
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: passed
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: passed
                                              ? Colors.green.shade100
                                              : Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          passed ? '✅ PASSED' : '❌ FAILED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: passed
                                                ? Colors.green.shade900
                                                : Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '$score/$totalQuestions correct • $date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < recentExams.length - 1)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  String _formatExamDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
