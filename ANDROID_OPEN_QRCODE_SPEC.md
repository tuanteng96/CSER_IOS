# OPEN_QRCODE Feature Specification - Android Implementation

## Overview
Implement `OPEN_QRCODE` command for Android to match iOS functionality. This feature provides a complete QR code scanning solution with fallback image picker for decoding QR codes from photos.

## Feature Scope

### 1. **QR Code Scanning (Primary Method)**
- Real-time QR code detection using device camera
- Support for multiple barcode formats (QR, Code39, Code128, EAN8, EAN13, PDF417, Data Matrix, etc.)
- Live camera preview with:
  - Yellow border highlight on detected QR codes
  - Flash toggle button (on/off)
  - Back/close button
  - Performance optimized for quick detection

### 2. **Photo Picker Fallback (Secondary Method)**
- Allow users to pick images from gallery when camera is unavailable
- Decode QR codes from selected images using modern Android APIs
- Show user-friendly error alerts when no QR code found in image
- Support both older `Intent.ACTION_PICK` and modern `PhotoPicker` APIs (Android 13+)

### 3. **Result Callback Mechanism**
- When QR code is detected (camera or image picker):
  1. Close QR scanner view
  2. Send result back to JavaScript via `App21Result` callback
  3. Include detected QR code data in result JSON

---

## iOS Implementation Reference

### App21.swift - OPEN_QRCODE Command
```swift
@objc func OPEN_QRCODE(result: Result) -> Void {
    self.caller.qrCodeResult = result
    DispatchQueue.main.async {
        self.caller.show(self.caller.storyboard!.instantiateViewController(withIdentifier: "QrCodeController"), sender: self)
    }
}
```

### QrCodeController.swift - Key Features
1. **Camera Setup**: Uses `AVCaptureSession` with metadata output for QR detection
2. **Supported Formats**:
   - UPC-E, Code39, Code39Mod43, Code93
   - Code128, EAN8, EAN13
   - Aztec, PDF417, ITF14, Data Matrix
   - Interleaved 2of5, QR Code

3. **Scan Overlay UI**:
   - Video preview layer with QR frame highlighting
   - Yellow border (2pt width) around detected codes
   - Back button (top-left)
   - Flash toggle button (top-right)

4. **Image Picker Integration**:
   - iOS 14+: `PHPickerViewController` (modal, fast, non-blocking)
   - Older iOS: `UIImagePickerController` fallback
   - Image processing: Extract QR data using `CIDetector` with high accuracy

5. **Result Broadcasting**:
   - Posts notification: `NSNotification.Name("QRCODE")`
   - Data: `["code": <detected_qr_string>]`
   - Dismisses UI automatically

6. **Error Handling**:
   - No QR found in image: Show alert dialog
   - Camera unavailable: Graceful degradation
   - Permission denied: Handled at framework level

---

## Android Implementation Requirements

### Technology Stack
- **Barcode Scanning**: ML Kit (Google) or ZXing library
  - Recommended: ML Kit Vision for native performance
  - Fallback: ZXing for broader format support
- **Camera**: `CameraX` library (modern, lifecycle-aware)
- **Photo Picker**: `PhotoPicker` (API 33+) or `ACTION_PICK` fallback
- **UI Framework**: Fragment-based or Activity-based (consistent with app architecture)

### Module Structure
1. **QrCodeFragment/QrCodeActivity**
   - Real-time QR scanning UI
   - Camera permission handling
   - Result dispatch

2. **CameraManager**
   - Handle camera lifecycle
   - Barcode detection setup
   - Error recovery

3. **ImageQRDecoder**
   - Decode QR from gallery images
   - Error alerts

---

## Functional Specifications

### Command Interface
**Function**: `OPEN_QRCODE`
**JavaScript Call**:
```javascript
app.call({
    sub_cmd: "OPEN_QRCODE",
    sub_cmd_id: <unique_id>,
    params: "" // empty or optional config
});
```

### Result Format
**Success Case** (QR found):
```json
{
    "success": true,
    "error": "",
    "data": "<detected_qr_code_value>",
    "sub_cmd": "OPEN_QRCODE",
    "sub_cmd_id": <unique_id>,
    "params": ""
}
```

**Cancel Case** (user closed without scanning):
```json
{
    "success": false,
    "error": "CANCELLED",
    "data": "",
    "sub_cmd": "OPEN_QRCODE",
    "sub_cmd_id": <unique_id>,
    "params": ""
}
```

**Error Case** (camera unavailable):
```json
{
    "success": false,
    "error": "CAMERA_UNAVAILABLE",
    "data": "",
    "sub_cmd": "OPEN_QRCODE",
    "sub_cmd_id": <unique_id>,
    "params": ""
}
```

---

## UI/UX Requirements

### QR Scanner Screen
- **Layout**:
  - Full-screen camera preview (black background)
  - Yellow highlight frame on detected QR code (2-3dp stroke width)
  - Top left: Back/close button (icon)
  - Top right: Flash toggle button (icon)
  - Optional: Scan line animation (subtle vertical line)

- **Behavior**:
  - Auto-detect barcode formats continuously
  - Display on detection (yellow border)
  - Vibration feedback (optional, ~50ms)
  - Automatic close after detection + 300ms delay
  
### Photo Picker Button
- Add gallery/photo picker button to scanner UI
- When photo selected:
  1. Parse QR from image using ML Kit / ZXing
  2. If found: return result and close
  3. If not found: show alert "QR code not found in image"
  4. Alert action: "OK" → return to scanner

### Alerts & Messages
- **No QR in Image**: 
  - Title: "Không tìm thấy mã QR"
  - Message: "Ảnh không chứa mã QR."
  - Button: "OK"
  
- **Camera Permission Denied**:
  - Title: "Quyền truy cập camera bị từ chối"
  - Message: "Vui lòng cấp quyền camera để quét mã QR."
  - Buttons: "Settings" (open app settings), "Cancel"

- **Camera Unavailable**:
  - Title: "Camera không khả dụng"
  - Message: "Thiết bị không có camera hoặc camera bị chiếm dụng."
  - Button: "OK"

---

## Performance Optimization

### Camera & Detection
- Use ML Kit for faster, hardware-accelerated detection
- Reduce frame processing: analyze every 2nd/3rd frame (tuneable)
- Dim preview if needed for battery (optional)
- Support landscape + portrait orientations

### Photo Picker
- Use non-blocking image loading for older Android versions
- Cache picker configuration if filtering available
- Optimize image size before barcode detection (resize to ~1920x1080)

### Permission Handling
- Request `CAMERA` + `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES`
- Use `Activity`/`Fragment` result contracts for permission flow
- Graceful degradation if permissions denied

---

## Implementation Checklist

- [ ] Create QrCodeActivity/QrCodeFragment with camera setup
- [ ] Integrate ML Kit Vision (or ZXing) for barcode detection
- [ ] Implement camera permission requests (runtime)
- [ ] Add photo picker with API 33+ PhotoPicker support
- [ ] Implement QR detection from selected images
- [ ] Add UI elements: back button, flash toggle, scan overlay
- [ ] Add result callback: return to App21 via `app_response` bridge
- [ ] Add vibration feedback on successful scan
- [ ] Implement error alerts with Vietnamese localization
- [ ] Test camera lifecycle on app pause/resume
- [ ] Test permission denial scenarios
- [ ] Optimize frame processing for responsiveness

---

## Bridge Integration

### Android App21 / CommandHandler
```
// Pseudo-code
class App21Handler {
    fun handleOPEN_QRCODE(result: Result) {
        val intent = Intent(context, QrCodeActivity::class.java)
        intent.putExtra("requestId", result.sub_cmd_id)
        activity.startActivityForResult(intent, REQUEST_QR_CODE)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
        if (requestCode == REQUEST_QR_CODE && resultCode == RESULT_OK) {
            val qrCode = data.getStringExtra("qrCode")
            val result = Result(success = true, data = qrCode)
            sendResultToJS(result)
        }
    }
}
```

### JavaScript Callback
```javascript
// WebView receives result via evalJs:
// app_response('OPEN_QRCODE', 'BASE64:<encoded_result>')

function handleQRResult(base64Data) {
    const jsonStr = atob(base64Data);
    const result = JSON.parse(jsonStr);
    console.log('QR Code:', result.data);
}
```

---

## Reference Materials

- **ML Kit Barcode Detection**: https://developers.google.com/ml-kit/vision/barcode-scanning
- **CameraX**: https://developer.android.com/training/camerax
- **PhotoPicker**: https://developer.android.com/about/versions/13/features/photopicker
- **ZXing Library**: https://github.com/zxing/zxing (fallback)

---

## Testing Scenarios

1. ✓ User opens QR scanner, points at QR code → detects, returns result
2. ✓ User cancels by pressing back → returns error "CANCELLED"
3. ✓ User selects image from gallery with QR → detects, returns result
4. ✓ User selects image without QR → shows alert, return to scanner
5. ✓ App is paused while scanning → resume, continue scanning
6. ✓ Camera permission denied → show alert, no crash
7. ✓ Multiple barcode formats detected correctly

---

## Notes
- Maintain parity with iOS implementation for user experience
- Vietnamese UI text (titles, messages) as referenced in iOS alerts
- Ensure fast QR detection (<500ms typical, <1s max)
- Test on devices with/without camera
