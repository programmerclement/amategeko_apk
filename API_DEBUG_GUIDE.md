# API Debugging Guide

## Changes Made

### 1. **Payments Tab** - Pull-to-Refresh + Better Debugging
- ✅ Added `RefreshIndicator` for pull-to-refresh functionality
- ✅ Enhanced logging with emojis for easier debugging
- ✅ Better error handling and display
- ✅ Fixed response parsing to handle multiple formats
- ✅ Added "Try Again" button when no plans are available

### 2. **Dashboard Tab** - Already has pull-to-refresh
- ✅ Confirmed RefreshIndicator is working

### 3. **Exams Tab** - Pull-to-Refresh Added
- ✅ Added `RefreshIndicator` and `AlwaysScrollableScrollPhysics()`
- ✅ Now refreshes when pulling down from top

### 4. **API Service** - Enhanced Debugging
- ✅ Added detailed logging to `fetchPublicPricingPlans()`
- ✅ Shows:
  - 📡 API endpoint being called
  - ✅ Status code
  - 📝 Raw response body
  - 📊 Response type before/after parsing
  - ✨ Final decoded data

## Pricing Plans Flow

```
User scrolls to Payments Tab
    ↓
Tab loads → Calls fetchPublicPricingPlans()
    ↓
API_SERVICE hits: https://amategeko-backend-new.onrender.com/api/pricing/plans
    ↓
Backend route handler:
  - Queries PricingPlan.find({ isActive: true })
  - Sorts by price
  - Returns array directly
    ↓
Expected Response: Array of plan objects
[
  { _id, name, price, currency, duration, examAttempts, features, isActive },
  { ... }
]
    ↓
Flutter parses and displays plans
```

## How to Debug Issues

### Check #1: View Console Logs
Run your Flutter app and watch the terminal for:

```
📡 Fetching pricing plans from: https://amategeko-backend-new.onrender.com/api/pricing/plans
✅ API GET /pricing/plans - Status: 200
📝 Raw Response: [{"_id":"...", ...}]
📊 Response Type: List<dynamic>
✨ Decoded Response: [...]
✨ Response Type after decode: List<dynamic>
✨ Final plans: 3 plans loaded
```

### Check #2: Verify Backend Database
Ensure your `PricingPlan` collection has documents:

```javascript
// Test with MongoDB shell or Robo3T
db.pricingplans.find({ isActive: true })

// Should return:
{
  _id: ObjectId("..."),
  name: "Starter",
  price: 2000,
  currency: "RWF",
  duration: "one-time",
  examAttempts: 5,
  features: ["...", "..."],
  isActive: true
}
```

### Check #3: Test API Directly
Use Postman or curl to test the endpoint:

```bash
# No authentication required
curl -X GET "https://amategeko-backend-new.onrender.com/api/pricing/plans"

# Expected response:
[
  { _id: "...", name: "Starter", price: 2000, ... },
  { _id: "...", name: "Professional", price: 5000, ... }
]
```

### Check #4: Common Issues

| Issue | Solution |
|-------|----------|
| **CORS Error** | Already configured in server, but check `corsOptions` |
| **401 Unauthorized** | Use `fetchPublicPricingPlans()` - no token needed |
| **Empty Array** | Check MongoDB - `PricingPlan.find()` returns 0 documents |
| **Wrong Format** | Backend must return direct array, not `{ data: [...] }` |
| **Network Timeout** | Check if backend is running at https://amategeko-backend-new.onrender.com/api/health |

### Check #5: Backend Health Check
```bash
curl "https://amategeko-backend-new.onrender.com/api/health"

# Should return:
{
  "status": "OK",
  "timestamp": "2026-03-26T10:30:00.000Z",
  "environment": "production"
}
```

## If Still Not Working

1. **Check backend logs** - Render.com dashboard shows logs
2. **Test API endpoint directly** - Use Postman to verify response
3. **Verify MongoDB connection** - Database might be down
4. **Check `isActive` flag** - Plans must have `isActive: true`
5. **Restart backend** - Sometimes helps with connection issues

## Pull-to-Refresh Features

All three tabs now support:
- 🔄 Pull down from top to refresh data
- ⏳ Shows loading indicator while fetching
- ✅ Automatically dismisses when done
- 📱 Works on both Android and iOS

Just pull down on any tab to refresh!
