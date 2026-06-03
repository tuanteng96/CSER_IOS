//
//  QrCodeController.swift
//  Cser2022
//
//  Copyright © 2021 High Sierra. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreImage
import PhotosUI

class QrCodeController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var scanOverlay: UIView?
    var scanAreaView: UIView?
    var scanLine: UIView?
    var instructionLabel: UILabel?
    var photoButton: UIButton?
    var overlayAdded = false
    var isSendNotif = false
    @IBOutlet weak var qrCodeView: UIView!
    @IBOutlet weak var btBack: UIImageView!
    @IBOutlet weak var btFlash: UIImageView!
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    @objc func onBack(_ ges: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func choosePhoto() {
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            config.filter = .images
            config.selectionLimit = 1
            config.preferredAssetRepresentationMode = .current

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            picker.modalPresentationStyle = .pageSheet
            self.present(picker, animated: true, completion: nil)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.image"]
            picker.delegate = self
            picker.modalPresentationStyle = .pageSheet
            self.present(picker, animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else { return }
        processPickedImage(image)
    }

    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self, error == nil, let image = object as? UIImage else { return }
                self.processPickedImage(image)
            }
        }
    }

    private func processPickedImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
        let features = detector?.features(in: ciImage) ?? []
        var found = false
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let message = qrFeature.messageString {
                found = true
                if !isSendNotif {
                    isSendNotif = true
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "QRCODE"), object: nil, userInfo: ["code": message])
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
            }
        }

        if !found {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
                let msgFont = UIFont.systemFont(ofSize: 14, weight: .regular)
                let titleColor: UIColor
                let msgColor: UIColor
                if #available(iOS 13.0, *) {
                    titleColor = UIColor.label
                    msgColor = UIColor.secondaryLabel
                } else {
                    titleColor = UIColor.white
                    msgColor = UIColor(white: 0.85, alpha: 1)
                }
                let titleAttr = NSAttributedString(
                    string: "Không tìm thấy mã QR",
                    attributes: [
                        NSAttributedString.Key.paragraphStyle: paragraph,
                        NSAttributedString.Key.font: titleFont,
                        NSAttributedString.Key.foregroundColor: titleColor
                    ]
                )
                let msg = NSAttributedString(
                    string: "Ảnh không chứa mã QR.",
                    attributes: [
                        NSAttributedString.Key.paragraphStyle: paragraph,
                        NSAttributedString.Key.font: msgFont,
                        NSAttributedString.Key.foregroundColor: msgColor
                    ]
                )
                alert.setValue(titleAttr, forKey: "attributedTitle")
                alert.setValue(msg, forKey: "attributedMessage")
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                func centerLabels(in view: UIView) {
                    for sub in view.subviews {
                        if let label = sub as? UILabel {
                            label.textAlignment = .center
                            label.numberOfLines = 0
                        }
                        centerLabels(in: sub)
                    }
                }
                centerLabels(in: alert.view)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func onFlash(_ ges: UITapGestureRecognizer) {
        toggleFlash()
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesBack = UITapGestureRecognizer(target: self, action: #selector(onBack(_:)))
        gesBack.numberOfTapsRequired = 1
        gesBack.numberOfTouchesRequired = 1
        btBack.addGestureRecognizer(gesBack)
        btBack.isUserInteractionEnabled = true
        
        let gesFlash = UITapGestureRecognizer(target: self, action: #selector(onFlash(_:)))
        gesFlash.numberOfTapsRequired = 1
        gesFlash.numberOfTouchesRequired = 1
        btFlash.addGestureRecognizer(gesFlash)
        btFlash.isUserInteractionEnabled = true
        
        view.backgroundColor = .black
        qrCodeView.backgroundColor = .clear

        
        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            // Initialize the video preview layer and add it as a sublayer to the main view layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.insertSublayer(videoPreviewLayer!, at: 0)
            
            // Start video capture
            captureSession.startRunning()
            
            
            // Initialize QR Code Frame to highlight the QR Code
            qrCodeFrameView = UIView()

            if let qrcodeFrameView = qrCodeFrameView {
                qrcodeFrameView.layer.borderColor = UIColor.yellow.cgColor
                qrcodeFrameView.layer.borderWidth = 2
                qrCodeView.addSubview(qrcodeFrameView)
                qrCodeView.bringSubviewToFront(qrcodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue anymore
            print(error)
            return
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.bounds
        if !overlayAdded {
            setupScanOverlay()
        } else {
            updateScanOverlayFrames()
        }
    }

    private func updateScanOverlayFrames() {
        guard let bounds = view?.bounds,
              let overlay = scanOverlay,
              let scanArea = scanAreaView,
              let scanLine = scanLine else { return }

        overlay.frame = bounds
        if let mask = overlay.layer.mask as? CAShapeLayer {
            // prefer a ~300x300 scan area but adapt to smaller screens
            let scanSide = min(300, min(bounds.width, bounds.height) * 0.65)
            let scanRect = CGRect(x: (bounds.width - scanSide) / 2,
                                  y: (bounds.height - scanSide) / 2,
                                  width: scanSide,
                                  height: scanSide)
            let path = UIBezierPath(rect: bounds)
            path.append(UIBezierPath(rect: scanRect).reversing())
            mask.path = path.cgPath
            scanArea.frame = scanRect
            scanLine.frame = CGRect(x: 0, y: 0, width: scanRect.width, height: 2)
            scanLine.layer.removeAnimation(forKey: "scanLine")
            let animation = CABasicAnimation(keyPath: "position.y")
            animation.fromValue = scanLine.layer.position.y
            animation.toValue = scanLine.layer.position.y + scanRect.height - 2
            animation.duration = 2.0
            animation.repeatCount = .infinity
            animation.autoreverses = false
            scanLine.layer.add(animation, forKey: "scanLine")
        }
    }

    private func setupScanOverlay() {
        overlayAdded = true
        guard let bounds = view?.bounds else { return }
        let overlay = UIView(frame: bounds)
        // make overlay a bit darker
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.7)
        overlay.isUserInteractionEnabled = false
        // prefer a ~300x300 scan area but adapt to smaller screens
        let scanSide = min(300, min(bounds.width, bounds.height) * 0.65)
        let scanRect = CGRect(x: (bounds.width - scanSide) / 2,
                              y: (bounds.height - scanSide) / 2,
                              width: scanSide,
                              height: scanSide)
        let path = UIBezierPath(rect: bounds)
        path.append(UIBezierPath(rect: scanRect).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        overlay.layer.mask = mask
        qrCodeView.addSubview(overlay)
        self.scanOverlay = overlay

        let scanArea = UIView(frame: scanRect)
        scanArea.backgroundColor = .clear
        // no full border; we draw only corner markers below
        scanArea.layer.borderWidth = 0
        qrCodeView.addSubview(scanArea)
        self.scanAreaView = scanArea

        let instruction = UILabel()
        instruction.text = "Di chuyển camera đến mã QR để quét hoặc"
        instruction.textColor = .white
        instruction.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        instruction.textAlignment = .center
        instruction.numberOfLines = 2
        instruction.alpha = 0.95
        instruction.translatesAutoresizingMaskIntoConstraints = false
        qrCodeView.addSubview(instruction)
        self.instructionLabel = instruction

        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "photo"), for: .normal)
            button.setTitle("  Chọn từ Thư viện ảnh", for: .normal)
        } else {
            // fallback for older iOS: use emoji in title
            button.setTitle("📷 Chọn từ Thư viện ảnh", for: .normal)
        }
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        // remove background to keep transparent button
        button.backgroundColor = .clear
        button.layer.cornerRadius = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        qrCodeView.addSubview(button)
        self.photoButton = button
        button.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)

        NSLayoutConstraint.activate([
            instruction.centerXAnchor.constraint(equalTo: qrCodeView.centerXAnchor),
            instruction.topAnchor.constraint(equalTo: scanArea.bottomAnchor, constant: 49),
            instruction.leadingAnchor.constraint(greaterThanOrEqualTo: qrCodeView.leadingAnchor, constant: 24),
            instruction.trailingAnchor.constraint(lessThanOrEqualTo: qrCodeView.trailingAnchor, constant: -24),
            button.centerXAnchor.constraint(equalTo: qrCodeView.centerXAnchor),
            button.topAnchor.constraint(equalTo: instruction.bottomAnchor, constant: 12)
        ])

        let cornerLength: CGFloat = 28
        let lineWidth: CGFloat = 4
        let corners: [(CGRect, UIColor)] = [
            (CGRect(x: 0, y: 0, width: cornerLength, height: lineWidth), .white),
            (CGRect(x: 0, y: 0, width: lineWidth, height: cornerLength), .white),
            (CGRect(x: scanRect.width - cornerLength, y: 0, width: cornerLength, height: lineWidth), .white),
            (CGRect(x: scanRect.width - lineWidth, y: 0, width: lineWidth, height: cornerLength), .white),
            (CGRect(x: 0, y: scanRect.height - lineWidth, width: cornerLength, height: lineWidth), .white),
            (CGRect(x: 0, y: scanRect.height - cornerLength, width: lineWidth, height: cornerLength), .white),
            (CGRect(x: scanRect.width - cornerLength, y: scanRect.height - lineWidth, width: cornerLength, height: lineWidth), .white),
            (CGRect(x: scanRect.width - lineWidth, y: scanRect.height - cornerLength, width: lineWidth, height: cornerLength), .white)
        ]
        for (frame, color) in corners {
            let corner = UIView(frame: frame)
            corner.backgroundColor = color
            corner.layer.cornerRadius = 2
            corner.layer.masksToBounds = true
            scanArea.addSubview(corner)
        }

        let line = UIView(frame: CGRect(x: 0, y: 0, width: scanRect.width, height: 2))
        line.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        scanArea.addSubview(line)
        self.scanLine = line

        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = line.layer.position.y
        animation.toValue = line.layer.position.y + scanRect.height - 2
        animation.duration = 2.0
        animation.repeatCount = .infinity
        animation.autoreverses = false
        line.layer.add(animation, forKey: "scanLine")

        
    }
}

extension QrCodeController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
//            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if let code = metadataObj.stringValue {
                if (!isSendNotif) {
                    isSendNotif = true
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "QRCODE") , object: nil, userInfo: ["code" : code])
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
