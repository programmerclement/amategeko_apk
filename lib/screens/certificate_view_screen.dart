import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/certificate_service.dart';
import '../services/auth_service.dart';

class CertificateViewScreen extends StatefulWidget {
  final String? userId;

  const CertificateViewScreen({super.key, this.userId});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? certificateData;
  bool isDownloading = false;

  String recipientName = '';
  String certificateCode = '';
  String issuedAt = '';
  String verificationUrl = '';
  bool certificateEligible = false;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Get userId from params or from stored user
      String? userId = widget.userId;
      userId ??= await AuthService.getUserId();

      if (userId == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await CertificateService.getCertificateForUser(userId);

      if (!mounted) return;

      if (response['success'] == true) {
        final cert = response['certificate'] ?? {};

        setState(() {
          certificateData = response;
          certificateEligible = response['eligible'] == true;
          recipientName = cert['recipientName'] ?? '';
          certificateCode = cert['certificateCode'] ?? '';
          issuedAt = cert['issuedAt'] ?? '';
          verificationUrl = cert['verificationUrl'] ?? '';
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage =
              response['message'] ??
              'Failed to load certificate. Please try again.';
          certificateEligible = false;
        });
      }
    } catch (e) {
      print('❌ Error loading certificate: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadCertificate() async {
    if (isDownloading) return;
    if (certificateData == null) return;

    final certificateId = certificateData?['certificate']?['id'];
    if (certificateId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Certificate ID not found')));
      return;
    }

    setState(() => isDownloading = true);

    try {
      final response = await CertificateService.downloadCertificatePdf(
        certificateId,
      );
      final pdfBytes = response.bodyBytes;

      // In a real app, you'd save this to device storage or open it
      // For now, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Certificate PDF ready to download')),
      );
    } catch (e) {
      print('❌ Error downloading certificate: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download certificate')));
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  void _copyVerificationUrl() {
    if (verificationUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification URL not available')));
      return;
    }

    Clipboard.setData(ClipboardData(text: verificationUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification URL copied to clipboard')),
    );
  }

  void _verifyCertificate() {
    if (certificateCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Certificate code not found')));
      return;
    }

    _showVerificationDialog();
  }

  void _showVerificationDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter certificate code to verify:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Enter certificate code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Your certificate code: $certificateCode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a certificate code')),
                );
                return;
              }

              Navigator.pop(context);
              await _performVerification(code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _performVerification(String certificateCode) async {
    try {
      final response = await CertificateService.verifyCertificate(
        certificateCode,
      );

      if (!mounted) return;

      if (response['success'] == true && response['verified'] == true) {
        final cert = response['certificate'] ?? {};
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Certificate Valid'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VerificationDetail(
                  label: 'Certificate Code',
                  value: cert['certificateCode'] ?? '',
                ),
                SizedBox(height: 12),
                _VerificationDetail(
                  label: 'Recipient',
                  value: cert['recipientName'] ?? '',
                ),
                SizedBox(height: 12),
                _VerificationDetail(
                  label: 'Issued',
                  value: cert['issuedAt'] ?? '',
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Certificate verification failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error verifying certificate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying certificate'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Certificate'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green.shade600),
            )
          : errorMessage.isNotEmpty
          ? _buildErrorState()
          : certificateEligible
          ? _buildCertificateView()
          : _buildIneligibleState(),
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
              'Error Loading Certificate',
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
              onPressed: _loadCertificate,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIneligibleState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.orange.shade400),
            SizedBox(height: 16),
            Text(
              'Certificate Not Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Activate a monthly plan to unlock your certificate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to pricing or plans page
                // Navigator.pushNamed(context, '/pricing');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateView() {
    return RefreshIndicator(
      onRefresh: _loadCertificate,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Certificate Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.card_membership,
                          color: Colors.white,
                          size: 28,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Certificate of Completion',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Text(
                      recipientName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(height: 1, color: Colors.white24),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificate ID',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              certificateCode,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Issued Date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(issuedAt),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Certificate Details Section
              Text(
                'Certificate Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Recipient', value: recipientName),
                    Divider(height: 16),
                    _DetailRow(
                      label: 'Certificate Code',
                      value: certificateCode,
                    ),
                    Divider(height: 16),
                    _DetailRow(
                      label: 'Issued Date',
                      value: _formatDate(issuedAt),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Action Buttons
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadCertificate,
                  icon: isDownloading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(Icons.download),
                  label: Text(
                    isDownloading
                        ? 'Downloading...'
                        : 'Download Certificate PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyVerificationUrl,
                      icon: Icon(Icons.link),
                      label: Text('Copy Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _verifyCertificate,
                      icon: Icon(Icons.verified),
                      label: Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Verification Info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Verification Information',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Others can verify your certificate by scanning the QR code or visiting your verification link. Your certificate is tamper-proof and can be trusted.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}

class _VerificationDetail extends StatelessWidget {
  final String label;
  final String value;

  const _VerificationDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
