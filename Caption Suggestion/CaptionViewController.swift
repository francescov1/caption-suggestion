//
//  CaptionViewController.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import UIKit
import FacebookShare
import FBSDKShareKit

class CaptionViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var feedbackView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var happyReactionButton: UIButton!
    @IBOutlet weak var sadReactionButton: UIButton!
    
    var imageToPost: UIImage?
    
    var tableData: [String] = []
    
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func happyReactionAction(_ sender: Any) {
        disableFeedback()
        alertUser(title: "Enjoy the ❤️s", message: "Hope to see you again soon!")
    }
    
    @IBAction func sadReactionAction(_ sender: Any) {
        disableFeedback()
        alertUser(title: "Sorry about that!", message: "We will consider this and improve our system for next time 😘")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        
        feedbackView.alpha = 0 // hide feedbackView (fade in when data ready)
        activityIndicator.startAnimating()
        waitForCaptions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func waitForCaptions() {
        NotificationCenter.default.addObserver(forName: Constants.ListenerName.CAPTIONS_RECEIVED, object: nil, queue: nil) { (notification) in
            if let captions = notification.object as? CaptionJSON {
                self.tableData = captions.suggestedCaptions
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                    // fade in feedbackView once loading complete
                    self.activityIndicator.stopAnimating()
                    self.fadeIn(view: self.feedbackView, delay: 0)
                }
                print("Image Info:\nSuggested: \(captions.suggestedCaptions)")
            }
            
            // caption failed, notification is error
            else if let error = notification.object as? Error {
                
                // log in FIR analytics
                // show error message and ask if want to retry
                
                self.alertUser(title: "Error", message: "Sorry about this, we're working on fixing it! Please try again.")
                print(error.localizedDescription)
            }
        }
        
        NotificationCenter.default.addObserver(forName: Constants.ListenerName.IMAGE_TO_POST, object: nil, queue: nil) { (notification) in
            if let image = notification.object as? UIImage {
                self.imageToPost = image
            }
            
        }
    }
    
    // TODO: Add button titles to constants
    func sharePopup(image: UIImage, caption: String) {
        AlertManager.sharedManager.askUser(title: "Share image with your new suggested caption!", message: "You will still have the chance to make any finishing touches 👌", buttonTitles: ["Facebook", "Instagram"]) { (action) in
            guard let buttonTitle = action.title else {
                print("Error with title names")
                return
            }
            
            switch buttonTitle {
                
            case "Facebook":
                self.shareToFacebook(caption: caption)
            case "Instagram":
                InstagramManager.sharedManager.documentControllerPost(image: image, caption: caption)
            default:
                print("Error")
                
            }
        }
    }
    
    func shareSheet(caption: String) {
         guard let image = imageToPost else { return }
        
        
        //var activityVC = UIActivityViewController(activityItems: [caption, image], applicationActivities: [])
        //activityVC.excludedActivityTypes[UIActivityTypePostToFacebook]
        //present(activityVC, animated: true, completion: nil)

        //InstagramManager.sharedManager.postImageToInstagramWithCaption(imageData: image, instagramCaption: caption, barButton: <#T##UIBarButtonItem#>)
        InstagramManager.sharedManager.openInstagram()
    }
    
    func shareToFacebook(caption: String) {
        // TODO: Add caption to post
        guard let image = imageToPost else {
            alertUser(title: "Error Opening Facebook", message: "Ensure you have the Facebook app installed and try again")
            return
        }
        
        guard var photo = FBSDKSharePhoto(image: image, userGenerated: true) else {
            alertUser(title: "Error Sending Data to Facebook", message: "Ensure you have the Facebook app installed and try again")
            return
        }
        
        photo.caption = caption
        
        var content = FBSDKSharePhotoContent()
        content.photos = [photo]
    
        
        FBSDKShareDialog.show(from: self, with: content, delegate: nil)
        
    }
    
    func disableFeedback() {
        happyReactionButton.isEnabled = false
        sadReactionButton.isEnabled = false
        // TODO:make buttons translucent
    }
    
    // helper function (pop-up box)
    func alertUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func fadeIn(view : UIView, delay: TimeInterval) {
        let animationDuration = 0.25
        
        // After the animation completes, fade out the view after a delay
        UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
            view.alpha = 1
        }, completion: nil)
    }
    
    
    func documentControllerPost(image: UIImage, caption: String) {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let checkValidation = FileManager.default
        let getImagePath = paths.appending("/image.igo")
        do {
            try checkValidation.removeItem(atPath: getImagePath)
        }
        catch let error {
            print("error with checkValidation: \(error)")
            return
        }
        
        let imageData =  UIImageJPEGRepresentation(image, 1.0)
        
        do {
            try imageData?.write(to: URL(fileURLWithPath: getImagePath), options: .atomicWrite)
        }
        catch let error {
            print("error with imageData write: \(error)")
            return
        }
        
        let imageUrl = URL(fileURLWithPath: getImagePath)
        
        var documentController = UIDocumentInteractionController(url: imageUrl)
        documentController.uti = "com.instagram.exclusivegram"
    
        documentController.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
        // try other option (openInMenu???)
        AlertManager.sharedManager.alertUser(title: "Test", message: "Worked", completion: nil)
        // topVC.present(documentController, animated: true, completion: nil)
        
    }
    
}


// TableView extension
extension CaptionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        tableView.allowsMultipleSelection = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let caption = tableData[indexPath.row]
        //shareToFacebook(caption: caption)
        //shareSheet(caption: caption)
        
        guard let image = imageToPost else {
            alertUser(title: "Error Opening Facebook", message: "Ensure you have the Facebook app installed and try again")
            return
        }
        sharePopup(image: image, caption: caption)
        // documentControllerPost(image: image, caption: caption)
       // InstagramManager.sharedManager.documentControllerPost(image: image, caption: caption)
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Initialize cell as custom cell (see CaptionTableViewCell file)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseId", for: indexPath) as! CaptionTableViewCell
        cell.captionLabel.text = tableData[indexPath.row]
        //cell.textLabel?.font = UIFont(name: (cell.textLabel?.font.fontName)!, size: 12)
        //cell.textLabel?.textColor = UIColor.gray
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
}

