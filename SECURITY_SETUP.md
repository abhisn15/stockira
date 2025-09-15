# 🔐 Security Setup Guide - Stockira App

## ⚠️ IMPORTANT SECURITY NOTICE

This document contains critical security information for the Stockira application. Please read carefully and follow all security practices.

## 📋 Quick Setup Checklist

- [ ] Copy `env.example` to `.env` and fill in your credentials
- [ ] Copy `android/local.properties.example` to `android/local.properties`
- [ ] Copy `ios/Configuration/ApiKeys.xcconfig.example` to `ios/Configuration/ApiKeys.xcconfig`
- [ ] Verify all sensitive files are in `.gitignore`
- [ ] Never commit `.env`, `local.properties`, or `ApiKeys.xcconfig` files
- [ ] Use environment variables for all API keys and secrets

## 🛡️ Security Features Implemented

### 1. Environment Variables (.env)
- ✅ All API keys stored in environment variables
- ✅ `.env` file excluded from Git
- ✅ Template file (`env.example`) provided for setup
- ✅ Support for multiple environments (dev, staging, prod)

### 2. Android Security
- ✅ `local.properties` excluded from Git
- ✅ Google Maps API keys in environment variables
- ✅ Template file provided for easy setup
- ✅ Keystore files excluded from version control

### 3. iOS Security
- ✅ `ApiKeys.xcconfig` excluded from Git
- ✅ Google Maps API keys in environment variables
- ✅ Template file provided for easy setup
- ✅ Provisioning profiles excluded from version control

### 4. Git Security
- ✅ Comprehensive `.gitignore` for all sensitive files
- ✅ All credential files excluded from version control
- ✅ Log files excluded (may contain sensitive data)
- ✅ Temporary files excluded

## 🔧 Setup Instructions

### Step 1: Environment Variables

1. **Copy the template file:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` file with your actual credentials:**
   ```bash
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

### Step 2: Android Configuration

1. **Copy the template file:**
   ```bash
   cp android/local.properties.example android/local.properties
   ```

2. **Edit `android/local.properties` with your actual values:**
   ```properties
   # Android SDK path (auto-detected)
   sdk.dir=/path/to/your/android/sdk
   
   # Flutter SDK path (auto-detected)
   flutter.sdk=/path/to/your/flutter/sdk
   
   # Google Maps API Keys
   GOOGLE_MAPS_API_KEY_ANDROID=your_actual_android_key
   GOOGLE_MAPS_MAP_ID_ANDROID=your_actual_android_map_id
   ```

### Step 3: iOS Configuration

1. **Copy the template file:**
   ```bash
   cp ios/Configuration/ApiKeys.xcconfig.example ios/Configuration/ApiKeys.xcconfig
   ```

2. **Edit `ios/Configuration/ApiKeys.xcconfig` with your actual values:**
   ```xcconfig
   // Google Maps Configuration
   GOOGLE_MAPS_API_KEY_IOS = your_actual_ios_key
   GOOGLE_MAPS_MAP_ID_IOS = your_actual_ios_map_id
   ```

## 🔑 API Keys Management

### Google Maps API Keys

1. **Get your API keys from Google Cloud Console:**
   - Visit: https://console.cloud.google.com/
   - Create a new project or select existing one
   - Enable Google Maps API
   - Create credentials (API Key)
   - Restrict the API key to your app's package name

2. **Security Best Practices:**
   - ✅ Restrict API keys to specific apps
   - ✅ Set usage quotas and limits
   - ✅ Monitor API key usage
   - ✅ Rotate keys regularly
   - ✅ Use different keys for different environments

### API Key Restrictions

**For Android:**
- Package name: `com.yourcompany.stockira`
- SHA-1 certificate fingerprint: (get from your keystore)

**For iOS:**
- Bundle identifier: `com.yourcompany.stockira`
- App Store ID: (if published)

## 🚨 Security Checklist

### Before Committing Code:
- [ ] No `.env` file in repository
- [ ] No `local.properties` file in repository
- [ ] No `ApiKeys.xcconfig` file in repository
- [ ] No hardcoded API keys in source code
- [ ] No passwords or secrets in source code
- [ ] All sensitive files in `.gitignore`

### Before Deploying:
- [ ] Use production API keys
- [ ] Enable API key restrictions
- [ ] Set up monitoring and alerts
- [ ] Test with production environment
- [ ] Verify all environment variables are set

### Regular Security Maintenance:
- [ ] Rotate API keys quarterly
- [ ] Review API key usage monthly
- [ ] Update dependencies regularly
- [ ] Monitor for security vulnerabilities
- [ ] Backup secure configurations

## 🔍 Security Monitoring

### What to Monitor:
- API key usage and quotas
- Unusual API requests
- Failed authentication attempts
- App crashes or errors
- Network traffic patterns

### Tools for Monitoring:
- Google Cloud Console (API usage)
- Firebase Analytics (app usage)
- Crashlytics (error monitoring)
- Custom logging and alerts

## 🆘 Emergency Procedures

### If API Key is Compromised:
1. **Immediately revoke the compromised key**
2. **Generate new API key**
3. **Update all environment files**
4. **Deploy updated app**
5. **Monitor for suspicious activity**

### If Credentials are Exposed:
1. **Remove from Git history** (if recently committed)
2. **Change all affected credentials**
3. **Notify team members**
4. **Review access logs**
5. **Update security procedures**

## 📞 Support & Contacts

### Security Issues:
- Report security vulnerabilities privately
- Contact: security@yourcompany.com
- Use encrypted communication for sensitive issues

### Technical Support:
- Development team: dev@yourcompany.com
- DevOps team: devops@yourcompany.com

## 📚 Additional Resources

- [Google Maps API Security Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Flutter Security Guide](https://docs.flutter.dev/security)
- [Environment Variables Best Practices](https://12factor.net/config)
- [Git Security Best Practices](https://git-scm.com/docs/gitignore)

---

**Remember: Security is everyone's responsibility! 🔐**
