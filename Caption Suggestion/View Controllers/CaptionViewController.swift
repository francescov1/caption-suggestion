//
//  CaptionViewController.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import UIKit
import FBSDKShareKit
import FirebaseCore
import FirebaseDatabase

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
        AlertManager.sharedManager.alertUser(title: "Enjoy the ❤️s", message: "Hope to see you again soon!", completion: nil)
        DatabaseManager.sharedManager.saveReaction(imageData: imageToPost?.png, captions: tableData, good: true)
    }
    
    @IBAction func sadReactionAction(_ sender: Any) {
        disableFeedback()
        AlertManager.sharedManager.alertUser(title: "Sorry about that!", message: "We will consider this and improve our system for next time 😘", completion: nil)
        DatabaseManager.sharedManager.saveReaction(imageData: imageToPost?.png, captions: tableData, good: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        
        // hide feedbackView (fade in when data ready)
        feedbackView.alpha = 0
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
            }
            
            // caption failed, notification is error
            else if let error = notification.object as? Error {
                
                // log in FIR analytics
                // show error message and ask if want to retry
                AlertManager.sharedManager.alertUser(title: "Error", message: "Sorry about this, we're working on fixing it! Please try again.", completion: nil)
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
                SharingManager.sharedManager.shareToFacebook(image: image, caption: caption)
                //self.shareToFacebook(caption: caption)
            case "Instagram":
                SharingManager.sharedManager.documentControllerInstagramPost(image: image, caption: caption)
                //InstagramManager.sharedManager.documentControllerPost(image: image, caption: caption)
            default:
                print("Error")
            }
        }
    }
    
    // TODO: make buttons translucent and show textbook to provide feedback
    func disableFeedback() {
        happyReactionButton.isEnabled = false
        sadReactionButton.isEnabled = false
        
    }
    
    func fadeIn(view : UIView, delay: TimeInterval) {
        let animationDuration = 0.25
        
        // After the animation completes, fade out the view after a delay
        UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
            view.alpha = 1
        }, completion: nil)
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
            AlertManager.sharedManager.alertUser(title: "Error with image uploaded", message: "Ensure the image is still saved on your phone and try again", completion: nil)
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

