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
            NRVideoCompressor.compressVideoWithQuality(presetName: AVAssetExportPresetMediumQuality, inputURL: originalVideoUrl!, completionHandler: { (outputUrl) in
                self.originalVideoUrl = nil
                self.originalVideoSize.text = "0 MB"
                let compressSize = NSData(contentsOf: outputUrl as URL)
                let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((compressSize?.length)!), countStyle: .file)
                self.newVideoSize.text = "compress size1 \(sizeinMB)"
                self.compressUrl = outputUrl
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    NRVideoCompressor.compressVideoWithQuality2(presetName: AVAssetExportPresetMediumQuality, inputURL: outputUrl, completionHandler: { (outputUrl2) in
//                        self.originalVideoUrl = nil
//                        self.originalVideoSize.text = "0 MB"
//                        let compressSize = NSData(contentsOf: outputUrl2 as URL)
//                        let sizeinMB = ByteCountFormatter.string(fromByteCount: Int64((compressSize?.length)!), countStyle: .file)
//                        self.newVideoSize.text = "compress size2 \(sizeinMB)"
//                        
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            self.moviePlayer = MPMoviePlayerController(contentURL: outputUrl2 as URL?)
//                            self.moviePlayer.view.frame = CGRect(x: 20, y: 100, width: 200, height: 150)
//                            
//                            self.view.addSubview(self.moviePlayer.view)
//                            self.moviePlayer.isFullscreen = true
//                            
//                            self.moviePlayer.controlStyle = MPMovieControlStyle.embedded
//                            
//                        }
//                    })
//                }
                
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
    
}

