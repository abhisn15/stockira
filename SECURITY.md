# 🔐 Security Configuration Guide

## API Key Management

### Environment Variables Setup

1. **Create `.env` file in project root** (already gitignored for security):
```bash
# API Configuration
BASE_URL=https://aice.tpm-facility.com
PREFIX_API=api
API_VERSION=v1

# Google Maps API Keys (SECURE - DO NOT COMMIT)
GOOGLE_MAPS_API_KEY_IOS=AIzaSyCdJRx2WW7pkf3QGCwV6NY7RphAS683kzY
GOOGLE_MAPS_API_KEY_ANDROID=AIzaSyAC-5pPVZot30WENTHNSntNsFfqMbjQFjw
GOOGLE_MAPS_WEB_API_KEY=AIzaSyAC-5pPVZot30WENTHNSntNsFfqMbjQFjw

# Google Maps Map IDs (SECURE - DO NOT COMMIT)
GOOGLE_MAPS_MAP_ID_IOS=71ed63eff6a1ac4fe8b35b3d
GOOGLE_MAPS_MAP_ID_ANDROID=71ed63eff6a1ac4fe8b35b3d
```

### Android Security

- **API Keys stored in**: `android/local.properties` (gitignored)
- **Map IDs stored in**: `android/local.properties` (gitignored)
- **Build configuration**: Automatic injection via `build.gradle.kts`
- **Manifest placeholders**: 
  - `${GOOGLE_MAPS_API_KEY}` - resolved at build time
  - `${GOOGLE_MAPS_MAP_ID}` - resolved at build time

### iOS Security

- **API Keys**: Managed through `MapsService` and `MapsConfig`
- **Map IDs**: Managed through `MapsService` and `MapsConfig`
- **Runtime validation**: API key and Map ID format validation
- **Fallback mechanism**: Secure fallback keys and Map IDs if .env fails

### Flutter Application

- **MapsService**: Centralized API key and Map ID management with caching
- **MapsConfig**: Environment-based configuration for both API keys and Map IDs
- **Runtime validation**: API key format and availability checking

## Security Features

✅ **Environment Variables**: API keys and Map IDs stored in `.env` (gitignored)
✅ **Build-time Injection**: Android uses gradle placeholders for both keys and IDs
✅ **Runtime Validation**: API key and Map ID format validation
✅ **Secure Caching**: In-memory caching with validation
✅ **Fallback Mechanism**: Secure fallbacks if environment fails
✅ **Debug Tools**: Masked logging for security audit
✅ **Platform Detection**: Automatic platform-specific keys and Map IDs
✅ **Map ID Management**: Secure handling of Google Maps Map IDs

## Files Protected

- `.env` - Environment variables (gitignored)
- `android/local.properties` - Android secure config (gitignored)
- API keys never hardcoded in source code (except secure fallbacks)

## Usage in Code

```dart
// Secure API key and Map ID access
final mapsService = MapsService();
final apiKey = mapsService.apiKey; // Platform-appropriate key
final mapId = mapsService.mapId; // Platform-appropriate Map ID

// Security validation
if (mapsService.isSecurelyConfigured) {
  // Proceed with Maps initialization
  print('🗺️ Using Map ID: ${mapsService.maskedMapId}');
} else {
  // Handle security error
}
```

## Development Setup

1. Copy `.env.example` to `.env`
2. Add your actual API keys to `.env`
3. For Android: Update `android/local.properties`
4. Never commit `.env` or `local.properties` files

## Production Deployment

- Use CI/CD environment variables
- Never expose API keys in public repositories
- Use different keys for development/staging/production
- Regularly rotate API keys for security
