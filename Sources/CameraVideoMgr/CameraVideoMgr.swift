import AVFoundation
import UIKit

public protocol CameraVideoMgrDelegate {
    func captureOutput(ciimg: CIImage)
}

// 
public enum CameraType: Int {
    case video = 0
    case photo = 1
}

// Camera Video Mgr
public class CameraVideoMgr: NSObject {
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQ",
                                                     qos: .userInitiated,
                                                     attributes: [],
                                                     autoreleaseFrequency: .workItem)
    public private(set) var session = AVCaptureSession()
    //private(set) var videoWidth = 0
    //private(set) var videoHeight = 0

    public var delegate: CameraVideoMgrDelegate?
    
    
    /// Create a camera with a specific type.
    /// - Parameter type: Choose video for auto-capture, for photo .photo.
    public init(type: CameraType = .video) {
        super.init()
        setupAVCapture()
    }
    
    private func setupAVCapture() {
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: .video,
                                                           position: .back).devices.first
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice!) else { return }
        
        // capture session setup
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        // Input device specification
        session.addInput(videoInput)
        
        // Output destination setting
        session.addOutput(videoDataOutput)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        
        //// Get video image size
        //try? videoDevice!.lockForConfiguration()
        //let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
        //videoWidth = Int(dimensions.width)
        //videoHeight = Int(dimensions.height)
        //videoDevice!.unlockForConfiguration()
        
        session.commitConfiguration()
    }
}

extension CameraVideoMgr: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pbuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Rotate clockwise to change orientation vertically
        let ciimage = CIImage(cvPixelBuffer: pbuf).oriented(.right)
        delegate?.captureOutput(ciimg: ciimage)
    }
}
