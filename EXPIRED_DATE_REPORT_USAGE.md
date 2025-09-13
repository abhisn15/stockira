# Expired Date Report Feature

## Overview
The Expired Date Report feature allows users to submit reports about products with expired dates, including product selection, quantities, and expiration dates for inventory management.

## Features

### 📋 **Form Fields**
- **Store Information**: Automatically populated from current check-in
- **Date**: Date picker for the report date
- **Items Array**: Dynamic list of products with:
  - **Product Selection**: Dropdown from API products
  - **Quantity**: Numeric input for product count
  - **Expired Date**: Date picker for expiration date

### 🛒 **Dynamic Items Management**
- **Add Item**: Button to add new items to the report
- **Remove Item**: Individual item removal with delete button
- **Item Validation**: Comprehensive validation for each item
- **Product Search**: Dropdown with product name and code display

## API Integration

### **POST** `/expired-dates`
**Request Body (form-data):**
```
store_id: 1
date: 2025-08-13
items[0][product_id]: 1
items[0][qty]: 10
items[0][expired_date]: 2025-08-12
items[1][product_id]: 2
items[1][qty]: 5
items[1][expired_date]: 2025-08-12
```

**Response:**
```json
{
  "success": true,
  "message": "Expired date report created successfully",
  "data": {
    "id": 1
  }
}
```

### **GET** `/products?conditions[origin_id]=1`
**Response:**
```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": [
    {
      "id": 2,
      "code": "20100009",
      "name": "AICE Chocolate Crispy Stick 60g",
      "subbrand": {
        "name": "ICE CREAM",
        "product_brand": {
          "name": "AICE"
        }
      },
      "latest_price": {
        "price": "98104.00"
      }
    }
  ]
}
```

## Usage Instructions

### 1. **Access Expired Date Report**
1. Open the app
2. Navigate to **Reports** section
3. Tap **"Expired Date"** card

### 2. **Prerequisites**
- User must be checked in to a store
- Valid authentication token required

### 3. **Fill Form**
1. **Store**: Automatically populated from check-in
2. **Date**: Select report date using date picker
3. **Items**: Add products with quantities and expiration dates

### 4. **Add Items**
1. Tap **"Add Item"** button
2. Select product from dropdown
3. Enter quantity (numeric)
4. Select expired date using date picker
5. Repeat for additional items

### 5. **Submit Report**
1. Verify all required fields are filled
2. Ensure at least one item is added
3. Tap **"Submit Expired Date Report"**
4. Wait for confirmation message

## File Structure

```
lib/
├── models/
│   └── expired_date_report.dart    # Data models
├── services/
│   └── expired_date_service.dart   # API service
└── screens/reports/ExpiredDate/
    └── index.dart                  # UI screen
```

## Error Handling

### **Validation Errors**
- Missing required fields
- No items added
- Invalid numeric input for quantity
- Missing product selection
- Missing expired date
- Not checked in to store

### **API Errors**
- Network connectivity issues
- Authentication failures
- Server validation errors
- Product not found errors

## User Experience

### **Visual Feedback**
- Loading states during data fetch
- Success/error snackbar messages
- Item cards with clear numbering
- Delete buttons for individual items
- Form validation with error messages

### **Dynamic Interface**
- Add/remove items functionality
- Responsive item cards
- Date picker integration
- Product dropdown with search
- Clear visual hierarchy

## Technical Details

### **Data Structure**
- **ExpiredDateItem**: Product ID, quantity, expired date
- **Product**: Complete product information with pricing
- **Form Validation**: Real-time validation for all fields
- **Date Handling**: ISO format for API communication

### **State Management**
- Loading states for API calls
- Form state management
- Dynamic items list management
- Error state handling

### **API Communication**
- Multipart form data for complex structures
- Indexed array fields (items[0][product_id])
- Proper error handling and user feedback
- Authentication token management

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
- [ ] Dynamic item addition/removal
- [ ] Product dropdown functionality
- [ ] Date picker integration
- [ ] API integration successful
- [ ] Error handling displays properly
- [ ] Navigation flows correctly
- [ ] Responsive design on different devices
- [ ] Store check-in validation
- [ ] Success/error feedback

## Sample Data Flow

### **Adding Items:**
1. User taps "Add Item"
2. New item card appears with form fields
3. User selects product from dropdown
4. User enters quantity
5. User selects expired date
6. Item is ready for submission

### **Form Submission:**
1. Validate all items have required data
2. Convert items to API format
3. Send multipart form data
4. Handle response and show feedback
5. Navigate back on success

## Future Enhancements

- Bulk product import functionality
- Product search and filtering
- Expired date validation (not in past)
- Item duplication feature
- Draft functionality for saving incomplete reports
- Offline form saving
- Barcode scanning for product selection
- Quantity validation against stock levels
