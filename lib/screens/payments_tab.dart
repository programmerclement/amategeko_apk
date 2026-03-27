import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  bool isLoading = false;
  bool isPaymentProcessing = false;
  bool isInitializing = true; // New: track if we're still loading userId
  String? selectedPlanId;
  String selectedNetwork = 'MTN';
  String phoneNumber = '';
  List<dynamic> pricingPlans = [];
  String? userId;

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
    // Reload user data when tab becomes active
    _loadUserData();
  }

  Future<void> _initializeTab() async {
    print('🔄 [PaymentsTab] Initializing tab...');
    if (mounted) {
      setState(() => isInitializing = true);
    }
    
    // Load user data first
    await _loadUserData();
    // Then load pricing plans
    await _loadPricingPlans();
    
    if (mounted) {
      setState(() => isInitializing = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
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

    // Validate phone format (should be 10 digits like 0788123456)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('07') || cleanPhone.length != 10) {
      AppSnackbar.error(
        context, 
        'Phone number must be 10 digits starting with 07\nExample: 0788123456',
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

    setState(() => isPaymentProcessing = true);

    try {
      print('💰 Initiating payment:');
      print('User ID: $userId');
      print('Plan: ${plan?['name'] ?? 'Unknown'}');
      print('Amount: ${plan?['price'] ?? 0} RWF');
      print('Phone: $cleanPhone');
      print('Network: $selectedNetwork');

      // Call payment API
      final response = await ApiService.initiatePayment(
        amount: (plan?['price'] ?? 0).toString(),
        phone: cleanPhone,
        network: selectedNetwork,
        planId: planId,
        userId: userId!,
      );

      if (!mounted) return;

      print('✅ Payment Response: $response');

      if (response['success'] == true) {
        // Payment initiated successfully
        final reference = response['reference'] ?? response['req_ref'];

        // Activate the plan for the user
        try {
          final activateResponse = await ApiService.activatePlan(planId: planId);
          print('Plan activation response: $activateResponse');

          if (activateResponse['success'] == true) {
            AppSnackbar.success(
              context,
              '✅ Plan activated successfully! Check your ${selectedNetwork} phone for payment prompt.',
            );
          } else {
            AppSnackbar.success(
              context,
              'Payment initiated!\nCheck your ${selectedNetwork} phone for prompt.',
            );
          }
        } catch (e) {
          print('Plan activation error: $e');
          // Still show success even if activation fails, payment was initiated
          AppSnackbar.success(
            context,
            'Payment initiated!\nCheck your ${selectedNetwork} phone for prompt.',
          );
        }

        // Show payment confirmation dialog
        _showPaymentConfirmation(
          planName: plan?['name'] ?? 'Plan',
          amount: plan?['price'] ?? 0,
          reference: reference,
          network: selectedNetwork,
          phone: phoneNumber,
        );

        // Clear form
        phoneController.clear();
        setState(() {
          phoneNumber = '';
          selectedPlanId = null;
        });
      } else {
        AppSnackbar.error(
          context,
          response['message'] ?? 'Payment initiation failed',
        );
      }
    } catch (e) {
      print('Payment error: $e');
      AppSnackbar.error(context, 'Error: ${e.toString()}');
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
    if (selectedPlanId == null) {
      print('⚠️ selectedPlanId is null in confirmation');
      return;
    }
    
    final selectedPlan = pricingPlans.firstWhere(
      (p) => p['_id'] == selectedPlanId,
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

  @override
  Widget build(BuildContext context) {
    print('🎨 [PaymentsTab] build() called - userId: $userId, isInitializing: $isInitializing');
    
    // Show loading indicator while initializing
    if (isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            SizedBox(height: 16),
            Text('Loading payment options...'),
          ],
        ),
      );
    }
    
    // Check if user is logged in
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
                // Navigate to login or show login dialog
                Navigator.pop(context); // Go back or navigate to login
                AppSnackbar.info(context, 'Please log in from your profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Go to Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: _loadUserData,
              child: Text(
                'Try Loading Again',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading && pricingPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            SizedBox(height: 16),
            Text('Loading pricing plans...'),
          ],
        ),
      );
    }

    if (pricingPlans.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text('No pricing plans available'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPricingPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPricingPlans,
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
                "Choose Your Plan 💳",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Upgrade to unlock unlimited exams",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: 24),

              // Plans Grid
              ...pricingPlans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  isSelected: selectedPlanId == plan['_id'],
                  onSelect: () {
                    setState(() => selectedPlanId = plan['_id']);
                    _scrollToPurchaseForm();
                  },
                  isLoading: isPaymentProcessing,
                ),
              ),

              SizedBox(height: 32),

              // Purchase Form (if plan selected)
              if (selectedPlanId != null) _buildPurchaseForm(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToPurchaseForm() {
    Future.delayed(Duration(milliseconds: 300), () {
      // Scroll could be added here if wrapped in ScrollController
    });
  }

  Widget _buildPurchaseForm() {
    if (selectedPlanId == null) return SizedBox();
    
    final selectedPlan = pricingPlans.firstWhere(
      (p) => p['_id'] == selectedPlanId,
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

          // Network Selection
          Text(
            'Payment Network',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          SizedBox(height: 8),
          Row(
            children: ['MTN', 'AIRTEL', 'SPENN'].map((network) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedNetwork = network),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selectedNetwork == network
                          ? Colors.blue.shade600
                          : Colors.white,
                      border: Border.all(
                        color: selectedNetwork == network
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      network,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selectedNetwork == network
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 16),

          // Phone Number Input
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
            onChanged: (value) => setState(() => phoneNumber = value),
            decoration: InputDecoration(
              prefixText: '+250 ',
              hintText: '788123456 (9 digits)',
              helperText: 'Enter 9 digits (without 0 at start)',
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

          SizedBox(height: 20),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPaymentProcessing
                  ? null
                  : () => _initiatePayment(selectedPlanId!),
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
                  : () => setState(() => selectedPlanId = null),
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
