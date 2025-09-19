# Store Mapping UI Debug Guide

## 🔧 **Perbaikan Render UI yang Telah Dilakukan**

### ✅ **1. Debug Info yang Selalu Tampil**
- **Areas Debug Box:** Selalu menampilkan status loading/success dengan warna yang berbeda
- **Sub Areas Debug Box:** Menampilkan status loading sub areas ketika area dipilih
- **Available Stores Debug Box:** Menampilkan status loading stores ketika sub area dipilih

### ✅ **2. Dropdown Improvements**
- **Area Dropdown:** 
  - Menampilkan ID dan nama area (format: "1 - RIAU")
  - Loading indicator di suffix icon
  - Hint text yang dinamis
- **Sub Area Dropdown:**
  - Menampilkan ID dan nama sub area (format: "2 - RIAU")
  - Loading indicator di suffix icon
  - Hint text yang dinamis berdasarkan state

### ✅ **3. Enhanced Logging**
- Console logs untuk setiap step:
  - Area selection
  - Sub area selection
  - Available stores loading
  - API responses

## 🎯 **Expected Behavior Setelah Perbaikan**

### **Step 1: Buka Bottomsheet**
```
🟠 Orange Box: "Loading areas... 0 loaded"
🔄 Area Dropdown: "Loading areas..." dengan loading spinner
```

### **Step 2: Areas Loaded**
```
🟢 Green Box: "Areas loaded: 10 areas available"
📋 Area Dropdown: "Pilih area terlebih dahulu" (dropdown enabled)
```

### **Step 3: Pilih Area (contoh: RIAU)**
```
🔵 Blue Box: "Loading sub areas for RIAU... 0 loaded"
🔄 Sub Area Dropdown: "Loading sub areas..." dengan loading spinner
```

### **Step 4: Sub Areas Loaded**
```
🟢 Green Box: "Sub areas loaded: 1 sub areas for RIAU"
📋 Sub Area Dropdown: "Pilih sub area" (dropdown enabled)
```

### **Step 5: Pilih Sub Area**
```
🟣 Purple Box: "Loading stores for RIAU... 0 loaded"
```

### **Step 6: Stores Loaded**
```
🟢 Green Box: "Stores loaded: X stores available for RIAU"
📋 Store tabs muncul dengan data
```

## 🔍 **Debug Information yang Ditampilkan**

### **Console Logs:**
```
Loading areas...
Areas response: 10 areas loaded
Areas loaded: 1: RIAU, 2: CILEGON, 3: SUMEDANG, ...

Area selected: 1 - RIAU
Loading sub areas for area ID: 1
Sub areas response: 1 sub areas loaded
Sub areas loaded: 2: RIAU

Sub area selected: 2 - RIAU
Loading available stores for sub area ID: 2
Available stores response: X stores loaded
Available stores loaded: 6: alfa kepatihan rakh, 8: INDOMARET RAYA GLAGAH, ...
```

### **UI Debug Boxes:**
- **Orange/Green:** Areas status
- **Blue/Green:** Sub areas status  
- **Purple/Green:** Available stores status

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Areas Tidak Muncul**
**Symptoms:** Orange box tetap muncul, dropdown kosong
**Solutions:**
1. Check console logs untuk API call
2. Verify token authentication
3. Check network connection
4. Tap "Refresh" button

### **Issue 2: Sub Areas Tidak Muncul**
**Symptoms:** Blue box tetap muncul setelah pilih area
**Solutions:**
1. Check console logs untuk sub areas API call
2. Verify area ID yang dipilih
3. Check API response format

### **Issue 3: Stores Tidak Muncul**
**Symptoms:** Purple box tetap muncul setelah pilih sub area
**Solutions:**
1. Check console logs untuk stores API call
2. Verify sub area ID yang dipilih
3. Check API response format

## 📱 **Testing Steps**

### **Test 1: Areas Loading**
1. Buka bottomsheet
2. Lihat orange debug box
3. Tunggu hingga berubah hijau
4. Verify dropdown area terisi

### **Test 2: Sub Areas Loading**
1. Pilih area dari dropdown
2. Lihat blue debug box
3. Tunggu hingga berubah hijau
4. Verify dropdown sub area terisi

### **Test 3: Stores Loading**
1. Pilih sub area dari dropdown
2. Lihat purple debug box
3. Tunggu hingga berubah hijau
4. Verify store tabs muncul

## 🎨 **Visual Indicators**

### **Color Coding:**
- 🟠 **Orange:** Loading/Error state
- 🟢 **Green:** Success/Loaded state
- 🔵 **Blue:** Sub areas loading
- 🟣 **Purple:** Stores loading

### **Icons:**
- ℹ️ **info_outline:** Loading state
- ✅ **check_circle:** Success state
- 🔄 **CircularProgressIndicator:** Loading spinner

## 🔧 **API Endpoints yang Digunakan**

### **Areas API:**
```
GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/areas?search
Response: {"success": true, "data": [{"id": 1, "name": "RIAU", "code": null}, ...]}
```

### **Sub Areas API:**
```
GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/sub-areas?area_id=1
Response: {"success": true, "data": [{"id": 2, "name": "RIAU", "area": {...}}, ...]}
```

### **Stores API:**
```
GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/stores?conditions[sub_area_id]=2
Response: {"success": true, "data": [{"id": 6, "name": "alfa kepatihan rakh", ...}, ...]}
```

## 🚀 **Next Steps**

1. **Test the app** dengan perbaikan ini
2. **Check console logs** untuk setiap step
3. **Verify UI debug boxes** menampilkan status yang benar
4. **Test dropdown functionality** step by step
5. **Report any remaining issues** dengan detail yang spesifik

Dengan perbaikan ini, UI seharusnya menampilkan status loading yang jelas dan dropdown yang berfungsi dengan baik! 🎉
