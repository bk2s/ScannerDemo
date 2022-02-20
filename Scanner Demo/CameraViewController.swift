//
//  ViewController.swift
//  Scanner Demo
//
//  Created by  Stepanok Ivan on 19.02.2022.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    // MARK: - Properties
    private var bag = DisposeBag()
    private var captureSession: AVCaptureSession!
    private var backCamera : AVCaptureDevice!
    private var backInput : AVCaptureInput!
    private var previewLayer : AVCaptureVideoPreviewLayer!
    private var capturePhotoOutput : AVCapturePhotoOutput!
    private var capturedImage: UIImage?

    // MARK: - Outlets
    @IBOutlet weak var rectangleImage: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.delegate = self
        self.setupAndStartCaptureSession()
        self.setupButton()
    }
    
    // MARK: - Methods
    private func setupButton() {
        self.cameraButton.rx.tap.asDriver(onErrorDriveWith: .empty()).drive(onNext: {
            guard let capturePhotoOutput = self.capturePhotoOutput else { return }
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        }).disposed(by: bag)
    }
    
    // MARK: - Camera Methods
    private func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .high
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            self.setupInputs()
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
            self.setupOutput()
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    private func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, at: 1)
        view.bringSubviewToFront(bottomView)
        view.bringSubviewToFront(rectangleImage)
        previewLayer.frame = self.view.layer.frame
    }
    
    private func setupInputs(){
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            fatalError("no back camera")
        }
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        captureSession.addInput(backInput)
    }
    
    private func setupOutput(){
        capturePhotoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(capturePhotoOutput) {
            captureSession.addOutput(capturePhotoOutput)
        } else {
            fatalError("could not add video output")
        }
        capturePhotoOutput.connections.first?.videoOrientation = .portrait
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let image = photo.cgImageRepresentation() {
            let rotatedImage = UIImage(cgImage: image, scale: 1.0, orientation: .left)
            let newViewController = FilterViewController(image: rotatedImage)
        present(newViewController, animated: true)
        }
    }

}

