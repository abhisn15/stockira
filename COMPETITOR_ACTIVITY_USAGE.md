# Competitor Activity Feature Usage Guide

## Overview
The Competitor Activity feature allows users to report competitor promotional activities, displays, and POSM (Point of Sale Materials) in stores. This feature is integrated into the Reports section of the app.

## How to Access
1. Open the Stockira app
2. Navigate to the **Reports** section from the main dashboard
3. Look for **"Competitor Activity"** in the reports grid
4. Tap on it to open the Competitor Activity form

## Prerequisites
- User must be **checked in** to a store before creating competitor activity reports
- The app will automatically detect the current store from your attendance record

## Form Fields

### Required Fields
- **Principal**: Select from available product principals (Diamond, JOYDAY, GLICOWINGS, WALLS, CAMPINA)
- **Type Promotion**: Choose promotion type (DISKON, GIMMICK, BUY 1 GET 1, POTONGAN HARGA, MEMBER, BELI 2 GRATIS 1)
- **Promo Mechanism**: Text description of the promotional mechanism
- **Start Date**: When the promotion starts
- **End Date**: When the promotion ends
- **Products**: Select one or more products involved in the promotion

### Optional Fields
- **Additional Display**: Toggle if there's additional display equipment
  - If enabled, select type: DOUBLE DECKER, FREEZER ISLAND, STANDING FREEZER, SHARING FREEZER AICE, SHARING FREEZER BRAND LAIN, FREEZER AICE
- **POSM**: Toggle if Point of Sale Materials are present
  - If enabled, select type: WOBBLER, POP
- **Photo**: Take a photo or select from gallery (optional)

## API Endpoints Used

### GET Endpoints (for dropdown data)
- `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/type/promotion` - Get promotion types
- `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/type/additional` - Get additional display types
- `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/type/posm` - Get POSM types
- `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/products/principals?conditions[origin_id]=1` - Get product principals

### POST Endpoint (for submission)
- `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/reports/competitor-activity`

## Form Submission Data
The form submits the following data:
```json
{
  "principal_id": 1,
  "store_id": 123,
  "type_promotion_id": 2,
  "promo_mechanism": "Buy 2 Get 1 Free on Ice Cream",
  "start_date": "2025-01-15",
  "end_date": "2025-01-30",
  "is_additional_display": 1,
  "is_posm": 0,
  "image": "base64_encoded_image_or_file",
  "products": ["WALLS Ice Cream", "Diamond Ice Cream"],
  "type_additional_id": 3,
  "type_posm_id": null
}
```

## Features
- **Responsive Design**: Works on all device sizes
- **Image Capture**: Camera and gallery integration
- **Multi-select Products**: Choose multiple products in one report
- **Conditional Fields**: Additional display and POSM fields appear based on toggles
- **Form Validation**: Comprehensive validation before submission
- **Loading States**: Visual feedback during data loading and submission
- **Error Handling**: User-friendly error messages

## User Roles
- **MD CVS**: Full access to Competitor Activity reports
- **SPG**: Full access to Competitor Activity reports
- **Other roles**: May have limited access based on role configuration

## File Structure
```
lib/
├── models/
│   └── competitor_activity.dart          # Data models
├── services/
│   └── competitor_activity_service.dart  # API service
└── screens/
    └── reports/
        ├── index.dart                    # Reports main screen
        └── competitor_activity_screen.dart # Competitor activity form
```

## Integration Notes
- The feature is automatically integrated into the existing Reports screen
- Store information is pulled from the current attendance record
- All API calls include proper authentication headers
- Image uploads are handled via multipart form data
- The feature follows the existing app's design patterns and color scheme
