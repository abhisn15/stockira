# 🔐 Security Guide - Stockira App

## 🚨 CRITICAL: Read This First!

**This application contains sensitive API keys and credentials. Follow these security guidelines to protect your data and prevent unauthorized access.**

## ⚡ Quick Start

1. **Run the security setup script:**
   ```bash
   ./scripts/setup-security.sh
   ```

2. **Edit the created files with your actual credentials:**
   - `.env` - Environment variables
   - `android/local.properties` - Android configuration
   - `ios/Configuration/ApiKeys.xcconfig` - iOS configuration

3. **Verify security configuration:**
   ```bash
   ./scripts/check-security.sh
   ```

## 🛡️ Security Features

### ✅ Implemented Security Measures

- **Environment Variables**: All API keys stored in `.env` file
- **Git Protection**: Sensitive files excluded from version control
- **Template Files**: Example files provided for easy setup
- **Automated Scripts**: Setup and verification scripts included
- **Comprehensive Documentation**: Security guides and best practices

### 🔒 Protected Files

The following files are **NEVER** committed to Git:

- `.env` - Environment variables with API keys
- `android/local.properties` - Android configuration with API keys
- `ios/Configuration/ApiKeys.xcconfig` - iOS configuration with API keys
- `*.keystore` - Android signing keys
- `*.mobileprovision` - iOS provisioning profiles
- `*.p12` - iOS certificates
- `*.log` - Log files (may contain sensitive data)

## 📁 File Structure

```
stockira/
├── .env                          # ❌ NEVER COMMIT - Your actual credentials
├── env.example                   # ✅ Template for .env
├── android/
│   ├── local.properties          # ❌ NEVER COMMIT - Android config
│   └── local.properties.example  # ✅ Template for Android config
├── ios/Configuration/
│   ├── ApiKeys.xcconfig          # ❌ NEVER COMMIT - iOS config
│   └── ApiKeys.xcconfig.example  # ✅ Template for iOS config
├── scripts/
│   ├── setup-security.sh         # ✅ Security setup script
│   └── check-security.sh         # ✅ Security verification script
├── SECURITY_SETUP.md             # ✅ Detailed security guide
└── README_SECURITY.md            # ✅ This file
```

## 🔧 Setup Instructions

### 1. Environment Variables

Create your `.env` file:
```bash
cp env.example .env
```

Edit `.env` with your actual values:
```env
# API Configuration
BASE_URL=https://your-actual-api-domain.com
PREFIX_API=api
API_VERSION=v1

# Google Maps API Keys
GOOGLE_MAPS_API_KEY_ANDROID=your_actual_android_key
GOOGLE_MAPS_API_KEY_IOS=your_actual_ios_key

# Google Maps Map IDs
GOOGLE_MAPS_MAP_ID_ANDROID=your_actual_android_map_id
GOOGLE_MAPS_MAP_ID_IOS=your_actual_ios_map_id
```

### 2. Android Configuration

Create your Android config:
```bash
cp android/local.properties.example android/local.properties
```

Edit `android/local.properties`:
```properties
# Google Maps API Keys
GOOGLE_MAPS_API_KEY_ANDROID=your_actual_android_key
GOOGLE_MAPS_MAP_ID_ANDROID=your_actual_android_map_id
```

### 3. iOS Configuration

Create your iOS config:
```bash
cp ios/Configuration/ApiKeys.xcconfig.example ios/Configuration/ApiKeys.xcconfig
```

Edit `ios/Configuration/ApiKeys.xcconfig`:
```xcconfig
// Google Maps Configuration
GOOGLE_MAPS_API_KEY_IOS = your_actual_ios_key
GOOGLE_MAPS_MAP_ID_IOS = your_actual_ios_map_id
```

## 🔍 Security Verification

### Automated Security Check

Run the security verification script:
```bash
./scripts/check-security.sh
```

This script checks for:
- ✅ Sensitive files in Git repository
- ✅ Hardcoded API keys in source code
- ✅ Proper .gitignore configuration
- ✅ Template files availability
- ✅ Debug prints in production code
- ✅ Unused imports and potential issues

### Manual Security Checklist

Before committing code:
- [ ] No `.env` file in repository
- [ ] No `local.properties` file in repository
- [ ] No `ApiKeys.xcconfig` file in repository
- [ ] No hardcoded API keys in source code
- [ ] All sensitive files in `.gitignore`
- [ ] Security check script passes

## 🚨 Emergency Procedures

### If API Key is Compromised

1. **Immediately revoke the compromised key**
2. **Generate new API key**
3. **Update all environment files**
4. **Deploy updated app**
5. **Monitor for suspicious activity**

### If Credentials are Exposed in Git

1. **Remove from Git history** (if recently committed)
2. **Change all affected credentials**
3. **Notify team members**
4. **Review access logs**
5. **Update security procedures**

## 📚 Additional Resources

- [SECURITY_SETUP.md](SECURITY_SETUP.md) - Detailed security setup guide
- [Google Maps API Security](https://developers.google.com/maps/api-security-best-practices)
- [Flutter Security Guide](https://docs.flutter.dev/security)
- [Environment Variables Best Practices](https://12factor.net/config)

## 🤝 Contributing

When contributing to this project:

1. **Never commit sensitive files**
2. **Use environment variables for all credentials**
3. **Run security checks before submitting PR**
4. **Follow security best practices**
5. **Report security issues privately**

## 📞 Support

For security-related questions or issues:
- **Security Issues**: security@yourcompany.com
- **Technical Support**: dev@yourcompany.com
- **Emergency Contact**: +1-XXX-XXX-XXXX

---

**Remember: Security is everyone's responsibility! 🔐**

*Last updated: $(date)*
