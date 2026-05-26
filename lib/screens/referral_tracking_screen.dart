import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/referral_service.dart';
import '../widgets/app_snackbar.dart';

class ReferralTrackingScreen extends StatefulWidget {
  const ReferralTrackingScreen({super.key});

  @override
  State<ReferralTrackingScreen> createState() => _ReferralTrackingScreenState();
}

class _ReferralTrackingScreenState extends State<ReferralTrackingScreen> {
  bool isLoading = true;
  String errorMessage = '';

  String referralCode = '';
  String shareUrl = '';
  int referralCount = 0;
  List<dynamic> invitedUsers = [];
  List<dynamic> pendingBonuses = [];
  List<dynamic> claimedBonuses = [];
  int pendingBonusCount = 0;
  int claimedBonusCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ReferralService.getReferralInfo();

      if (!mounted) return;

      if (response['referralCode'] != null) {
        final referralStats = response['referralStats'] ?? {};
        final referrals = referralStats['referrals'] ?? [];

        setState(() {
          referralCode = response['referralCode'] ?? '';
          shareUrl = response['shareData']?['url'] ?? '';
          referralCount = referralStats['referralCount'] ?? 0;
          invitedUsers = referrals;
          isLoading = false;
        });

        // Load pending bonuses
        await _loadPendingBonuses();
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load referral data';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading referral data: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingBonuses() async {
    try {
      final response = await ReferralService.getPendingBonuses();

      if (!mounted) return;

      setState(() {
        pendingBonuses = response['pendingBonuses'] ?? [];
        claimedBonuses = response['claimedBonuses'] ?? [];
        pendingBonusCount = response['pendingCount'] ?? 0;
        claimedBonusCount = response['claimedCount'] ?? 0;
      });

      print(
        '✅ Pending bonuses loaded: $pendingBonusCount pending, $claimedBonusCount claimed',
      );
    } catch (e) {
      print('❌ Error loading pending bonuses: $e');
    }
  }

  void _copyReferralCode() {
    if (referralCode.isEmpty) {
      AppSnackbar.error(context, 'Referral code not available');
      return;
    }

    Clipboard.setData(ClipboardData(text: shareUrl));
    AppSnackbar.success(context, 'Referral link copied to clipboard');
  }

  void _shareReferralCode() {
    if (shareUrl.isEmpty) {
      AppSnackbar.error(context, 'Share link not available');
      return;
    }

    try {
      final shareMessage =
          'Join my exam platform and get free exam attempts! Use my referral code: $referralCode';
      final shareText = '$shareMessage\n$shareUrl';

      Share.share(shareText, subject: 'Join My Exam Platform - Referral Link');
    } catch (e) {
      print('❌ Share error: $e');
      AppSnackbar.error(context, 'Error opening share: ${e.toString()}');
    }
  }

  Future<void> _claimBonus(int index) async {
    try {
      final response = await ReferralService.claimBonusExam(index);

      if (!mounted) return;

      if (response['success'] == true) {
        AppSnackbar.success(
          context,
          '✅ Bonus exam claimed! You now have 1 free attempt.',
        );
        await _loadPendingBonuses();
      } else {
        AppSnackbar.error(
          context,
          response['message'] ?? 'Failed to claim bonus',
        );
      }
    } catch (e) {
      AppSnackbar.error(context, 'Error claiming bonus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Referral Tracking'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green.shade600),
            )
          : errorMessage.isNotEmpty
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Referral Code Section
                      _buildReferralCodeSection(),
                      SizedBox(height: 20),

                      // Stats Section
                      _buildStatsSection(),
                      SizedBox(height: 20),

                      // Pending Bonuses Section
                      if (pendingBonusCount > 0) ...[
                        _buildPendingBonusesSection(),
                        SizedBox(height: 20),
                      ],

                      // Invited Users Section
                      _buildInvitedUsersSection(),
                      SizedBox(height: 20),

                      // Claimed Bonuses Section
                      if (claimedBonusCount > 0) ...[
                        _buildClaimedBonusesSection(),
                        SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              'Error Loading Referral Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReferralData,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(120, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Code',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            referralCode,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyReferralCode,
                  icon: Icon(Icons.copy),
                  label: Text('Copy Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 44),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareReferralCode,
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.people,
              label: 'Invited',
              value: '$referralCount',
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatItem(
              icon: Icons.card_giftcard,
              label: 'Pending',
              value: '$pendingBonusCount',
              color: Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle,
              label: 'Claimed',
              value: '$claimedBonusCount',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBonusesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Bonuses (${pendingBonuses.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 12),
        ...pendingBonuses.asMap().entries.map((entry) {
          final index = entry.key;
          final bonus = entry.value;
          final bonusData = bonus as Map<String, dynamic>;
          final referredName =
              bonusData['referredName'] ??
              bonusData['referredUsername'] ??
              'User';
          final createdAt = bonusData['createdAt'] ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.orange.shade600,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Exam from $referredName',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _claimBonus(bonusData['index'] ?? index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: Size(80, 40),
                  ),
                  child: Text(
                    'Claim',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper: Find pending bonus for a user
  Map<String, dynamic>? _getPendingBonusForUser(String userName) {
    for (int i = 0; i < pendingBonuses.length; i++) {
      final bonus = pendingBonuses[i] as Map<String, dynamic>;
      final referredName =
          bonus['referredName'] ?? bonus['referredUsername'] ?? '';
      if (referredName.toLowerCase() == userName.toLowerCase()) {
        bonus['index'] = bonus['index'] ?? i;
        return bonus;
      }
    }
    return null;
  }

  // Helper: Check if user already claimed bonus
  bool _hasClaimedBonus(String userName) {
    for (final bonus in claimedBonuses) {
      final bonusData = bonus as Map<String, dynamic>;
      final referredName =
          bonusData['referredName'] ?? bonusData['referredUsername'] ?? '';
      if (referredName.toLowerCase() == userName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Widget _buildInvitedUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invited Users ($referralCount)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 12),
        if (invitedUsers.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 12),
                Text(
                  'No invited users yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ...invitedUsers.map((user) {
            final userData = user as Map<String, dynamic>;
            final referredName =
                userData['referredName'] ?? userData['username'] ?? 'User';
            final completedPayment = userData['completedPayment'] ?? false;
            final registeredAt = userData['registeredAt'] ?? '';

            // Check bonus status
            final pendingBonus = _getPendingBonusForUser(referredName);
            final alreadyClaimed = _hasClaimedBonus(referredName);

            return Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pendingBonus != null
                      ? Colors.orange.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: completedPayment
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      completedPayment ? Icons.check_circle : Icons.person,
                      color: completedPayment
                          ? Colors.green.shade600
                          : Colors.blue.shade600,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referredName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          completedPayment
                              ? '✅ Purchased (Bonus earned)'
                              : '⏳ Registered ${_formatDate(registeredAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: completedPayment
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  if (!completedPayment)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else if (alreadyClaimed)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✅ Claimed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    )
                  else if (pendingBonus != null)
                    ElevatedButton(
                      onPressed: () => _claimBonus(pendingBonus['index'] ?? 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size(0, 32),
                      ),
                      child: Text(
                        'Claim Bonus',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'No Bonus',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildClaimedBonusesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Claimed Bonuses (${claimedBonuses.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 12),
        ...claimedBonuses.map((bonus) {
          final bonusData = bonus as Map<String, dynamic>;
          final referredName =
              bonusData['referredName'] ??
              bonusData['referredUsername'] ??
              'User';
          final claimedAt = bonusData['claimedAt'] ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Claimed from $referredName',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'Claimed ${_formatDate(claimedAt)}',
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
          );
        }),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
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
        return "${date.day}/${date.month}/${date.year} at $timeStr";
      }
    } catch (e) {
      return dateStr;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
