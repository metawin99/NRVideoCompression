//
//  ViewController.swift
//  NRVideoCompression
//
//  Created by naveenrana1309 on 10/24/2016.
//  Copyright (c) 2016 naveenrana1309. All rights reserved.
//

import UIKit
import MobileCoreServices
import NRVideoCompression
import AVFoundation
import MediaPlayer

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var originalVideoSize: UILabel!
    @IBOutlet weak var newVideoSize: UILabel!
    var selector = ""
    
    var originalVideoUrl: NSURL?
    var compressUrl: NSURL?
    var moviePlayer:MPMoviePlayerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        let actionSheetController = UIAlertController(title: "Select upload type", message: "", preferredStyle: .actionSheet)
        let takePhotoActionButton = UIAlertAction(title: "Take photo", style: .default) { action -> Void in
            picker.sourceType = .camera
            self.present(picker, animated: true, completion:nil)
            self.selector = "camera"
        }
        let libActionButton = UIAlertAction(title: "Lib", style: .default) { action -> Void in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion:nil)
            self.selector = "photo"
        }
        let videoActionButton = UIAlertAction(title: "Video", style: .default) { action -> Void in
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            self.present(picker, animated: true, completion:nil)
            self.selector = "video"
        }
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        
        actionSheetController.addAction(takePhotoActionButton)
        actionSheetController.addAction(libActionButton)
        actionSheetController.addAction(videoActionButton)
        actionSheetController.addAction(cancelActionButton)
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    //MARK: UIImagePickerController Delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        self.originalVideoUrl = info[UIImagePickerControllerMediaURL] as? NSURL

        let originalSize = NSData(contentsOf: originalVideoUrl! as URL)
        let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((originalSize?.length)!), countStyle: .file)
        self.originalVideoSize.text = "original size\(sizeinMB)"

//        compressFile(urlToCompress: self.originalVideoUrl! as URL, outputURL: self.originalVideoUrl! as URL) { (urlResult) in
//            print("output", urlResult)
//            let compressSize = NSData(contentsOf: urlResult as URL)
//            let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((compressSize?.length)!), countStyle: .file)
//            self.newVideoSize.text = "compress size1 \(sizeinMB)"
//            self.compressUrl = urlResult as NSURL
//        }
        
        
        if let _ = originalVideoUrl {
            if FileManager.default.fileExists(atPath: self.originalVideoUrl!.absoluteString!) {
                try! FileManager.default.removeItem(at: self.originalVideoUrl! as URL)
            }

            let originalSize = NSData(contentsOf: originalVideoUrl! as URL)
            let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((originalSize?.length)!), countStyle: .file)
            self.originalVideoSize.text = "original size\(sizeinMB)"
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectVideoButtonClicked(_ sender: Any) {
        openImagePicker()
    }
    
    @IBAction func compressButtonClicked(_ sender: Any) {
        if let _ = self.originalVideoUrl {
            self.originalVideoSize.text = "Loading"
            //AVAssetExportPresetLowQuality
            //AVAssetExportPresetMediumQuality
            //AVAssetExportPresetHighestQuality
            NRVideoCompressor.compressVideoWithQuality(presetName: AVAssetExportPreset1280x720, inputURL: originalVideoUrl!, completionHandler: { (outputUrl) in
                self.originalVideoUrl = nil
                self.originalVideoSize.text = "0 MB"
                let compressSize = NSData(contentsOf: outputUrl as URL)
                let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((compressSize?.length)!), countStyle: .file)
                self.newVideoSize.text = "compress size1 \(sizeinMB)"
                self.compressUrl = outputUrl
            })
        }
    }
    
    
    @IBAction func playVideo(_ sender: Any) {
        if let url = compressUrl {
            self.moviePlayer = MPMoviePlayerController(contentURL: url as URL?)
            
            let screenSize = UIScreen.main.bounds
            let screenWidth = screenSize.width
            
            self.moviePlayer.view.frame = CGRect(x: screenWidth / 2 - 100, y: 250, width: 200, height: 200)
            
            self.view.addSubview(self.moviePlayer.view)
            self.moviePlayer.isFullscreen = true
            
            self.moviePlayer.controlStyle = MPMovieControlStyle.embedded
        }
    }
    
    
    
    var assetWriter:AVAssetWriter?
    var assetReader:AVAssetReader?
    
    let bitrate:NSNumber = NSNumber(value:1)
//    let bitrate:NSNumber = NSNumber(value:250000)
    
    func compressFile(urlToCompress: URL, outputURL: URL, completion:@escaping (URL)->Void){
        var audioFinished = false
        var videoFinished = false

        let asset = AVAsset(url: urlToCompress);

        do{
            assetReader = try AVAssetReader(asset: asset)
        } catch{
            assetReader = nil
        }
        
        guard let reader = assetReader else{
            fatalError("Could not initalize asset reader probably failed its try catch")
        }
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
        
        let videoReaderSettings: [String:Any] =  [(kCVPixelBufferPixelFormatTypeKey as String?)!:kCVPixelFormatType_32ARGB ]
        
        // ADJUST BIT RATE OF VIDEO HERE
        //AVVideoCodecH264
        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:self.bitrate],
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoHeightKey: videoTrack.naturalSize.height * 0.50,
            AVVideoWidthKey: videoTrack.naturalSize.width * 0.50
        ]
        
        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
        
        if reader.canAdd(assetReaderVideoOutput){
            reader.add(assetReaderVideoOutput)
        } else {
            fatalError("Couldn't add video output reader")
        }
        
        if reader.canAdd(assetReaderAudioOutput){
            reader.add(assetReaderAudioOutput)
        } else {
            fatalError("Couldn't add audio output reader")
        }
        
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: kUTTypeQuickTimeMovie as AVFileType)
        } catch {
            assetWriter = nil
        }
        guard let writer = assetWriter else{
            fatalError("assetWriter was nil")
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: kCMTimeZero)
        
        let closeWriter:()->Void = {
            if (audioFinished && videoFinished){
                self.assetWriter?.finishWriting(completionHandler: {
                    
                    self.checkFileSize(sizeUrl: (self.assetWriter?.outputURL)!, message: "The file size of the compressed file is: ")
                    
                    completion((self.assetWriter?.outputURL)!)
                    
                })
                
                self.assetReader?.cancelReading()
                
            }
        }
        
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData){
                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
                if (sample != nil){
                    audioInput.append(sample!)
                }else{
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
        
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            //request data here
            
            while(videoInput.isReadyForMoreMediaData){
                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
                if (sample != nil){
                    videoInput.append(sample!)
                }else{
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
            
        }
    }
    
    func checkFileSize(sizeUrl: URL, message:String){
        let data = NSData(contentsOf: sizeUrl)!
        print(message, (Double(data.length) / 1048576.0), " mb")
    }
    
}

