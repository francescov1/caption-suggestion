//
//  AlertsProvider.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-31.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import Foundation
import UIKit

class AlertsProvider {
    
    func alertUser(title: String, message: String, completion: @escaping () -> ()) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(ok)
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: completion)
    }

}
