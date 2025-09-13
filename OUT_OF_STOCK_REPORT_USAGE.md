# Out of Stock Report Feature

## Overview
The Out of Stock (OOS) Report feature allows users to submit comprehensive reports about product inventory status, including actual quantities, estimated purchase orders, sales data, and distributor availability.

## Features

### 📋 **Form Fields**
- **Store Information**: Automatically populated from current check-in
- **Date**: Date picker for the report date
- **Report Type**: Toggle between "Out of Stock" and "In Stock"
- **Products Array**: Dynamic list of products with detailed inventory data
- **Images**: Multiple image uploads for supporting documentation

### 🛒 **Dynamic Products Management**
- **Add Product**: Button to add new products to the report
- **Remove Product**: Individual product removal with delete button
- **Product Search**: Searchable dropdown with product filtering
- **Comprehensive Data**: Each product includes:
  - Product selection with search
  - Actual quantity
  - Estimated purchase order (PO)
  - Average weekly sales (out)
  - Average weekly sales (in)
  - OOS from distributor toggle

### 🖼️ **Image Upload**
- **Single Camera**: Take one photo at a time
- **Multiple Gallery**: Select multiple images from gallery
- **Preview**: Grid view of selected images
- **Remove**: Individual image removal capability

## API Integration

### **POST** `/reports/out-of-stock`
**Request Body (form-data):**
```
store_id: 1
date: 2025-08-12
is_out_of_stock: 1
products[0][product_id]: 101
products[0][actual_qty]: 0
products[0][estimated_po]: 50
products[0][average_weekly_sale_out]: 20
products[0][average_weekly_sale_in]: 15
products[0][oos_distributor]: 0
products[1][product_id]: 102
products[1][actual_qty]: 2
products[1][estimated_po]: 30
products[1][average_weekly_sale_out]: 10
products[1][average_weekly_sale_in]: 8
products[1][oos_distributor]: 1
images[]: [file1.jpg, file2.jpg]
```

**Response:**
```json
{
  "success": true,
  "message": "Out of stock report created successfully",
  "data": {
    "id": 1
  }
}
```

### **GET** `/products?conditions[origin_id]=1`
**Query Parameters:**
- `search`: Search term for product name/code
- `per_page`: Number of products per page
- `conditions[origin_id]`: Filter by origin ID

**Response:**
```json
{
  "success": true,
  "message": "Products fetched successfully",
  "data": [
    {
      "id": 101,
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

### 1. **Access Out of Stock Report**
1. Open the app
2. Navigate to **Reports** section
3. Tap **"Out of Stock"** card

### 2. **Prerequisites**
- User must be checked in to a store
- Valid authentication token required

### 3. **Fill Form**
1. **Store**: Automatically populated from check-in
2. **Date**: Select report date using date picker
3. **Report Type**: Toggle between "Out of Stock" and "In Stock"
4. **Products**: Add products with detailed inventory data
5. **Images**: Add supporting images (optional)

### 4. **Add Products**
1. Tap **"Add Product"** button
2. Search and select product from dropdown
3. Enter actual quantity (current stock)
4. Enter estimated purchase order quantity
5. Enter average weekly sales out
6. Enter average weekly sales in
7. Toggle OOS from distributor if applicable
8. Repeat for additional products

### 5. **Submit Report**
1. Verify all required fields are filled
2. Ensure at least one product is added
3. Tap **"Submit Out of Stock Report"**
4. Wait for confirmation message

## File Structure

```
lib/
├── models/
│   └── out_of_stock_report.dart    # Data models
├── services/
│   └── out_of_stock_service.dart   # API service
└── screens/reports/OutOfStock/
    └── index.dart                  # UI screen
```

## Error Handling

### **Validation Errors**
- Missing required fields
- No products added
- Invalid numeric input for quantities
- Missing product selection
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
- Product cards with clear numbering
- Delete buttons for individual products
- Form validation with error messages
- Report type toggle with color coding

### **Dynamic Interface**
- Add/remove products functionality
- Product search and filtering
- Responsive product cards
- Toggle switches for boolean values
- Image preview with remove functionality
- Clear visual hierarchy

## Technical Details

### **Data Structure**
- **OutOfStockProduct**: Product ID, quantities, sales data, distributor status
- **Product**: Complete product information with pricing
- **Form Validation**: Real-time validation for all numeric fields
- **Image Handling**: Multiple image upload with compression

### **State Management**
- Loading states for API calls
- Form state management
- Dynamic products list management
- Search filtering state
- Error state handling

### **API Communication**
- Multipart form data for complex structures
- Indexed array fields (products[0][product_id])
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
- [ ] Dynamic product addition/removal
- [ ] Product search functionality
- [ ] Numeric field validation
- [ ] Toggle switches work properly
- [ ] Image upload functionality
- [ ] API integration successful
- [ ] Error handling displays properly
- [ ] Navigation flows correctly
- [ ] Responsive design on different devices
- [ ] Store check-in validation
- [ ] Success/error feedback

## Sample Data Flow

### **Adding Products:**
1. User taps "Add Product"
2. New product card appears with form fields
3. User searches and selects product from dropdown
4. User enters inventory and sales data
5. User toggles distributor status if needed
6. Product is ready for submission

### **Form Submission:**
1. Validate all products have required data
2. Convert products to API format with indexed arrays
3. Send multipart form data with images
4. Handle response and show feedback
5. Navigate back on success

## Advanced Features

### **Product Search**
- Real-time filtering as user types
- Search by product name or code
- Dropdown updates dynamically
- Maintains selected product state

### **Report Type Toggle**
- Visual distinction between Out of Stock and In Stock
- Color-coded interface (red/green)
- Toggle affects overall report context
- Maintains state throughout form

### **Image Management**
- Multiple image selection
- Preview with remove functionality
- Automatic compression and optimization
- Filename generation with timestamps

## Future Enhancements

- Bulk product import functionality
- Advanced product filtering (category, brand)
- Quantity validation against historical data
- Barcode scanning for product selection
- Draft functionality for saving incomplete reports
- Offline form saving
- Product recommendation based on history
- Automated quantity calculations
- Integration with inventory management systems
