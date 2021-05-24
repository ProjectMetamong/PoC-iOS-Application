//
//  ExerciseCamViewController.swift
//  PoC UIKit
//
//  Created by Seunghun Yang on 2021/05/23.
//

import UIKit
import AVKit
import SnapKit
import Vision

class ExerciseCamViewController: UIViewController {
    
    // MARK: - Properties
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    
    private var pointsPath = UIBezierPath()
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
    
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return session }
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return session }
        guard session.canAddInput(deviceInput) else { return session }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        guard session.canAddOutput(dataOutput) else { return session }
        session.addOutput(dataOutput)
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    
        session.commitConfiguration()
        
        return session
    }()
    
    lazy var captureLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer()
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        layer.session = self.captureSession
        self.captureSession.startRunning()
        return layer
    }()
    
    lazy var overlayLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = view.bounds
        layer.lineWidth = 5
        layer.fillColor = #colorLiteral(red: 0, green: 0.9810667634, blue: 0.5736914277, alpha: 1)
        layer.lineCap = .round
        layer.contentsGravity = .resizeAspectFill
        return layer
    }()
    
    lazy var stopButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.layer.cornerRadius = cornerRadius
        button.backgroundColor = .red
        button.setTitle("종료", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        button.addTarget(self, action: #selector(self.handleStopButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var progressBar: UISlider = {
        let slider = UISlider()
        slider.setThumbImage(UIImage(), for: .normal)
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .white
        slider.value = 0
        return slider
    }()
    
    var scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "85점"
        label.font = UIFont.italicSystemFont(ofSize: 60)
        label.textColor = .white
        return label
    }()
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        self.view.layer.addSublayer(captureLayer)
        self.view.layer.addSublayer(overlayLayer)
        self.view.addSubview(self.stopButton)
        self.view.addSubview(self.progressBar)
        self.view.addSubview(self.scoreLabel)
        
        self.stopButton.snp.makeConstraints {
            $0.right.equalTo(self.view.snp.right).offset(-15)
            $0.bottom.equalTo(self.view.snp.bottom).offset(-30)
            $0.height.equalTo(50)
            $0.width.equalTo(100)
        }
        
        self.progressBar.snp.makeConstraints {
            $0.top.equalTo(self.view.snp.topMargin).offset(15)
            $0.left.equalTo(self.view.snp.left).offset(15)
            $0.right.equalTo(self.view.snp.right).offset(-15)
        }
        
        self.scoreLabel.snp.makeConstraints {
            $0.bottom.equalTo(self.stopButton.snp.top).offset(-15)
            $0.right.equalTo(self.view.snp.right).offset(-15)
        }
    }
    
    // MARK: - Actions
    
    @objc func handleStopButtonTapped() {
        self.navigationController?.popToViewController(ofClass: DetailViewController.self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ExerciseCamViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([bodyPoseRequest])
            guard let observation = bodyPoseRequest.results?.first else {
                return
            }
            let observedBody = Skeleton(observed: observation, delegate: self)
            DispatchQueue.main.sync {
                observedBody.showSkeleton(for: self.captureLayer, on: self.overlayLayer)
            }
            return
        } catch {
            captureSession.stopRunning()
            return
        }
    }
}

extension ExerciseCamViewController: SkeletonDelegate {
    func showBodyPoints(points: [CGPoint]) {
        self.pointsPath.removeAllPoints()
        for point in points {
            let path = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 10, height: 10))
            self.pointsPath.append(path)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
    }
}


class Skeleton {
    var leftAnkle: CGPoint?
    var leftKnee: CGPoint?
    var leftHip: CGPoint?
    var leftShoulder: CGPoint?
    var leftElbow: CGPoint?
    var leftWrist: CGPoint?
    var leftEye: CGPoint?
    var leftEar: CGPoint?
    var rightAnkle: CGPoint?
    var rightKnee: CGPoint?
    var rightHip: CGPoint?
    var rightShoulder: CGPoint?
    var rightElbow: CGPoint?
    var rightWrist: CGPoint?
    var rightEye: CGPoint?
    var rightEar: CGPoint?
    var nose: CGPoint?
    var delegate: SkeletonDelegate
    
    init(observed body: VNHumanBodyPoseObservation, delegate: SkeletonDelegate) {
        self.delegate = delegate
        do {
            self.leftAnkle = try body.recognizedPoint(.leftAnkle).toCGPoint()
            self.leftKnee = try body.recognizedPoint(.leftKnee).toCGPoint()
            self.leftHip = try body.recognizedPoint(.leftHip).toCGPoint()
            self.leftShoulder = try body.recognizedPoint(.leftShoulder).toCGPoint()
            self.leftElbow = try body.recognizedPoint(.leftElbow).toCGPoint()
            self.leftWrist = try body.recognizedPoint(.leftWrist).toCGPoint()
            self.leftEye = try body.recognizedPoint(.leftEye).toCGPoint()
            self.leftEar = try body.recognizedPoint(.leftEar).toCGPoint()
            self.rightAnkle = try body.recognizedPoint(.rightAnkle).toCGPoint()
            self.rightKnee = try body.recognizedPoint(.rightKnee).toCGPoint()
            self.rightHip = try body.recognizedPoint(.rightHip).toCGPoint()
            self.rightShoulder = try body.recognizedPoint(.rightShoulder).toCGPoint()
            self.rightElbow = try body.recognizedPoint(.rightElbow).toCGPoint()
            self.rightWrist = try body.recognizedPoint(.rightWrist).toCGPoint()
            self.rightEye = try body.recognizedPoint(.rightEye).toCGPoint()
            self.rightEar = try body.recognizedPoint(.rightEar).toCGPoint()
            self.nose = try body.recognizedPoint(.nose).toCGPoint()
        } catch {
            print("??")
        }
    }
    
    func showSkeleton(for captureLayer: AVCaptureVideoPreviewLayer, on overlayLayer: CAShapeLayer) {
        var bodyPoints: [CGPoint] = []
        
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftAnkle!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftKnee!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftHip!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftShoulder!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftElbow!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftWrist!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftEye!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.leftEar!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightAnkle!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightKnee!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightHip!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightShoulder!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightElbow!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightWrist!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightEye!))
        bodyPoints.append(captureLayer.layerPointConverted(fromCaptureDevicePoint: self.rightEar!))
        
        self.delegate.showBodyPoints(points: bodyPoints)
    }
}

protocol SkeletonDelegate {
    func showBodyPoints(points: [CGPoint])
}

extension VNRecognizedPoint {
    func toCGPoint() -> CGPoint {
        return CGPoint(x: self.location.x, y: 1 - self.location.y)
    }
}
