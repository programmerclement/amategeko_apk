import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/certificate_service.dart';
import '../services/referral_service.dart';
import '../widgets/stat_card.dart';
import 'exam_screen.dart';
import 'exam_history_screen.dart';
import 'certificate_view_screen.dart';
import 'referral_tracking_screen.dart';

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

  // Exam eligibility
  bool canTakeExam = true;
  String eligibilityMessage = '';

  // Referral data
  String referralCode = '';
  int referralCount = 0;
  double referralEarnings = 0.0;
  int pendingBonusCount = 0;
  int claimedBonusCount = 0;
  String shareUrl = '';

  // Certificate data
  bool certificateEligible = false;
  String certificateMessage = '';
  String certificateUrl = '';
  String certificateNumber = '';
  String certificateIssuedAt = '';

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
      if (profileResponse.containsKey('message') &&
          !profileResponse.containsKey('_id')) {
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

      // Referral tracking fields
      referralCode =
          profileResponse['referralCode'] ??
          profileResponse['inviteCode'] ??
          '';
      referralCount =
          profileResponse['referralCount'] ??
          profileResponse['referralsCount'] ??
          profileResponse['referredUsers']?.length ??
          0;
      final referralEarningsValue =
          profileResponse['referralEarnings'] ??
          profileResponse['referralBonus'] ??
          profileResponse['referralIncome'] ??
          0;
      referralEarnings = referralEarningsValue is num
          ? referralEarningsValue.toDouble()
          : double.tryParse('$referralEarningsValue') ?? 0.0;

      // Certificate metadata
      final certificateData =
          profileResponse['certificate'] ??
          profileResponse['certificateData'] ??
          {};
      certificateEligible =
          certificateData['eligible'] == true ||
          certificateData['isEligible'] == true ||
          certificateData['status']?.toString().toLowerCase() == 'ready';
      certificateMessage =
          certificateData['message'] ??
          certificateData['status'] ??
          (certificateEligible
              ? 'Your certificate is ready to download.'
              : 'Complete a passing exam or subscribe to unlock your certificate.');
      certificateUrl =
          certificateData['url'] ??
          certificateData['certificateUrl'] ??
          certificateData['downloadUrl'] ??
          '';
      certificateNumber =
          certificateData['certificateCode'] ??
          certificateData['certificateId'] ??
          certificateData['id'] ??
          '';
      certificateIssuedAt =
          certificateData['issuedAt'] ?? certificateData['date'] ?? '';

      // Parse stats from profile
      final stats = profileResponse['stats'] ?? {};
      totalExamsTaken = stats['totalExamsTaken'] ?? 0;
      averageScore = (stats['averageScore'] ?? 0).toDouble();
      bestScore = (stats['bestScore'] ?? 0).toDouble();

      // Step 2: Fetch exam history
      final examResponse = await ApiService.fetchExamHistory();

      // Step 2.25: Fetch certificate data directly
      if (userId.isNotEmpty) {
        try {
          print('📜 [Dashboard] Loading certificate data for user: $userId');
          final certResponse = await CertificateService.getCertificateForUser(
            userId,
          );
          print('📜 [Dashboard] Certificate response: $certResponse');

          if (certResponse['success'] == true) {
            final cert = certResponse['certificate'] ?? {};
            certificateEligible = certResponse['eligible'] == true;
            certificateMessage = certResponse['message'] ?? certificateMessage;
            certificateNumber =
                cert['certificateCode'] ??
                cert['certificateId'] ??
                cert['id'] ??
                '';
            certificateIssuedAt = cert['issuedAt'] ?? '';

            print(
              '✅ [Dashboard] Certificate loaded: eligible=$certificateEligible, code=$certificateNumber',
            );
          } else {
            certificateEligible = false;
            certificateMessage =
                certResponse['message'] ?? 'Certificate not available';
            print(
              'ℹ️ [Dashboard] Certificate not eligible: ${certResponse['message']}',
            );
          }
        } catch (e) {
          print('❌ [Dashboard] Error loading certificate: $e');
          // Continue with profile data fallback
        }
      }

      // Step 2.3: Fetch referral data
      try {
        print('🔗 [Dashboard] Loading referral data');
        final referralResponse = await ReferralService.getReferralInfo();

        if (referralResponse['referralCode'] != null) {
          referralCode = referralResponse['referralCode'] ?? '';
          shareUrl = referralResponse['shareData']?['url'] ?? '';

          final referralStats = referralResponse['referralStats'] ?? {};
          referralCount = referralStats['referralCount'] ?? 0;

          print(
            '✅ [Dashboard] Referral loaded: code=$referralCode, count=$referralCount',
          );
        }
      } catch (e) {
        print('❌ [Dashboard] Error loading referral: $e');
      }

      // Step 2.5: Check exam eligibility
      final eligibilityResponse = await ApiService.checkExamEligibility();
      if (eligibilityResponse['success'] == true) {
        canTakeExam =
            eligibilityResponse['canTakeExam'] == true ||
            eligibilityResponse['eligible'] == true;
        eligibilityMessage =
            eligibilityResponse['message'] ??
            (canTakeExam
                ? 'You may start an exam now.'
                : 'You are not eligible to start a new exam yet.');
      } else {
        canTakeExam = false;
        eligibilityMessage =
            eligibilityResponse['message'] ??
            'Unable to check exam eligibility.';
      }

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

  void _copyReferralCode() {
    if (referralCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No referral code available yet.')),
      );
      return;
    }

    final shareLink = 'https://amategeko.app/referral/$referralCode';
    Clipboard.setData(ClipboardData(text: shareLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Referral link copied to clipboard')),
    );
  }

  void _startExam() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamScreen()));
  }

  Widget _buildCertificateSection() {
    print(
      '🎖️ [CertificateSection] Building - eligible: $certificateEligible, code: $certificateNumber',
    );

    return GestureDetector(
      onTap: certificateEligible
          ? () {
              print(
                '🎖️ [CertificateSection] Tapped - navigating to certificate view',
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CertificateViewScreen(userId: userId),
                ),
              );
            }
          : null,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: certificateEligible
              ? Colors.green.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: certificateEligible
                ? Colors.green.shade300
                : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (certificateEligible ? Colors.green : Colors.grey)
                  .withValues(alpha: 0.08),
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
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      color: certificateEligible ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Certificate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
                if (certificateEligible)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Ready',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (certificateEligible) ...[
              if (certificateNumber.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Certificate #: $certificateNumber',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (certificateIssuedAt.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Issued: $certificateIssuedAt',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CertificateViewScreen(userId: userId),
                          ),
                        );
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text('View Certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: Size(double.infinity, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                certificateMessage,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(certificateMessage)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  minimumSize: Size(double.infinity, 44),
                  foregroundColor: Colors.grey.shade900,
                ),
                child: Text('Certificate Info'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ReferralTrackingScreen()));
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple.shade600, size: 24),
                SizedBox(width: 8),
                Text(
                  'Referral Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple.shade600,
                  size: 16,
                ),
              ],
            ),
            SizedBox(height: 12),
            if (referralCode.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.code, color: Colors.purple.shade600, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Code: $referralCode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invited',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$referralCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.purple.shade200),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$pendingBonusCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.purple.shade200),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Claimed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$claimedBonusCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (referralCode.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Tap to view details and claim bonuses',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canTakeExam ? _startExam : null,
                      icon: Icon(Icons.play_arrow),
                      label: Text(
                        canTakeExam ? 'Start Exam' : 'Eligibility Pending',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canTakeExam
                            ? Colors.green.shade600
                            : Colors.grey.shade400,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
              if (!canTakeExam) ...[
                SizedBox(height: 10),
                Text(
                  eligibilityMessage,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
              SizedBox(height: 20),

              // Stats Grid - Real Data from API
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 10,
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
                      color: Colors.purple.withValues(alpha: 0.2),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Exams",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ExamHistoryScreen()),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
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

              SizedBox(height: 24),
              _buildCertificateSection(),
              _buildReferralSection(),
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
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "${date.day}/${date.month}/${date.year} $hour:$minute";
    } catch (e) {
      return dateStr;
    }
  }

  void _viewExamDetails(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExamHistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final passed = exam['passed'] ?? false;
    final statusColor = passed ? Colors.green : Colors.red;
    final score = exam['score'] ?? 0;
    final category = exam['category'] ?? 'General';
    final difficulty = exam['difficulty'] ?? 'N/A';
    final date = _formatDate(exam['createdAt']);

    return GestureDetector(
      onTap: () => _viewExamDetails(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
                    color: statusColor.withValues(alpha: 0.1),
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
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        color: color.withValues(alpha: 0.1),
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
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "${date.day}/${date.month}/${date.year} $hour:$minute";
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
              color: Colors.orange.withValues(alpha: 0.1),
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
                "RWF ${(amount is int ? amount.toDouble() : amount).toStringAsFixed(0)}",
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
                  color: statusColor.withValues(alpha: 0.1),
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
