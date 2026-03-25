import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  bool isLoading = false;
  bool isPaymentProcessing = false;
  String? selectedPlanId;
  String selectedNetwork = 'MTN';
  String phoneNumber = '';
  List<dynamic> pricingPlans = [];
  String? userId;

  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPricingPlans();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('userId');
      });
      print('User ID loaded: $userId');
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadPricingPlans() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.fetchPricingPlans();

      if (mounted) {
        setState(() {
          // Backend returns array of plans directly
          if (response is List) {
            pricingPlans = response as List<dynamic>;
          } else if (response.containsKey('data') && response['data'] is List) {
            pricingPlans = response['data'] as List<dynamic>;
          } else if (response.containsKey('plans') &&
              response['plans'] is List) {
            pricingPlans = response['plans'] as List<dynamic>;
          } else {
            pricingPlans = _getDefaultPlans();
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading plans: $e');
      if (mounted) {
        setState(() {
          pricingPlans = _getDefaultPlans();
          isLoading = false;
        });
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
        'popular': true,
      },
      {
        '_id': '3',
        'name': 'Premium',
        'price': 10000,
        'currency': 'RWF',
        'duration': 'one-time',
        'examAttempts': 50,
        'features': [
          'Unlimited Exams',
          'Expert Coaching',
          'All Features',
          '24/7 Support',
          'Certificate',
        ],
        'isActive': true,
      },
    ];
  }

  Future<void> _initiatePayment(String planId) async {
    // Validate inputs
    if (phoneNumber.isEmpty) {
      AppSnackbar.error(context, 'Please enter your phone number');
      return;
    }

    if (userId == null || userId!.isEmpty) {
      AppSnackbar.error(context, 'User information not found');
      return;
    }

    // Find plan
    final plan = pricingPlans.firstWhere(
      (p) => p['_id'] == planId,
      orElse: () => null,
    );

    if (plan == null) {
      AppSnackbar.error(context, 'Plan not found');
      return;
    }

    setState(() => isPaymentProcessing = true);

    try {
      print('💰 Initiating payment:');
      print('Plan: ${plan['name']}');
      print('Amount: ${plan['price']} RWF');
      print('Phone: $phoneNumber');
      print('Network: $selectedNetwork');

      // Call payment API
      final response = await ApiService.initiatePayment(
        amount: plan['price'].toString(),
        phone: phoneNumber,
        network: selectedNetwork,
        planId: planId,
        userId: userId!,
      );

      if (!mounted) return;

      print('Payment Response: $response');

      if (response['success'] == true) {
        // Payment initiated successfully
        final reference = response['reference'] ?? response['req_ref'];

        AppSnackbar.success(
          context,
          'Payment initiated!\nCheck your ${selectedNetwork} phone for prompt.',
        );

        // Show payment confirmation dialog
        _showPaymentConfirmation(
          planName: plan['name'],
          amount: plan['price'],
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
                    _ConfirmationRow('Amount', '$amount RWF'),
                    _ConfirmationRow('Network', network),
                    _ConfirmationRow('Phone', phone),
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
    if (isLoading && pricingPlans.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Colors.green.shade600),
      );
    }

    return SingleChildScrollView(
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
    );
  }

  void _scrollToPurchaseForm() {
    Future.delayed(Duration(milliseconds: 300), () {
      // Scroll could be added here if wrapped in ScrollController
    });
  }

  Widget _buildPurchaseForm() {
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
                      selectedPlan['name'],
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${selectedPlan['examAttempts']} exam attempts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${selectedPlan['price']} RWF',
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
            onChanged: (value) => setState(() => phoneNumber = value),
            decoration: InputDecoration(
              prefixText: '+250 ',
              hintText: '7xx xxx xxx',
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
                      'Pay ${selectedPlan['price']} RWF',
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
                  Text(
                    '${plan['examAttempts'] ?? 0} exam attempts',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),

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
    final features = plan['features'] as List? ?? [];
    return features
        .map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _FeatureItem(text: feature),
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
