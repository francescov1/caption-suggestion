//
//  InstagramProvider.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import UIKit
import Foundation

class InstagramManager: NSObject, UIDocumentInteractionControllerDelegate {
    
    private let kInstagramURL = "instagram://app"
    private let kUTI = "com.instagram.exclusivegram"
    private let kfileNameExtension = "instagram.igo"
    private let kAlertViewTitle = "Error"
    private let kAlertViewMessage = "Please install the Instagram application"
    
    var documentInteractionController = UIDocumentInteractionController()
    
    // singleton manager
    class var sharedManager: InstagramManager {
        struct Singleton {
            static let instance = InstagramManager()
        }
        return Singleton.instance
    }
    
    func postImageToInstagramWithCaption(imageData: Data, instagramCaption: String, barButton: UIBarButtonItem) {
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
    
}

