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
//import CenteredCollectionView
import ZKCarousel

class CaptionViewController: UIViewController {

    @IBOutlet weak var feedbackView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var happyReactionButton: UIButton!
    @IBOutlet weak var sadReactionButton: UIButton!
    @IBOutlet weak var suggestedCaptionView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    /*
    // The width of each cell with respect to the screen.
    // Can be a constant or a percentage.
    let cellPercentWidth: CGFloat = 0.7
    
    // A reference to the `CenteredCollectionViewFlowLayout`.
    // Must be aquired from the IBOutlet collectionView.
    var centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    */
    
    
    // other pod
    let carousel : ZKCarousel = {
        let carousel = ZKCarousel()
        
        // Create as many slides as you'd like to show in the carousel
        let slide = ZKCarouselSlide(image: UIImage(), title: "Hello There 👻", description: "Welcome to the ZKCarousel demo! Swipe left to view more slides!")
        let slide1 = ZKCarouselSlide(image: UIImage(), title: "A Demo Slide ☝🏼", description: "lorem ipsum devornum cora fusoa foen sdie ha odab ebakldf shjbesd ljkhf")
        let slide2 = ZKCarouselSlide(image: UIImage(), title: "Another Demo Slide ✌🏼", description: "lorem ipsum devornum cora fusoa foen ebakldf shjbesd ljkhf")
        
        // Add the slides to the carousel
        carousel.slides = [slide, slide1, slide2]
        
        return carousel
    }()

    
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
        
        // hide feedbackView (fade in when data ready)
        feedbackView.alpha = 0
        activityIndicator.startAnimating()
        waitForCaptions()
        
        self.carousel.frame = CGRect()
        self.suggestedCaptionView.addSubview(self.carousel)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /*func initializeCollectionView() {
        // Get the reference to the `CenteredCollectionViewFlowLayout` (REQURED STEP)
        centeredCollectionViewFlowLayout = collectionView.collectionViewLayout as! CenteredCollectionViewFlowLayout
        
        // Modify the collectionView's decelerationRate (REQURED STEP)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        // Assign delegate and data source
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Configure the required item size (REQURED STEP)
        centeredCollectionViewFlowLayout.itemSize = CGSize(
            width: view.bounds.width * cellPercentWidth,
            height: view.bounds.height * cellPercentWidth * cellPercentWidth
        )
        
        // Configure the optional inter item spacing (OPTIONAL STEP)
        centeredCollectionViewFlowLayout.minimumLineSpacing = 20
        
        // Get rid of scrolling indicators
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }*/
    
    func waitForCaptions() {
        NotificationCenter.default.addObserver(forName: Constants.ListenerName.CAPTIONS_RECEIVED, object: nil, queue: nil) { (notification) in
            if let captions = notification.object as? CaptionJSON {
                //self.tableData = captions.suggestedCaptions
                
                DispatchQueue.main.async {
                    
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
                DispatchQueue.main.async { // Correct
                    self.imageView.image = image
                }
                
                
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



// CollectionView Extension
/*

extension CaptionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // check if the currentCenteredPage is not the page that was touched
        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage, currentCenteredPage != indexPath.row {
            // trigger a scrollTo(index: animated:)
            collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition(rawValue: 0), animated: true)
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }
    
    
}*/


