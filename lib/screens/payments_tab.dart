import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/app_snackbar.dart';
import 'exam_screen.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  // Payment flow screens: 'history', 'selectPlan', 'paymentDetails', 'confirmation', 'result'
  String currentScreen = 'history';
  
  // Data
  bool isLoading = false;
  bool isInitializing = true;
  String? userId;
  List<dynamic> pricingPlans = [];
  List<dynamic> paymentHistory = [];
  
  // Payment process
  String selectedNetwork = 'MTN';
  String phoneNumber = '';
  dynamic selectedPlanForPayment;
  String? currentPaymentReference;
  String paymentResultStatus = ''; // 'success' or 'failed'
  String paymentResultMessage = '';
  
  bool isPaymentProcessing = false;
  Timer? ussdCountdownTimer;
  int ussdTimeoutSeconds = 120; // 2 minutes

  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  @override
  void deactivate() {
    print('👋 [PaymentsTab] Tab deactivated');
    super.deactivate();
  }

  @override
  void activate() {
    print('👋 [PaymentsTab] Tab activated - reloading user data');
    super.activate();
    _loadUserData();
    _loadPaymentHistory();
  }

  Future<void> _initializeTab() async {
    print('🔄 [PaymentsTab] Initializing tab...');
    if (mounted) {
      setState(() => isInitializing = true);
    }
    
    await _loadUserData();
    await _loadPricingPlans();
    await _loadPaymentHistory();
    
    if (mounted) {
      setState(() => isInitializing = false);
    }
  }

  Future<void> _loadPaymentHistory() async {
    try {
      print('🔄 [PaymentsTab] Loading payment history...');
      final token = await AuthService.getToken();
      if (token != null) {
        // Fetch actual payment history from API
        final response = await PaymentService.fetchPaymentHistory(token);
        if (response['success']) {
          setState(() {
            paymentHistory = response['data'] ?? [];
          });
          print('✅ Payment history loaded: ${paymentHistory.length} items');
        } else {
          print('⚠️ Failed to load payment history: ${response['message']}');
        }
      }
    } catch (e) {
      print('❌ Error loading payment history: $e');
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    ussdCountdownTimer?.cancel();
    super.dispose();
  }

  // ========== OLD MODAL CODE REMOVED - REPLACED WITH MULTI-SCREEN SYSTEM ABOVE ==========

  // Auto-detect network from phone number
  String getNetworkFromPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Extract first 2 digits (after the leading 7)
    if (cleanPhone.length >= 2) {
      final prefix = cleanPhone.substring(0, 2);
      
      // Airtel: 72, 73
      if (prefix == '72' || prefix == '73') {
        return 'AIRTEL';
      }
      
      // MTN: 78, 79
      if (prefix == '78' || prefix == '79') {
        return 'MTN';
      }
    }
    
    return 'MTN'; // Default to MTN
  }

  // Poll payment status until confirmed or failed
  Future<Map<String, dynamic>> pollPaymentStatus(
    String reference, {
    int maxAttempts = 60, // 60 attempts * 5 seconds = 5 minutes
    int intervalSeconds = 5,
  }) async {
    print('🔄 [PaymentsTab] Starting payment poll for reference: $reference');
    
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await ApiService.checkPaymentStatus(reference);
        
        print('📊 [PaymentsTab] Poll attempt ${i + 1}/$maxAttempts: ${response['status']}');
        
        if (response['success'] == true && response['status'] == 'SUCCESSFUL') {
          print('✅ [PaymentsTab] Payment SUCCESSFUL!');
          return {
            'success': true,
            'status': 'SUCCESSFUL',
            'response': response,
          };
        }
        
        if (response['status'] == 'FAILED' || 
            response['status'] == 'CANCELLED' || 
            response['status'] == 'EXPIRED') {
          print('❌ [PaymentsTab] Payment ${response['status']}');
          return {
            'success': false,
            'status': response['status'],
            'message': response['message'] ?? 'Payment ${response['status'].toLowerCase()}',
            'response': response,
          };
        }
        
        // Still pending, wait before next attempt
        if (i < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: intervalSeconds));
        }
      } catch (e) {
        print('❌ [PaymentsTab] Poll error: $e');
        // Continue polling on error
        if (i < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: intervalSeconds));
        }
      }
    }
    
    // Timeout after max attempts
    print('⏰ [PaymentsTab] Payment polling timed out');
    return {
      'success': false,
      'status': 'TIMEOUT',
      'message': 'Payment confirmation timed out. Please check your payment status.',
    };
  }

  Future<void> _loadUserData() async {
    try {
      print('🔄 [PaymentsTab] Loading user ID...');
      
      // Get userId using the proper AuthService method
      final loadedUserId = await AuthService.getUserId();
      
      print('📍 [PaymentsTab] Retrieved userId: $loadedUserId');
      print('📍 [PaymentsTab] userId type: ${loadedUserId.runtimeType}');
      print('📍 [PaymentsTab] userId isEmpty: ${loadedUserId?.isEmpty}');
      
      if (mounted) {
        setState(() {
          userId = loadedUserId;
        });
      }
      
      print('👤 [PaymentsTab] User ID loaded: $userId');
      
      if (userId == null || userId!.isEmpty) {
        print('⚠️ [PaymentsTab] No user ID found - user may not be logged in');
        if (mounted) {
          AppSnackbar.warning(context, 'Please log in to make payments');
        }
      } else {
        print('✅ [PaymentsTab] User ID confirmed: $userId');
      }
    } catch (e) {
      print('❌ [PaymentsTab] Error loading user data: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Error loading user information');
      }
    }
  }

  Future<void> _loadPricingPlans() async {
    setState(() => isLoading = true);

    try {
      print('🔄 Loading pricing plans from API...');
      final response = await ApiService.fetchPublicPricingPlans();

      print('📦 Response received: $response');
      print('📊 Response type: ${response.runtimeType}');

      if (mounted) {
        setState(() {
          // Handle different response formats
          if (response is List && response.isNotEmpty) {
            print('✅ Response is List');
            pricingPlans = response;
          } else if (response is Map) {
            print('✅ Response is Map - checking format');
            
            // Try different keys
            if (response.containsKey('data') && response['data'] is List) {
              print('✅ Found data key');
              pricingPlans = response['data'];
            } else if (response.containsKey('plans') && response['plans'] is List) {
              print('✅ Found plans key');
              pricingPlans = response['plans'];
            } else {
              print('⚠️ No valid data in response, using defaults');
              pricingPlans = _getDefaultPlans();
            }
          } else {
            print('❌ Invalid response format: ${response.runtimeType}');
            pricingPlans = _getDefaultPlans();
          }
          
          print('✨ Final plans: ${pricingPlans.length} plans loaded');
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading plans: $e');
      if (mounted) {
        setState(() {
          pricingPlans = _getDefaultPlans();
          isLoading = false;
        });
        AppSnackbar.error(context, 'Error loading plans: ${e.toString()}');
      }
    }
  }

  List<dynamic> _getDefaultPlans() {
    return [
      {
        '_id': '1',
        'name': 'Starter',
        'price': 2000,
        'currency': 'RWF',
        'duration': 'one-time',
        'examAttempts': 5,
        'features': ['5 Exam Attempts', 'Basic Support'],
        'isActive': true,
      },
      {
        '_id': '2',
        'name': 'Professional',
        'price': 5000,
        'currency': 'RWF',
        'duration': 'one-time',
        'examAttempts': 15,
        'features': [
          '15 Exam Attempts',
          'Performance Analytics',
          'Priority Support',
          'Study Materials',
        ],
        'isActive': true,
      },
      {
        '_id': '3',
        'name': 'Premium',
        'price': 10000,
        'currency': 'RWF',
        'duration': 'one-time',
        'examAttempts': 50,
        'features': [
          '50 Exam Attempts',
          'Expert Coaching',
          'All Features',
          '24/7 Support',
          'Certificate',
        ],
        'isActive': true,
      },
      {
        '_id': '4',
        'name': 'Weekly Pass',
        'price': 3000,
        'currency': 'RWF',
        'duration': 'weekly',
        'examAttempts': 999999,
        'features': [
          '∞ Unlimited Attempts',
          'Valid for 7 days',
          'Full Access',
          'Study Materials',
          'Performance Tracking',
        ],
        'isActive': true,
        'popular': false,
      },
      {
        '_id': '5',
        'name': 'Monthly Pass',
        'price': 10000,
        'currency': 'RWF',
        'duration': 'monthly',
        'examAttempts': 999999,
        'features': [
          '∞ Unlimited Attempts',
          'Valid for 30 days',
          'Full Premium Access',
          'All Study Materials',
          'Performance Analytics',
          'Priority Support',
        ],
        'isActive': true,
        'popular': true,
      },
      {
        '_id': '6',
        'name': 'Yearly Pass',
        'price': 100000,
        'currency': 'RWF',
        'duration': 'yearly',
        'examAttempts': 999999,
        'features': [
          '∞ Unlimited Attempts',
          'Valid for 365 days',
          'Complete Premium Access',
          'Expert Coaching Sessions',
          'All Study Resources',
          '24/7 Priority Support',
          'Certificate Upon Completion',
        ],
        'isActive': true,
        'popular': false,
      },
    ];
  }

  Future<void> _initiatePayment(String planId) async {
    // Validate user is logged in FIRST
    if (userId == null || userId!.isEmpty) {
      AppSnackbar.error(
        context, 
        '❌ User not logged in\n\nPlease log in to make a payment',
      );
      print('⚠️ Payment attempt without userId');
      return;
    }

    // Validate phone number
    if (phoneNumber.isEmpty) {
      AppSnackbar.error(context, 'Please enter your phone number');
      return;
    }

    // Validate phone format (should be 9 digits like 788123456)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('7') || cleanPhone.length != 9) {
      AppSnackbar.error(
        context, 
        'Phone number must be 9 digits starting with 7\nExample: 788123456',
      );
      return;
    }

    // Find plan
    final plan = pricingPlans.firstWhere(
      (p) => p['_id'] == planId,
      orElse: () => null,
    );

    if (plan == null) {
      AppSnackbar.error(context, 'Plan not found. Please refresh and try again.');
      return;
    }

    // Validate plan has required fields
    if (plan['price'] == null || plan['name'] == null) {
      AppSnackbar.error(context, 'Invalid plan data. Please refresh and try again.');
      return;
    }

    // Auto-detect network from phone
    final detectedNetwork = getNetworkFromPhone(cleanPhone);
    print('📱 Detected network: $detectedNetwork');

    setState(() => isPaymentProcessing = true);

    try {
      final phoneWithZero = '0' + cleanPhone; // Add 0 prefix to make 10 digits
      
      print('💰 Initiating payment:');
      print('User ID: $userId');
      print('Plan: ${plan?['name'] ?? 'Unknown'}');
      print('Amount: ${plan?['price'] ?? 0} RWF');
      print('Phone: $phoneWithZero');
      print('Network: $detectedNetwork');

      // Show PIN confirmation prompt immediately
      _showPINConfirmationDialog(
        phoneNumber: cleanPhone,
        network: detectedNetwork,
        amount: plan?['price'] ?? 0,
        planName: plan?['name'] ?? 'Plan',
      );

      // Call payment API
      final response = await ApiService.initiatePayment(
        amount: (plan?['price'] ?? 0).toString(),
        phone: phoneWithZero,
        network: detectedNetwork,
        planId: planId,
        userId: userId!,
      );

      if (!mounted) return;

      print('✅ Payment Response: $response');

      if (response['success'] == true) {
        // Payment initiated successfully
        final reference = response['reference'] ?? response['req_ref'];
        currentPaymentReference = reference;

        print('🔄 Payment initiated - showing USSD prompt with 2-minute timeout');

        // Show USSD code with 2-minute timeout
        _showUSSDPromptWithTimeout(
          reference: reference,
          planName: plan?['name'] ?? 'Plan',
          amount: plan?['price'] ?? 0,
          network: detectedNetwork,
          phone: phoneNumber,
          planId: planId,
        );

          // Clear form
          phoneController.clear();
          setState(() {
            phoneNumber = '';
            selectedPlanForPayment = null;
            currentPaymentReference = null;
          });
      } else {
        final errorMessage = response['message'] ?? '';
        final displayMessage = errorMessage.isNotEmpty
            ? errorMessage
            : 'Dear client payment failed due to unknown error or you don\'t have enough amount to complete this transaction please try again later or contact 0780100211';
        AppSnackbar.error(
          context,
          displayMessage,
        );
        setState(() {
          paymentResultStatus = 'FAILED';
          paymentResultMessage = displayMessage;
          currentScreen = 'result';
          isPaymentProcessing = false;
          currentPaymentReference = null;
        });
      }
    } catch (e) {
      print('Payment error: $e');
      final errorMessage = e.toString();
      final displayMessage = errorMessage.contains('400') || errorMessage.isNotEmpty
          ? 'Dear client payment failed due to unknown error or you don\'t have enough amount to complete this transaction please try again later or contact 0780100211'
          : 'Error: $errorMessage';
      AppSnackbar.error(context, displayMessage);
      setState(() {
        paymentResultStatus = 'FAILED';
        paymentResultMessage = displayMessage;
        currentScreen = 'result';
        isPaymentProcessing = false;
        currentPaymentReference = null;
      });
    } finally {
      if (mounted) {
        setState(() => isPaymentProcessing = false);
      }
    }
  }

  void _showPaymentConfirmation({
    required String planName,
    required int amount,
    required String reference,
    required String network,
    required String phone,
  }) {
    // Get the selected plan to show duration
    if (selectedPlanForPayment == null) {
      print('⚠️ selectedPlanForPayment is null in confirmation');
      return;
    }
    
    final selectedPlan = pricingPlans.firstWhere(
      (p) => p['_id'] == selectedPlanForPayment['_id'],
      orElse: () => null,
    );

    String durationText = 'One-time';
    String durationInfo = '';
    
    if (selectedPlan != null) {
      final duration = selectedPlan['duration'] ?? 'one-time';
      final examAttempts = selectedPlan['examAttempts'] ?? 0;
      
      if (duration == 'weekly') {
        durationText = 'Weekly - Valid for 7 days';
        durationInfo = 'Unlimited ($examAttempts) exam attempts';
      } else if (duration == 'monthly') {
        durationText = 'Monthly - Valid for 30 days';
        durationInfo = 'Unlimited ($examAttempts) exam attempts';
      } else if (duration == 'yearly') {
        durationText = 'Yearly - Valid for 365 days';
        durationInfo = 'Unlimited ($examAttempts) exam attempts';
      } else {
        durationText = 'One-time';
        durationInfo = '$examAttempts exam attempts';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Payment Initiated',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Complete the payment prompt on your phone',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfirmationRow('Plan', planName),
                    _ConfirmationRow('Duration', durationText),
                    _ConfirmationRow('Attempts', durationInfo),
                    _ConfirmationRow('Amount', '$amount RWF'),
                    _ConfirmationRow('Network', network),
                    _ConfirmationRow('Phone', phone),
                    _ConfirmationRow('Reference', reference),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUSSDPromptWithTimeout({
    required String reference,
    required String planName,
    required int amount,
    required String network,
    required String phone,
    required String planId,
  }) {
    int remainingSeconds = ussdTimeoutSeconds;
    
    // Cancel any existing timer
    ussdCountdownTimer?.cancel();
    
    // Start countdown timer
    ussdCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      remainingSeconds--;
      
      if (remainingSeconds <= 0) {
        timer.cancel();
        Navigator.pop(context); // Close dialog
        
        // Show timeout failed screen
        setState(() {
          paymentResultStatus = 'TIMEOUT';
          paymentResultMessage = 'Payment confirmation timed out. The 2-minute window to dial *182*7*2# has expired.';
          currentScreen = 'result';
          isPaymentProcessing = false;
        });
      }
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Update remaining time display
          ussdCountdownTimer?.cancel();
          ussdCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            if (mounted) {
              setState(() {
                remainingSeconds--;
                if (remainingSeconds <= 0) {
                  timer.cancel();
                  Navigator.pop(context);
                  this.setState(() {
                    paymentResultStatus = 'TIMEOUT';
                    paymentResultMessage = 'Payment confirmation timed out. The 2-minute window to dial *182*7*2# has expired.';
                    currentScreen = 'result';
                    isPaymentProcessing = false;
                  });
                }
              });
            }
          });
          
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_in_talk,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Complete Your Payment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Dial this code on your phone to complete the payment:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 20),
                  // USSD Code Display
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '*182*7*2#',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Press CALL',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Payment Details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow('Plan', planName),
                        _DetailRow('Amount', '$amount RWF'),
                        _DetailRow('Network', network),
                        _DetailRow('Phone', phone),
                        _DetailRow('Reference', reference),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Countdown Timer
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Time Remaining:',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: seconds < 30 ? Colors.red : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'After dialing, this dialog will close automatically when payment is confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ussdCountdownTimer?.cancel();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Clean up timer when dialog is closed
      ussdCountdownTimer?.cancel();
    });
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [PaymentsTab] build() - currentScreen: $currentScreen');

    if (isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (userId == null || userId!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.orange.shade400),
            SizedBox(height: 20),
            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You need to be logged in to purchase a plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AppSnackbar.info(context, 'Please log in from your profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Go to Login'),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: _loadUserData,
              child: Text('Try Loading Again'),
            ),
          ],
        ),
      );
    }

    // Route to different screens
    if (currentScreen == 'history') {
      return _buildPaymentHistoryScreen();
    } else if (currentScreen == 'selectPlan') {
      return _buildSelectPlanScreen();
    } else if (currentScreen == 'paymentDetails') {
      return _buildPaymentDetailsScreen();
    } else if (currentScreen == 'confirmation') {
      return _buildConfirmationScreen();
    } else if (currentScreen == 'result') {
      return _buildResultScreen();
    }

    return _buildPaymentHistoryScreen();
  }

  // ========== SCREEN 1: PAYMENT HISTORY ==========
  Widget _buildPaymentHistoryScreen() {
    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      color: Colors.green.shade600,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your purchases',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.receipt_long, color: Colors.white, size: 32),
                ],
              ),
            ),

            // Make Payment Button (on top)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentScreen = 'selectPlan';
                      phoneNumber = '';
                      phoneController.clear();
                    });
                    _loadPricingPlans();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Make Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Payment History List or Empty State
            if (paymentHistory.isEmpty)
              Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                    SizedBox(height: 16),
                    Text(
                      'No payments yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Purchase a plan to see your payment history',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: paymentHistory.map<Widget>((payment) {
                    return _buildPaymentHistoryItem(payment);
                  }).toList(),
                ),
              ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryItem(dynamic payment) {
    final status = payment['status'] ?? 'PENDING';
    final statusColor = status == 'SUCCESSFUL'
        ? Colors.green
        : status == 'FAILED'
            ? Colors.red
            : status == 'PENDING'
                ? Colors.orange
                : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['planName'] ?? 'Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${payment['amount'] ?? 0} RWF',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  payment['createdAt'] ?? '--',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 13, color: Colors.grey.shade600),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  payment['phoneNumber'] ?? '--',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          if (payment['reference'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.tag, size: 13, color: Colors.grey.shade600),
                SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reference copied!')),
                      );
                    },
                    child: Text(
                      payment['reference'] ?? '--',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ========== SCREEN 2: SELECT PLAN ==========
  Widget _buildSelectPlanScreen() {
    if (isLoading && pricingPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            SizedBox(height: 16),
            Text('Loading plans...'),
          ],
        ),
      );
    }

    if (pricingPlans.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text('No plans available'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => currentScreen = 'history');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
              ),
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => currentScreen = 'history');
                },
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose the plan that suits you',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Plans List
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: pricingPlans.map<Widget>((plan) {
                  final isFreeplan = (plan['price'] ?? 0) == 0;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isFreeplan) {
                            _activateFreePlanDirect(plan);
                          } else {
                            setState(() {
                              selectedPlanForPayment = plan;
                              currentScreen = 'paymentDetails';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan['name'] ?? 'Plan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if ((plan['examAttempts'] ?? 0) > 0)
                                          Text(
                                            '${plan['examAttempts']} exam attempts',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    isFreeplan ? 'Free' : '${plan['price']} RWF',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isFreeplan
                                          ? Colors.green.shade600
                                          : Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (isFreeplan)
                                Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _activateFreePlanDirect(plan);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: Text('Activate'),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedPlanForPayment = plan;
                                          currentScreen = 'paymentDetails';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: Text('Continue'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== SCREEN 3: PAYMENT DETAILS ==========
  Widget _buildPaymentDetailsScreen() {
    if (selectedPlanForPayment == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() => currentScreen = 'selectPlan');
          },
          child: Text('Go Back'),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => currentScreen = 'selectPlan');
                },
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enter your phone number',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Summary
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        _PaymentSummaryRow('Plan', selectedPlanForPayment['name'] ?? 'Plan'),
                        _PaymentSummaryRow('Amount', '${selectedPlanForPayment['price'] ?? 0} RWF'),
                        _PaymentSummaryRow('Exam Attempts', '${selectedPlanForPayment['examAttempts'] ?? 0}'),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Phone Input
                  Text(
                    'Phone Number',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !isPaymentProcessing,
                    maxLength: 9,
                    onChanged: (value) {
                      setState(() {
                        phoneNumber = value;
                        if (value.replaceAll(RegExp(r'\D'), '').length >= 1) {
                          selectedNetwork = getNetworkFromPhone(value);
                        }
                      });
                    },
                    decoration: InputDecoration(
                      prefixText: '+250 ',
                      hintText: '788123456 (9 digits)',
                      helperText: 'Enter 9 digits (without 0 at start)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.purple.shade600),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      counterText: '',
                    ),
                  ),

                  if (phoneNumber.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedNetwork == 'AIRTEL'
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedNetwork == 'AIRTEL'
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedNetwork == 'AIRTEL'
                                ? Icons.mobile_screen_share
                                : Icons.phone_android,
                            color: selectedNetwork == 'AIRTEL'
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Network: $selectedNetwork',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selectedNetwork == 'AIRTEL'
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24),

                  // Info box
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will receive a payment prompt on your phone after confirming.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isPaymentProcessing
                      ? null
                      : () {
                          setState(() => currentScreen = 'selectPlan');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPaymentProcessing ? null : _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 27, 204, 119),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isPaymentProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _validateAndProceed() {
    if (phoneNumber.isEmpty) {
      AppSnackbar.error(context, 'Please enter your phone number');
      return;
    }

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('7') || cleanPhone.length != 9) {
      AppSnackbar.error(context, 'Phone number must be 9 digits starting with 7');
      return;
    }

    // Proceed to confirmation
    setState(() => currentScreen = 'confirmation');
  }

  // ========== SCREEN 4: CONFIRMATION ==========
  Widget _buildConfirmationScreen() {
    if (selectedPlanForPayment == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => setState(() => currentScreen = 'selectPlan'),
          child: Text('Go Back'),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => currentScreen = 'paymentDetails');
                },
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Your PIN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Waiting for payment prompt',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 24),

                  // Phone Icon
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_in_talk,
                      size: 64,
                      color: Colors.indigo.shade600,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        _PaymentSummaryRow('Plan', selectedPlanForPayment['name'] ?? 'Plan'),
                        _PaymentSummaryRow('Amount', '${selectedPlanForPayment['price'] ?? 0} RWF'),
                        _PaymentSummaryRow('Network', selectedNetwork),
                        _PaymentSummaryRow('Phone', phoneNumber),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Step Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.amber.shade700, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Follow these steps:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _InstructionStep('1', 'You will receive an SMS on your phone'),
                        _InstructionStep('2', 'Press 1 (or follow the prompt)'),
                        _InstructionStep('3', 'Enter your PIN when asked'),
                        _InstructionStep('4', 'Wait for confirmation'),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Processing indicator
                  Column(
                    children: [
                      CircularProgressIndicator(color: Colors.indigo.shade600),
                      SizedBox(height: 16),
                      Text(
                        'Processing your payment...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        // Action Button
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPaymentProcessing ? null : _startPaymentWithPolling,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isPaymentProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Start Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _InstructionStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SCREEN 5: PAYMENT RESULT ==========
  Widget _buildResultScreen() {
    final isSuccess = paymentResultStatus == 'SUCCESSFUL';
    final isTimeout = paymentResultStatus == 'TIMEOUT';
    final statusTitle = isSuccess 
        ? 'Payment Successful!' 
        : isTimeout 
            ? 'Payment Timeout'
            : 'Payment Failed';
    final statusSubtitle = isSuccess
        ? 'Your plan has been activated'
        : isTimeout
            ? 'Please dial *182*7*2# to complete the payment'
            : 'Please try again';

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green : (isTimeout ? Colors.orange.shade700 : Colors.red.shade600),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Go back to history without starting exam
                  setState(() {
                    currentScreen = 'history';
                    phoneNumber = '';
                    phoneController.clear();
                    selectedPlanForPayment = null;
                    currentPaymentReference = null;
                    paymentResultStatus = '';
                    paymentResultMessage = '';
                  });
                  _loadPaymentHistory();
                },
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 32),

                  // Result Icon
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isSuccess 
                          ? Colors.green.shade50 
                          : isTimeout 
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess 
                          ? Icons.check 
                          : isTimeout 
                              ? Icons.schedule
                              : Icons.close,
                      size: 80,
                      color: isSuccess 
                          ? Colors.green.shade600 
                          : isTimeout 
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                    ),
                  ),

                  SizedBox(height: 32),

                  // Message
                  Text(
                    paymentResultMessage.isNotEmpty
                        ? paymentResultMessage
                        : (isSuccess
                            ? 'Your payment has been processed successfully!'
                            : isTimeout
                                ? 'The 2-minute window to dial *182*7*2# has expired. You can dial the code again by tapping Try Again.'
                                : 'Your payment could not be processed.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  if (isTimeout) ...[
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Dial this code to complete your payment:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '*182*7*2#',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade900,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Press CALL',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (currentPaymentReference != null) ...[
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          SelectableText(
                            currentPaymentReference!,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isSuccess) {
                  // Navigate to ExamScreen after successful payment
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ExamScreen()),
                  );
                } else {
                  // Try again - go back to payment history
                  setState(() {
                    currentScreen = 'history';
                    phoneNumber = '';
                    phoneController.clear();
                    selectedPlanForPayment = null;
                    currentPaymentReference = null;
                    paymentResultStatus = '';
                    paymentResultMessage = '';
                  });
                  _loadPaymentHistory();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess 
                    ? Colors.green.shade600 
                    : isTimeout
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isSuccess ? 'Go to Start Exam' : 'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startPaymentWithPolling() async {
    if (selectedPlanForPayment == null || userId == null) {
      AppSnackbar.error(context, 'Invalid payment data');
      return;
    }

    setState(() => isPaymentProcessing = true);

    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final phoneWithZero = '0' + cleanPhone; // Add 0 prefix to make 10 digits
      final detectedNetwork = getNetworkFromPhone(cleanPhone);

      print('💰 Starting payment process...');

      // Call payment API
      final response = await ApiService.initiatePayment(
        amount: (selectedPlanForPayment['price'] ?? 0).toString(),
        phone: phoneWithZero,
        network: detectedNetwork,
        planId: selectedPlanForPayment['_id'],
        userId: userId!,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final reference = response['reference'] ?? response['req_ref'];
        currentPaymentReference = reference;

        print('✅ Payment initiated: $reference');

        // Poll for payment confirmation
        final pollResult = await pollPaymentStatus(reference);

        if (!mounted) return;

        if (pollResult['success'] == true && pollResult['status'] == 'SUCCESSFUL') {
          // Try to activate plan
          try {
            await ApiService.activatePlan(planId: selectedPlanForPayment['_id']);
          } catch (e) {
            print('⚠️ Plan activation error: $e');
          }

          setState(() {
            paymentResultStatus = 'SUCCESSFUL';
            paymentResultMessage = 'Your payment was successful!\nYour plan is now active.';
            currentScreen = 'result';
          });
        } else {
          setState(() {
            paymentResultStatus = 'FAILED';
            paymentResultMessage =
                'Payment could not be verified.\nPlease check your payment status or try again.';
            currentScreen = 'result';
          });
        }
      } else {
        final errorMessage = response['message'] ?? '';
        final displayMessage = errorMessage.isNotEmpty
            ? errorMessage
            : 'Dear client payment failed due to unknown error or you don\'t have enough amount to complete this transaction please try again later or contact 0780100211';
        setState(() {
          paymentResultStatus = 'FAILED';
          paymentResultMessage = displayMessage;
          currentScreen = 'result';
        });
      }
    } catch (e) {
      print('❌ Payment error: $e');
      final errorMessage = e.toString();
      final displayMessage = errorMessage.contains('400') || errorMessage.isNotEmpty
          ? 'Dear client payment failed due to unknown error or you don\'t have enough amount to complete this transaction please try again later or contact 0780100211'
          : 'Error: $errorMessage';
      setState(() {
        paymentResultStatus = 'FAILED';
        paymentResultMessage = displayMessage;
        currentScreen = 'result';
      });
    } finally {
      if (mounted) {
        setState(() => isPaymentProcessing = false);
      }
    }
  }

  Future<void> _activateFreePlanDirect(dynamic plan) async {
    if (userId == null || userId!.isEmpty) {
      AppSnackbar.error(context, 'User not logged in');
      return;
    }

    setState(() => isPaymentProcessing = true);

    try {
      print('🎁 Activating free plan...');
      final response = await ApiService.activatePlan(planId: plan['_id']);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          paymentResultStatus = 'SUCCESSFUL';
          paymentResultMessage = 'Free plan activated successfully!\nYou can now start using it.';
          currentScreen = 'result';
        });
      } else {
        AppSnackbar.error(
          context,
          response['message'] ?? 'Failed to activate free plan',
        );
        setState(() => currentScreen = 'selectPlan');
      }
    } catch (e) {
      print('❌ Error activating free plan: $e');
      AppSnackbar.error(context, 'Error: ${e.toString()}');
      setState(() => currentScreen = 'selectPlan');
    } finally {
      if (mounted) {
        setState(() => isPaymentProcessing = false);
      }
    }
  }

  Widget _PaymentSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  void _showPINConfirmationDialog({
    required String phoneNumber,
    required String network,
    required int amount,
    required String planName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, color: Colors.blue, size: 48),
              SizedBox(height: 16),
              Text(
                'Enter Your PIN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'You will receive a prompt on your phone',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfirmationRow('Network', network),
                    _ConfirmationRow('Phone', phoneNumber),
                    _ConfirmationRow('Amount', '$amount RWF'),
                    _ConfirmationRow('Plan', planName),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Follow the prompt on your phone and enter your PIN to confirm the payment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Waiting for confirmation...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog({
    required String planName,
    required int amount,
    required String reference,
    required String network,
    required String phone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Payment Successful! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Your plan has been activated',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfirmationRow('Plan', planName),
                    _ConfirmationRow('Amount', '$amount RWF'),
                    _ConfirmationRow('Network', network),
                    _ConfirmationRow('Reference', reference),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseForm() {
    if (selectedPlanForPayment == null) return SizedBox();
    
    final selectedPlan = pricingPlans.firstWhere(
      (p) => p['_id'] == selectedPlanForPayment['_id'],
      orElse: () => null,
    );

    if (selectedPlan == null) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Your Purchase',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 16),

          // Plan Summary
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPlan?['name'] ?? 'Plan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (((selectedPlan?['examAttempts'] as int?) ?? 0) >= 999999)
                      Text(
                        '∞ Unlimited Attempts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        '${selectedPlan?['examAttempts'] ?? 0} exam attempts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (((selectedPlan?['duration'] as String?) ?? 'one-time') != 'one-time')
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          (selectedPlan?['duration'] as String?) == 'weekly'
                              ? 'Valid for 7 days'
                              : (selectedPlan?['duration'] as String?) == 'monthly'
                              ? 'Valid for 30 days'
                              : 'Valid for 365 days',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${selectedPlan?['price'] ?? 0} RWF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Phone Number Input with Auto-Detected Network
          Text(
            'Phone Number',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          SizedBox(height: 8),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            enabled: !isPaymentProcessing,
            maxLength: 10,
            onChanged: (value) {
              setState(() {
                phoneNumber = value;
                // Auto-detect network when phone changes
                if (value.replaceAll(RegExp(r'\D'), '').length >= 3) {
                  selectedNetwork = getNetworkFromPhone(value);
                }
              });
            },
            decoration: InputDecoration(
              prefixText: '+250 ',
              hintText: '788123456 (9 digits)',
              helperText: 'Enter 9 digits (without 0 at start)\nNetwork: ${phoneNumber.isEmpty ? 'Enter phone' : selectedNetwork}',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              counterText: '', // Hide the character counter
            ),
          ),

          SizedBox(height: 8),

          // Show detected network info
          if (phoneNumber.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selectedNetwork == 'AIRTEL'
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selectedNetwork == 'AIRTEL'
                      ? Colors.red.shade300
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedNetwork == 'AIRTEL' ? Icons.mobile_screen_share : Icons.phone_android,
                    color: selectedNetwork == 'AIRTEL' ? Colors.red.shade600 : Colors.green.shade600,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Network: $selectedNetwork',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedNetwork == 'AIRTEL'
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 20),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPaymentProcessing
                  ? null
                  : () => _initiatePayment(selectedPlanForPayment!['_id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isPaymentProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Pay ${selectedPlan?['price'] ?? 0} RWF',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isPaymentProcessing
                  ? null
                  : () => setState(() => selectedPlanForPayment = null),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),

          SizedBox(height: 12),

          // Info Text
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.amber.shade800),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete the USSD prompt on your $selectedNetwork phone to confirm payment',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final VoidCallback onSelect;
  final bool isLoading;
  final bool isSelected;

  const _PlanCard({
    required this.plan,
    required this.onSelect,
    required this.isLoading,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan['popular'] ?? false;
    final color = isPopular ? Colors.green : Colors.blue;

    return GestureDetector(
      onTap: isLoading ? null : onSelect,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade600
                : isPopular
                ? color
                : Colors.grey.shade200,
            width: isSelected || isPopular ? 2 : 1,
          ),
          boxShadow: [
            if (isPopular || isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                offset: Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Popular Badge
            if (isPopular)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    "MOST POPULAR",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Selected Badge
            if (isSelected)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular) SizedBox(height: 12),

                  // Plan Name
                  Text(
                    plan['name'] ?? 'Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan['price']} ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'RWF',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),
                  if (plan != null)
                    ...[
                      if (((plan['examAttempts'] as int?) ?? 0) >= 999999)
                        Text(
                          '∞ Unlimited Exam Attempts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          '${plan['examAttempts'] ?? 0} exam attempts',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      
                      // Show duration for period plans
                      if (((plan['duration'] as String?) ?? 'one-time') != 'one-time')
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            (plan['duration'] as String?) == 'weekly'
                                ? 'Valid for 7 days'
                                : (plan['duration'] as String?) == 'monthly'
                                ? 'Valid for 30 days'
                                : 'Valid for 365 days',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],

                  SizedBox(height: 16),

                  // Divider
                  Divider(height: 1, color: Colors.grey.shade200),
                  SizedBox(height: 16),

                  // Features
                  ..._buildFeatures(plan),

                  SizedBox(height: 16),

                  // Select Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.green.shade600
                            : isPopular
                            ? color
                            : Colors.grey.shade200,
                        foregroundColor: isSelected || isPopular
                            ? Colors.white
                            : color,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        isSelected ? 'Selected ✓' : 'Select Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatures(dynamic plan) {
    if (plan == null) return [];
    
    final features = plan['features'] as List? ?? [];
    return features
        .map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _FeatureItem(text: feature?.toString() ?? 'Feature'),
          ),
        )
        .toList();
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
