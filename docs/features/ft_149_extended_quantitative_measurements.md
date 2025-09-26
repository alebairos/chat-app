# FT-149.11: Extended Quantitative Measurements Support

**Feature ID**: FT-149.11  
**Priority**: Medium  
**Category**: Enhancement / Data Coverage  
**Effort**: 8-12 hours  

## Problem Statement

Current FT-149.10 implementation handles **~15 basic quantitative types** but is missing **50+ specialized measurements** across health, finance, productivity, nutrition, environment, and lifestyle domains.

**Current Coverage**: volume, distance, steps, duration, weight, cycles, reps, sets, pace, calories, heart_rate
**Missing Coverage**: 50+ measurement types that users naturally track

## Solution Overview

Extend the quantitative metadata system to support comprehensive measurement types across all life domains, enabling rich long-term memory and progress tracking for diverse user activities.

## Missing Quantitative Measurements

### 🏥 Health & Biometrics (Priority: High)
- **Blood Pressure**: "My BP was 120/80" → `blood_pressure: {systolic: 120, diastolic: 80}`
- **Blood Sugar**: "Glucose level 95 mg/dL" → `glucose: {amount: 95, unit: "mg/dL"}`
- **Body Temperature**: "Fever of 38.5°C" → `temperature: {amount: 38.5, unit: "°C"}`
- **Oxygen Saturation**: "SpO2 was 98%" → `oxygen_saturation: {amount: 98, unit: "%"}`
- **Body Fat %**: "Body fat 15%" → `body_fat_percentage: {amount: 15, unit: "%"}`
- **BMI**: "BMI is 24.2" → `bmi: {amount: 24.2, unit: "kg/m²"}`

### 💰 Financial (Priority: High)
- **Money Spent**: "Spent $45 on groceries" → `money_spent: {amount: 45, unit: "USD"}`
- **Income**: "Earned $500 today" → `income: {amount: 500, unit: "USD"}`
- **Savings**: "Saved $200 this month" → `savings: {amount: 200, unit: "USD"}`
- **Investment**: "Invested $1000 in stocks" → `investment: {amount: 1000, unit: "USD"}`

### 📚 Learning & Productivity (Priority: High)
- **Pages Read**: "Read 25 pages" → `pages: {amount: 25, unit: "pages"}`
- **Words Written**: "Wrote 500 words" → `words: {amount: 500, unit: "words"}`
- **Emails Processed**: "Answered 12 emails" → `emails: {amount: 12, unit: "emails"}`
- **Tasks Completed**: "Finished 8 tasks" → `tasks: {amount: 8, unit: "tasks"}`
- **Study Hours**: "Studied 3 hours" → `study_duration: {amount: 3, unit: "hours"}`

### 🍽️ Nutrition (Priority: Medium)
- **Protein**: "Had 30g protein" → `protein: {amount: 30, unit: "g"}`
- **Carbohydrates**: "Ate 45g carbs" → `carbohydrates: {amount: 45, unit: "g"}`
- **Calories Consumed**: "Ate 500 calories" → `calories_consumed: {amount: 500, unit: "cal"}`
- **Sugar**: "15g sugar" → `sugar: {amount: 15, unit: "g"}`
- **Fiber**: "25g fiber" → `fiber: {amount: 25, unit: "g"}`

### 🌡️ Environmental (Priority: Medium)
- **Temperature**: "Room temp 22°C" → `ambient_temperature: {amount: 22, unit: "°C"}`
- **Humidity**: "Humidity 65%" → `humidity: {amount: 65, unit: "%"}`
- **Air Quality**: "AQI 45" → `air_quality: {amount: 45, unit: "AQI"}`
- **Noise Level**: "85 dB" → `noise_level: {amount: 85, unit: "dB"}`

### 🚗 Transportation (Priority: Low)
- **Speed**: "Drove 80 km/h" → `speed: {amount: 80, unit: "km/h"}`
- **Fuel**: "Used 40L gas" → `fuel_consumed: {amount: 40, unit: "L"}`
- **Miles Driven**: "Drove 150 miles" → `distance_driven: {amount: 150, unit: "miles"}`

### 💧 Detailed Hydration (Priority: Low)
- **Water Temperature**: "Drank cold water 5°C" → `water_temperature: {amount: 5, unit: "°C"}`
- **Electrolytes**: "500mg sodium" → `sodium: {amount: 500, unit: "mg"}`

### 🏃‍♂️ Advanced Fitness (Priority: Medium)
- **VO2 Max**: "VO2 max 45" → `vo2_max: {amount: 45, unit: "ml/kg/min"}`
- **Power Output**: "250 watts" → `power: {amount: 250, unit: "watts"}`
- **Cadence**: "90 RPM" → `cadence: {amount: 90, unit: "rpm"}`
- **Elevation**: "Climbed 500m elevation" → `elevation_gain: {amount: 500, unit: "m"}`

### 😴 Sleep Details (Priority: Medium)
- **Sleep Quality Score**: "Sleep score 85/100" → `sleep_score: {amount: 85, unit: "score"}`
- **REM Sleep**: "2.5 hours REM" → `rem_sleep: {amount: 2.5, unit: "hours"}`
- **Deep Sleep**: "1.8 hours deep sleep" → `deep_sleep: {amount: 1.8, unit: "hours"}`

### 🧠 Mental Health (Priority: Medium)
- **Mood Score**: "Mood 7/10" → `mood_score: {amount: 7, unit: "scale"}`
- **Stress Level**: "Stress 4/10" → `stress_level: {amount: 4, unit: "scale"}`
- **Anxiety Level**: "Anxiety 3/10" → `anxiety_level: {amount: 3, unit: "scale"}`

### 📱 Digital (Priority: Low)
- **Screen Time**: "4 hours screen time" → `screen_time: {amount: 4, unit: "hours"}`
- **App Usage**: "Instagram 45 minutes" → `app_usage: {amount: 45, unit: "minutes"}`
- **Notifications**: "Got 23 notifications" → `notifications: {amount: 23, unit: "count"}`

### 🏠 Household (Priority: Low)
- **Chores**: "Did 3 chores" → `chores: {amount: 3, unit: "tasks"}`
- **Cleaning Time**: "Cleaned for 30 minutes" → `cleaning_duration: {amount: 30, unit: "minutes"}`
- **Laundry Loads**: "2 loads of laundry" → `laundry_loads: {amount: 2, unit: "loads"}`

## Implementation Strategy

### Phase 1: High Priority (Health, Finance, Productivity)
**Effort**: 4 hours
- Add 15 most critical measurement types
- Focus on health metrics, financial tracking, productivity
- Essential for comprehensive life tracking

### Phase 2: Medium Priority (Nutrition, Fitness, Sleep, Mental Health)
**Effort**: 3 hours  
- Add 20 lifestyle and wellness measurements
- Enhanced fitness and sleep tracking
- Mental health quantification

### Phase 3: Low Priority (Environmental, Transportation, Digital, Household)
**Effort**: 2 hours
- Add remaining specialized measurements
- Complete coverage for niche use cases

## Technical Implementation

### 1. Extend Targets Array
```dart
final targets = [
  // Existing (FT-149.10)
  'volume', 'quantity', 'cycles', 'distance', 'steps', 'duration', 'weight', 'reps', 'sets',
  
  // Phase 1: High Priority
  'blood_pressure', 'glucose', 'temperature', 'money_spent', 'income', 'pages', 'words', 'emails', 'tasks',
  
  // Phase 2: Medium Priority  
  'protein', 'carbohydrates', 'calories_consumed', 'vo2_max', 'power', 'sleep_score', 'mood_score',
  
  // Phase 3: Low Priority
  'speed', 'screen_time', 'chores', 'humidity', 'noise_level'
];
```

### 2. Add Parser Logic
```dart
// Health metrics
if (key.contains('blood_pressure')) {
  final bp = quantitative['blood_pressure'];
  return "${bp['systolic']}/${bp['diastolic']}";
}

// Financial
if (key.contains('money') || key.contains('income') || key.contains('savings')) {
  final financial = quantitative[key];
  return financial['amount'];
}
```

### 3. Add Icons and Formatting
```dart
// Health icons
case 'blood_pressure': return '🩺';
case 'glucose': return '🩸';
case 'temperature': return '🌡️';

// Financial icons  
case 'money_spent': case 'income': case 'savings': return '💰';

// Productivity icons
case 'pages': return '📖';
case 'words': return '✍️';
case 'emails': return '📧';
```

## Expected Benefits

### Long-term Memory Enhancement
- **Comprehensive Health Tracking**: BP trends, glucose patterns, temperature logs
- **Financial Intelligence**: Spending patterns, income tracking, savings goals
- **Productivity Insights**: Reading habits, writing output, task completion rates
- **Lifestyle Optimization**: Sleep quality trends, mood patterns, fitness progress

### User Experience
- **Universal Coverage**: Support for any quantitative activity users track
- **Consistent Display**: All measurements follow same `🔢 value unit` format
- **Rich Context**: Detailed metadata for pattern analysis and goal setting

## Success Metrics
- **Coverage**: Support 50+ quantitative measurement types
- **Accuracy**: 95%+ correct extraction and display
- **Performance**: <100ms parsing time for extended measurements
- **User Adoption**: 80%+ of quantitative activities display meaningful insights

## Future Extensions
- **Custom Measurements**: User-defined quantitative types
- **Unit Conversion**: Automatic conversion between units (kg/lbs, °C/°F)
- **Trend Analysis**: Historical patterns and progress tracking
- **Goal Integration**: Automatic goal suggestions based on tracked metrics
