# Display Report Feature

## Overview
The Display Report feature allows users to submit reports about store display conditions, including type of additional display, constraints, total bucket products, and supporting images.

## Features

### 📋 **Form Fields**
- **Store Information**: Automatically populated from current check-in
- **Type Additional**: Dropdown selection from API (DOUBLE DECKER, FREEZER ISLAND, etc.)
- **Constraint**: Text input for describing constraints
- **Total Bucket Product**: Numeric input for product count
- **Images**: Multiple image uploads (camera/gallery)

### 🖼️ **Image Upload**
- **Single Camera**: Take one photo at a time
- **Multiple Gallery**: Select multiple images from gallery
- **Preview**: Grid view of selected images
- **Remove**: Individual image removal capability

## API Integration

### **POST** `/reports/display`
**Request Body (form-data):**
```
store_id: 3
type_additional_id: 1
constraint: "tes"
total_bucket_product: 3
images[]: [file1.jpg, file2.jpg, file3.jpg]
```

**Response:**
```json
{
  "success": true,
  "message": "Display report created successfully",
  "data": {
    "id": 1
  }
}
```

### **GET** `/type/additional`
**Response:**
```json
{
  "success": true,
  "message": "Type additionals fetched successfully",
  "data": [
    {
      "id": 1,
      "name": "DOUBLE DECKER"
    },
    {
      "id": 2,
      "name": "FREEZER ISLAND"
    }
  ]
}
```

## Usage Instructions

### 1. **Access Display Report**
1. Open the app
2. Navigate to **Reports** section
3. Tap **"Display"** card

### 2. **Prerequisites**
- User must be checked in to a store
- Valid authentication token required

### 3. **Fill Form**
1. **Store**: Automatically populated from check-in
2. **Type Additional**: Select from dropdown
3. **Constraint**: Enter description text
4. **Total Bucket Product**: Enter numeric value
5. **Images**: Add multiple photos

### 4. **Submit Report**
1. Verify all required fields are filled
2. Tap **"Submit Display Report"**
3. Wait for confirmation message

## File Structure

```
lib/
├── models/
│   └── display_report.dart          # Data models
├── services/
│   └── display_report_service.dart  # API service
└── screens/reports/Display/
    └── index.dart                   # UI screen
```

## Error Handling

### **Validation Errors**
- Missing required fields
- Invalid numeric input
- No images selected
- Not checked in to store

### **API Errors**
- Network connectivity issues
- Authentication failures
- Server validation errors
- Image upload failures

## User Experience

### **Visual Feedback**
- Loading states during data fetch
- Success/error snackbar messages
- Image preview with remove option
- Form validation with error messages

### **Responsive Design**
- Adapts to different screen sizes
- Touch-friendly image selection
- Clear form layout and spacing

## Technical Details

### **Image Handling**
- Multiple image selection support
- Automatic image compression (80% quality)
- Maximum dimensions: 1920x1080
- File naming with timestamp

### **Form Validation**
- Required field validation
- Numeric input validation
- Image count validation
- Store check-in validation

### **State Management**
- Loading states for API calls
- Form state management
- Image selection state
- Error state handling

## Integration Points

### **Attendance Service**
- Retrieves current store information
- Validates user check-in status

### **Auth Service**
- Provides authentication tokens
- Handles token validation

### **Navigation**
- Integrated into Reports screen
- Proper back navigation
- Error state navigation

## Testing Checklist

- [ ] Form validation works correctly
- [ ] Image upload functionality
- [ ] API integration successful
- [ ] Error handling displays properly
- [ ] Navigation flows correctly
- [ ] Responsive design on different devices
- [ ] Store check-in validation
- [ ] Success/error feedback

## Future Enhancements

- Image compression optimization
- Offline form saving
- Draft functionality
- Image editing capabilities
- Bulk image upload progress
- Form field auto-save
