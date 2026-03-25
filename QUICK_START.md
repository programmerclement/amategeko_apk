# ⚡ QUICK START GUIDE - REAL BACKEND INTEGRATION

## 🔥 MOST IMPORTANT: Update Your Server URL

**File**: `lib/services/api_service.dart` (Line 8)

### BEFORE:
```dart
static const String baseUrl = "http://YOUR_SERVER_IP:5000/api";
```

### AFTER (Example):
```dart
// For local development:
static const String baseUrl = "http://192.168.1.100:5000/api";

// For production:
static const String baseUrl = "http://your-domain.com/api";
```

**That's it!** The rest is automatic. 🎉

---

## ✅ ALL REAL ENDPOINTS INTEGRATED

| Feature | Endpoint | Status |
|---------|----------|--------|
| User Profile | `GET /users/profile` | ✅ Real |
| Exam History | `GET /exam/history` | ✅ Real |
| Payments | `GET /payments/user/:userId` | ✅ Real |
| Exam Eligibility | `GET /exam/check-eligibility` | ✅ Real |
| Pricing Plans | `GET /pricing/plans` | ✅ Real (with fallback) |
| Start Payment | `POST /payments/initiate` | ✅ Real |

---

## 📋 WHAT CHANGED

### ApiService (`lib/services/api_service.dart`)
- ✅ Updated base URL (configurable)
- ✅ All endpoints match backend URLs
- ✅ Token is automatically added to every request
- ✅ Proper error handling for 401, 400+ status codes
- ✅ No dummy data in API calls

### Dashboard Tab (`lib/screens/dashboard_tab.dart`)
- ✅ Fetches user profile from `/users/profile`
- ✅ Extracts all real data (username, email, stats)
- ✅ Calculates stats from real exam data
- ✅ Shows real exam history (last 3)
- ✅ Shows real payment history (last 3)
- ✅ Proper error states with refresh button
- ✅ Real data only - no dummy data

### Exams Tab (`lib/screens/exams_tab.dart`)
- ✅ Calls real endpoint before starting exam
- ✅ Handles eligibility response correctly
- ✅ Shows error message if not eligible
- ✅ Displays remaining exams count if available

### Payments Tab (`lib/screens/payments_tab.dart`)
- ✅ Fetches pricing plans from API
- ✅ Falls back to dummy data if API fails
- ✅ Initiates real payment with API
- ✅ Shows proper error/success messages

### Home Screen (`lib/screens/home_screen.dart`)
- ✅ Fetches user profile once on app load
- ✅ Passes user info to drawer
- ✅ User name and email displayed in sidebar

---

## 🎯 DATA FLOW

### Dashboard Load Flow:
```
1. User opens app → HomeScreen loads
2. HomeScreen fetches /users/profile
3. DashboardTab fetches /exam/history
4. DashboardTab fetches /payments/user/:userId
5. All data displayed in UI
6. User can pull-to-refresh for latest data
```

### Exam Start Flow:
```
1. User clicks "Start Exam"
2. ExamsTab calls GET /exam/check-eligibility
3. If eligible → Success message + prepare for exam
4. If not → Error message + show remaining exams
```

### Payment Flow:
```
1. User selects plan
2. PaymentsTab calls POST /payments/initiate
3. If success → Redirect to payment gateway (to implement)
4. If fail → Error message shown
```

---

## 🧪 TESTING CHECKLIST

- [ ] Update `baseUrl` in `api_service.dart`
- [ ] Run app and login
- [ ] Dashboard loads stats (not 0, no errors)
- [ ] Recent exams show up
- [ ] Recent payments show up
- [ ] Pull-to-refresh works
- [ ] Click "Start Exam" - see eligibility message
- [ ] Payments tab loads plans
- [ ] All API calls show in network logs

---

## 📡 EXPECTED API RESPONSES

### Success Response Format:
```json
{
  "success": true,
  "data": {...}  // or specific fields like "exams", "payments"
}
```

### Error Response Format:
```json
{
  "success": false,
  "message": "Error description"
}
```

### Status Codes:
- `200` - Success
- `400` - Bad request
- `401` - Unauthorized (token expired)
- `500` - Server error

---

## 🔐 AUTHENTICATION

All requests automatically include:
```
Authorization: Bearer {token}
```

Token is fetched from SharedPreferences (saved during login).

---

## 🎨 UI HIGHLIGHTS

✨ Modern Material Design 3  
✨ Responsive layout  
✨ Real data with proper formatting  
✨ Error states with refresh options  
✨ Loading spinners  
✨ Color-coded status (Green=Pass, Red=Fail)  
✨ Professional card layouts  
✨ Smooth animations  

---

## 🚀 NEXT STEPS

1. **Test with your backend** - Make sure all endpoints return correct format
2. **Handle edge cases** - Test with no exams, no payments, etc.
3. **Implement exam screen** - Create screen to take actual exams
4. **Implement payment gateway** - Integrate payment provider
5. **Add analytics** - Track user behavior
6. **Deploy to production** - Use correct server URL

---

## ❓ COMMON ISSUES & FIXES

### Issue: Dashboard shows all zeros
**Fix**: Check if backend is returning data. Test endpoint with Postman.

### Issue: "No authentication token"
**Fix**: User must be logged in first. Make sure login saves token.

### Issue: "Unauthorized" errors
**Fix**: Token might be expired. User needs to login again.

### Issue: Network errors
**Fix**: Check server URL is correct and server is running.

---

## 💡 PRO TIPS

1. Use **Postman** to test API endpoints before debugging app
2. Check **Flutter console** for API response logs (printed automatically)
3. Use **Android Studio Profiler** to check network requests
4. Test on **real device**, not just emulator
5. Always use **HTTPS** in production (not HTTP)

---

**Questions?** Check the full `API_INTEGRATION_GUIDE.md` file for detailed documentation.

Happy coding! 🎉
