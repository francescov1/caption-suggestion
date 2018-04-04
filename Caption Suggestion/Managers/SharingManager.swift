//
//  SharingManager.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-04-04.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import Foundation
import UIKit
import FBSDKShareKit

class SharingManager {
    class var sharedManager: SharingManager {
        struct Singleton {
            static let instance = SharingManager()
        }
        return Singleton.instance
    }
    
    // Facebook
    
    // TODO: Add caption to post
    func shareToFacebook(image: UIImage, caption: String) {
        guard let photo = FBSDKSharePhoto(image: image, userGenerated: true) else {
            AlertManager.sharedManager.alertUser(title: "Error Sending Data to Facebook", message: "Ensure you have the Facebook app installed and try again", completion: nil)
            return
        }
        
        photo.caption = caption
        let content = FBSDKSharePhotoContent()
        content.photos = [photo]
        
        guard let topVC = UIApplication.topViewController() else {
            AlertManager.sharedManager.alertUser(title: "Error opening Instagram", message: "Sorry! We're working on fixing this. Please try again.", completion: nil)
            return
        }
        
        FBSDKShareDialog.show(from: topVC, with: content, delegate: nil)
    }
    
    
    // Instagram
    
    func documentControllerInstagramPost(image: UIImage, caption: String) {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let checkValidation = FileManager.default
        let getImagePath = paths.appending("/image.igo")
        do {
            try checkValidation.removeItem(atPath: getImagePath)
            let imageData =  UIImageJPEGRepresentation(image, 1.0)
            try imageData?.write(to: URL(fileURLWithPath: getImagePath), options: .atomicWrite)
        }
        catch let error {
            print("error with checkValidation or imageData write:\n \(error)")
            return
        }
        let imageUrl = URL(fileURLWithPath: getImagePath)
        let documentController = UIDocumentInteractionController(url: imageUrl)
        documentController.uti = "com.instagram.exclusivegram"
        
        guard let topVC = UIApplication.topViewController() else {
            AlertManager.sharedManager.alertUser(title: "Error opening Instagram", message: "Sorry! We're working on fixing this. Please try again.", completion: nil)
            return
        }
        
        documentController.annotation = ["InstagramCaption": caption]
        
        // topVC.present(documentController, animated: true, completion: nil)
        documentController.presentOptionsMenu(from: topVC.view.frame, in: topVC.view, animated: true)
    }
    
    /*
    func openInstagram() {
        if let instagramURL = URL(string: "instagram://app") {
            if UIApplication.shared.canOpenURL(instagramURL) {
                UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil)
            }
        }
        /*if UIApplication.shared.canOpenURL(instagramURL!) {
         UIApplication.shared.open(instagramURL, options: nil, completionHandler: nil)
         }*/
        //NSURL *instagramURL = [NSURL URLWithString:@"instagram://location?id=1"];
    }

    
    func postImageToInstagramWithCaption(imageData: Data, instagramCaption: String, barButton: UIBarButtonItem) {
        let kInstagramURL = "instagram://app"
        let kUTI = "com.instagram.exclusivegram"
        let kfileNameExtension = "instagram.igo"
        let kAlertViewTitle = "Error"
        let kAlertViewMessage = "Please install the Instagram application"
     
        var documentInteractionController = UIDocumentInteractionController()
        // called to post image with caption to the instagram application
        
        let instagramURL = URL(string: kInstagramURL)
        if UIApplication.shared.canOpenURL(instagramURL!) {
            let manager = FileManager()
            let path = manager.temporaryDirectory.appendingPathComponent(kfileNameExtension)
            do {
                //try UIImageJPEGRepresentation(imageInstagram, 1.0)!.write(to: path, options: .atomic)
                try imageData.write(to: path, options: .atomic)
                //                UIImageJPEGRepresentation(imageInstagram, 1.0)!.writeToFile(path, atomically: true)
            }
            catch {
                print("Error writing")
                return
            }
            //let fileURL = URL(fileURLWithPath: path)
            let fileURL = path
            documentInteractionController.url = fileURL
            documentInteractionController.delegate = self
            documentInteractionController.uti = kUTI
            
            // adding caption for the image
            documentInteractionController.annotation = ["InstagramCaption": instagramCaption]
            documentInteractionController.presentOpenInMenu(from: barButton, animated: true)
            //documentInteractionController.presentOpenInMenuFromRect(rect, inView: view, animated: true)
        } else {
            
            // alert displayed when the instagram application is not available in the device
            //UIAlertView(title: kAlertViewTitle, message: kAlertViewMessage, delegate:nil, cancelButtonTitle:"Ok").show()
        }
    }
     */
    
}

