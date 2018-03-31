//
//  CaptionViewController.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import UIKit

class CaptionViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var feedbackView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var tableData: [String] = []
    
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func happyReactionAction(_ sender: Any) {
        alertUser(title: "Enjoy the ❤️s", message: "Hope to see you again soon!")
    }
    @IBAction func sadReactionAction(_ sender: Any) {
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
        }
        
        NotificationCenter.default.addObserver(forName: Constants.ListenerName.CAPTIONS_FAILED, object: nil, queue: nil) { (notification) in
            if let error = notification.object as? Error {
                
                // log in FIR analytics
                // show error message and ask if want to retry
                self.alertUser(title: "Error", message: "Sorry about this, we're working on fixing it! Please try again.")
                
                print(error.localizedDescription)
            }
            
        }
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
    
}


// TableView extension
extension CaptionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
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

