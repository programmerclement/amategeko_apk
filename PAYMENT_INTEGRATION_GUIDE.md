# Payment Integration & Pricing Plans - Complete Guide

## ✅ What's Been Implemented

### 1. **Six Pricing Plans** (3 One-Time + 3 Period-Based)

#### One-Time Plans:
1. **Starter** - 2,000 RWF → 5 exam attempts
2. **Professional** - 5,000 RWF → 15 exam attempts
3. **Premium** - 10,000 RWF → 50 exam attempts

#### Period-Based Plans (with Unlimited Attempts):
4. **Weekly Pass** - 3,000 RWF → ∞ Unlimited for 7 days ⭐ POPULAR
5. **Monthly Pass** - 10,000 RWF → ∞ Unlimited for 30 days ⭐⭐ MOST POPULAR
6. **Yearly Pass** - 100,000 RWF → ∞ Unlimited for 365 days

### 2. **Period Plans Marked as Popular**
- **Monthly Pass** is marked as `popular: true` (shows badge + green highlight)
- Weekly and Yearly show relevant information but are not marked popular
- All period plans show `∞ Unlimited Attempts` in green

### 3. **Payment Integration API Routes**

Your payment endpoint handles:

```
POST /api/payments/initiate
├─ Initiates payment transaction
├─ Creates payment record in DB
├─ Returns reference number
└─ Triggers payment provider (ITECPAY)

GET /api/payments/status/:reference
├─ Checks payment status
└─ Returns: success/pending/failed

POST /api/payments/confirm/:reference
├─ Manual payment confirmation
└─ Activates user's subscription

GET /api/payments/manual-check/:req_ref
├─ Alternative payment check
└─ For backup verification
```

### 4. **Payment Flow in App**

```
User opens Payments Tab
         ↓
Load pricing plans (real from DB or defaults)
         ↓
User selects a plan (card highlights green + shows "Selected ✓")
         ↓
Purchase form appears
├─ Shows plan summary (name, attempts/unlimited, price, validity)
├─ Network selection (MTN, AIRTEL, SPENN)
├─ Phone number input
└─ Pay button
         ↓
User clicks "Pay X,XXX RWF"
         ↓
Call: POST /api/payments/initiate
├─ amount: plan['price']
├─ phone: user input
├─ network: MTN/AIRTEL/SPENN
├─ planId: plan['_id']
└─ userId: authenticated user
         ↓
Backend returns: { success: true, reference: "ABC123", ... }
         ↓
Show confirmation dialog with:
├─ Plan name
├─ Duration/Validity info
├─ Amount
├─ Network
├─ Phone number
├─ Transaction reference
└─ "Done" button
         ↓
User completes USSD payment on phone
         ↓
Webhook hits: POST /api/webhook
├─ Verifies payment
├─ Updates payment status
└─ Activates plan for user
         ↓
User can now use unlimited exams (for period plans)
or X attempts (for one-time plans)
```

---

## 📱 UI/UX Features

### Plan Cards Display:
- ✅ Plan name (18px, bold)
- ✅ Price in large text (28px, colored)
- ✅ Exam attempts or "∞ Unlimited"
- ✅ Validity period (for time-based plans)
- ✅ Features list (checkmarks)
- ✅ "MOST POPULAR" badge (Monthly Pass)
- ✅ "Selected ✓" badge when clicked
- ✅ Shadow effect on popular plans

### Purchase Form:
- ✅ Shows complete plan summary
- ✅ Network selection (MTN/AIRTEL/SPENN)
- ✅ Phone input with prefix "+250"
- ✅ Pay button shows amount
- ✅ Loading spinner during payment
- ✅ Blue info box with payment instructions

### Confirmation Dialog:
- ✅ Green checkmark icon
- ✅ Plan name
- ✅ Duration (e.g., "Valid for 30 days")
- ✅ Attempts (e.g., "∞ Unlimited (999999) exam attempts")
- ✅ Amount and network
- ✅ Phone number
- ✅ Transaction reference
- ✅ "Done" button

### Pull-to-Refresh:
- ✅ Works on all three main tabs
- ✅ Swipe down from top to reload
- ✅ Green loading spinner
- ✅ Auto-dismisses when complete

---

## 🔗 API Methods in ApiService

```dart
// Payment Initiation
Future<Map<String, dynamic>> initiatePayment({
  required String amount,
  required String phone,
  required String network,
  required String planId,
  required String userId,
})

// Check Payment Status
Future<Map<String, dynamic>> checkPaymentStatus(String reference)

// Manual Payment Check
Future<Map<String, dynamic>> manualPaymentCheck(String reqRef)

// Confirm Payment
Future<Map<String, dynamic>> confirmPayment(String reference)

// Get Public Pricing Plans
Future<dynamic> fetchPublicPricingPlans()

// Activate Plan (Optional)
Future<Map<String, dynamic>> activatePlan({required String planId})
```

---

## 📊 Plan Comparison Table

| Feature | Starter | Pro | Premium | Weekly | Monthly | Yearly |
|---------|---------|-----|---------|--------|---------|--------|
| Price | 2K RWF | 5K RWF | 10K RWF | 3K RWF | 10K RWF | 100K RWF |
| Attempts | 5 | 15 | 50 | ∞ | ∞ | ∞ |
| Duration | One-time | One-time | One-time | 7 days | 30 days | 365 days |
| Popular | ❌ | ❌ | ❌ | ❌ | ✅ YES | ❌ |
| Support | Basic | Priority | 24/7 | Priority | 24/7 | 24/7 |
| Analytics | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 🧪 Testing the Payment Flow

### Step 1: Load Pricing Plans
```
✅ Open Payments tab
✅ See 6 plans load (or defaults if API fails)
✅ Monthly Pass has green background + "MOST POPULAR" badge
✅ Period plans show "∞ Unlimited Attempts" in green
```

### Step 2: Select a Plan
```
✅ Click any plan card
✅ Card highlights green
✅ "Selected ✓" badge appears
✅ Purchase form appears below with plan details
```

### Step 3: Process Payment
```
✅ Select network (MTN/AIRTEL/SPENN)
✅ Enter phone number (without +250, just 7xx xxx xxx)
✅ Click "Pay X,XXX RWF"
✅ Shows loading spinner
✅ Success dialog appears with transaction reference
```

### Step 4: Verify in Backend
```
Database checks:
- Payment record created in payments collection
- Status initially: 'PENDING'
- Reference number matches

Webhook receives:
- Confirmation from payment provider
- Updates payment status to 'SUCCESS'
- Updates user's active plan
- Sets plan expiration (for time-based plans)
```

---

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Plans showing defaults | Check if API returns correct format |
| Monthly Pass not highlighted | Verify `popular: true` in plan data |
| "∞ Unlimited" not showing | Check if `examAttempts >= 999999` |
| Payment fails | Check phone number format (should be 7xx xxx xxx) |
| Status not updating | Verify webhook endpoint is receiving data |
| Wrong duration shown | Ensure `duration` field is: one-time/weekly/monthly/yearly |

---

## 📝 Next Steps

1. **Test with real backend** - Ensure pricing plans load from MongoDB
2. **Verify payment flow** - Test payment initiation with ITECPAY
3. **Check webhook integration** - Confirm payment confirmation updates user plan
4. **Monitor payment stats** - Use `/api/payments/admin/stats` endpoint
5. **Handle expired plans** - Implement plan expiration check on next login

---

## 💡 Important Notes

- **Monthly Pass is the recommended plan** - It's marked popular and has best value
- **Unlimited plans use 999999** - Treated as unlimited in logic
- **Period plans auto-expire** - Backend handles expiration via cron jobs
- **Phone format**: +250 prefix is added by app, user enters without it
- **Payment is asynchronous** - User sees UI update after USSD completion

