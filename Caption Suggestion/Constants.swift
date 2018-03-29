//
//  Constants.swift
//  Caption Suggestion
//
//  Created by Francesco Virga on 2018-03-29.
//  Copyright © 2018 Francesco Virga. All rights reserved.
//

import Foundation

struct Constants {
    static let PICKER_DATA = ["Lyric", "Generic", "Sentimental", "Funny", "Selfie", "Pun", "Motivational"]
    
    struct RequestHeader {
        static let ADDITIONAL_KEYWORD = "additional-keyword"
        static let CAPTION_TYPE = "caption-type"
        static let NUM_SUGGESTIONS = "number-of-suggestions"
        
    }
    struct RequestUrl {
        static let SUGGEST_CAPS = "https://us-central1-caption-suggestion.cloudfunctions.net/suggestCaptions"
    }
    
    struct ListenerName {
        static let CAPTIONS_RECEIVED = NSNotification.Name("CaptionsReceived")
    }
    
    
}
