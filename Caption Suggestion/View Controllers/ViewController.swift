//
//  ViewController.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import Crashlytics

struct CaptionJSON: Codable {
    var suggestedCaptions: [String]
}

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var keywordField: UITextField!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var pickerViewer: UIPickerView!
    
    let pickerData = Constants.PICKER_DATA
    
    @IBAction func choseImageAction(_ sender: Any) {
        addNewPicture()
    }
    
    @IBAction func generateAction(_ sender: Any) {
        var keyword = ""
        if let text = keywordField.text {
            keyword = text
        }
        if let image = imageView.image,  let data = UIImagePNGRepresentation(image) as Data? {
            restReq(imageData: data, keyword: keyword) // call REST request function with chosen image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGesture()
        pickerViewer.dataSource = self
        pickerViewer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func restReq(imageData: Data, keyword: String) {
        
        // url for request
        let urlString = Constants.RequestUrl.SUGGEST_CAPS
        guard let url = URL(string: urlString) else { return }
        
        // build request
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "POST"
        urlReq.httpBody = imageData
        urlReq.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let type = pickerData[pickerViewer.selectedRow(inComponent: 0)].lowercased() // caption type
        urlReq.addValue(type, forHTTPHeaderField: Constants.RequestHeader.CAPTION_TYPE)
        urlReq.addValue("3", forHTTPHeaderField: Constants.RequestHeader.NUM_SUGGESTIONS) // this "3" should be grabbed from user input rather than hardcoded
        
        if keyword != "" {
            urlReq.addValue(keyword, forHTTPHeaderField: Constants.RequestHeader.ADDITIONAL_KEYWORD)
        }
        
        
        // send request
        URLSession.shared.dataTask(with: urlReq) { (data, response, error) in
            if error != nil {
                NotificationCenter.default.post(name: Constants.ListenerName.CAPTIONS_RECEIVED, object: error)
                return
            }
            guard let data = data else { return }
            do {
                // assign response JSON to struct
                let captions = try JSONDecoder().decode(CaptionJSON.self, from: data)
                
                // next vc will place observer on notif center and wait until captions arrived
                NotificationCenter.default.post(name: Constants.ListenerName.IMAGE_TO_POST, object: self.imageView.image)
                NotificationCenter.default.post(name: Constants.ListenerName.CAPTIONS_RECEIVED, object: captions)
            }
            catch let jsonError {
                print(jsonError)
            }
        }.resume()
    }
    
    // helper function (pop-up box)
    func alertUser(title: String, message: String, completion: @escaping (UIAlertAction) -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Dismiss", style: .default, handler: completion)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
}

// ImagePicker extension
extension ViewController: UIImagePickerControllerDelegate {
    
    func addNewPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            print("Error with image picker")
            return
        }
        
        imageView.image = image
        generateButton.isEnabled = true
        dismiss(animated: true)
    }
}

// PickerView extension
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate  {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}

// TextField extension
extension ViewController: UITextFieldDelegate {
    func addTapGesture(){
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
