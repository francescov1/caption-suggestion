//
//  AlertsProvider.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-31.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import Foundation
import UIKit

class AlertManager {
    class var sharedManager: AlertManager {
        struct Singleton {
            static let instance = AlertManager()
        }
        return Singleton.instance
    }
    
    
    func alertUser(title: String, message: String, completion: ((UIAlertAction) -> Void)?) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Dismiss", style: .default, handler: completion)
        alert.addAction(ok)
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        
    }
    
    func askUser(title: String, message: String, buttonTitles: [String], completion: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for title in buttonTitles {
            let button = UIAlertAction(title: title, style: .default, handler: completion)
            alert.addAction(button)
        }
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        
    }

}
