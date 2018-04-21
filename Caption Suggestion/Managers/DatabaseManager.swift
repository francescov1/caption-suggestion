//
//  DatabaseManager.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-04-04.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class DatabaseManager {
    class var sharedManager: DatabaseManager {
        struct Singleton {
            static let instance = DatabaseManager()
        }
        return Singleton.instance
    }
    
    var dbRef: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    // use this until saveFeedback is fully implemented
    func saveReaction(imageData: Data?, captions: [String], good: Bool) {
        
        var feedback: [String: Any] = ["timestamp": FIRServerValue.timestamp(), "image": "NA", "captions": captions, "good": good]
        if imageData != nil {
            feedback["image"] = imageData?.base64EncodedString()
        }
        dbRef.child("feedback").childByAutoId().setValue(feedback) { (error, ref) in
            if error != nil {
                // log error
                print("Error with database write:\n\(String(describing: error))")
                return
            }
        }
    }
    
    // call this after user leaves screen or exists, so if they leave written feedback its also given
    func saveFeedback(captions: [String], imageData: Data?, keyword: String, type: String, good: Bool, message: String?) {
        
        var feedback: [String: Any] = ["timestamp": FIRServerValue.timestamp(), "image": "NA", "captions": captions, "keyword": keyword, "type": type, "good": good, "message": message ?? "NA"]
        if imageData != nil {
            feedback["image"] = imageData?.base64EncodedString()
        }
        dbRef.child("feedback").childByAutoId().setValue(feedback) { (error, ref) in
            if error != nil {
                // log error
                print("Error with database write:\n\(String(describing: error))")
                return
            }
        }
    }
    
}
