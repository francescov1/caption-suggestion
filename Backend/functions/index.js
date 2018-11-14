'use strict';
const admin = require('firebase-admin');
const functions = require('firebase-functions');
admin.initializeApp();
const db = admin.database();
const stopWord = require('stopword');
const requestPK = require('request');
const util = require('util');

/*const firebaseConfig = JSON.parse(process.env.FIREBASE_CONFIG);
const headers = firebaseConfig.backend.reqheader;
const azure = firebaseConfig.azure;
const wordapi = firebaseConfig.wordapi;*/
const headers = functions.config().backend.reqheader;
const azure = functions.config().azure;
const wordapi = functions.config().wordapi;

exports.suggestCaptions = functions.https.onRequest((request, response) => {
    let data = request.body;
    var additionalKeyword;
    var synonymsPromise;
    if (request.headers[headers.keyword]) {
      additionalKeyword = request.headers[headers.keyword];
      additionalKeyword = additionalKeyword.trim();
      synonymsPromise = fetchSynonyms(additionalKeyword);
    }

    let captionType = request.headers[headers.captype];
    var captionPromise = fetchCaptions(captionType);
    let numOfCaps = parseInt(request.headers[headers.numsuggestions]);

    // Azure Computer Vision API call
    var params = {
        "visualFeatures": "Tags,Description",
        "details": "",
        "language": "en",
    };
    var options = {
      method: 'POST',
      uri: azure.requrl,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': azure.subscriptionkey
      },
      qs: params,
      body: data
    };

    console.time("computerVisionTagFetch")
    requestPK(options, function(err, res, body) {
      console.timeEnd("computerVisionTagFetch");
      if (!err && (res.statusCode === 200 || res.statusCode === 201)) {
        console.log('Data:\n' + body);

        let data = JSON.parse(body);
        let topTags = data.tags;
        let description = data.description;
        let genCaptionsObj = description.captions;
        let allTags = description.tags;

        var genCaptionTags = [];
        for (var i=0; i<genCaptionsObj.length; i++) {
          var genTags = genCaptionsObj[i].text.split(' ');
          genTags = stopWord.removeStopwords(genTags);
          genCaptionTags = genCaptionTags.concat(genTags);
        }

        Promise.all([captionPromise, synonymsPromise]).then(results => {
            console.time("refineTime");
            let captions = results[0];
            let synonyms = results[1];
            let refinedCaptions = captionRefine(captions, topTags, allTags, genCaptionTags, additionalKeyword || null, synonyms || null, numOfCaps);
            console.log('Final caption suggestions:\n' + util.inspect(refinedCaptions, {showHidden: false, depth: null}));
            let dataResponse = {
              'suggestedCaptions': refinedCaptions,
            };
            console.timeEnd("refineTime");
            response.status(200).send(dataResponse);
            return refinedCaptions;
        }).catch(error => {
            console.log('promise error: ' + error);
            response.status(400).send(error);
            return error;
        });

      }
      else {
        console.log('error: ', err);
        response.status(res.statusCode || 400).send(err);
      }
    });
});


function fetchCaptions(type) {
    console.time("databaseFetch");
    return db.ref("captions/" + type).once("value").then(snapshot => {
      console.timeEnd("databaseFetch");
      return snapshot.val();
    });
}

// TODO:
// make sure tags and description.tags line up properly
// ensure continuing loop iterator works

function captionRefine(captions, topTags, allTags, genCaptionTags, keyword, synonyms, n) {
    // fill flag array with 1 so that if no tags apply, first 3 captions
    // will still be chosen
    var flags = Array(captions.length);
    flags.fill(1);
    var capsWithKeyword = [];
    // loop through captions, check for keywords
    // if found, increment flags accordingly
    for (var j=0; j<captions.length; j++) {
        for (var i=0; i<topTags.length; i++) {
            if (topTags[i].confidence < 0.5) break;
            if (captions[j].indexOf(topTags[i].name) !== -1) flags[j] += 2;
        }
        // check for tags in captions
        for (i; i<allTags.length; i++) {
            if(captions[j].indexOf(allTags[i]) !== -1) flags[j] += 1;
        }
        // check for generated caption words in captions
        for (i=0; i<genCaptionTags.length; i++) {
            if(captions[j].indexOf(allTags[i]) !== -1) flags[j] += 1;
        }
        // check for keyword synonyms in captions
        if (synonyms) {
            for (i=0; i<synonyms.length; i++) {
              if (captions[j].indexOf(synonyms[i]) !== -1) flags[j] += 1;
            }
        }
        // check for keyword in captions
        if(keyword && captions[j].indexOf(keyword) !== -1) {
            flags[j] += 4;
            capsWithKeyword.push(captions[j]);
        }
    }

    console.log('Flags:\n' + flags);
    var refinedCaptions = [];
    while (refinedCaptions.length < n) {
        let max = Math.max.apply(null, flags);
        let index = flags.indexOf(max);
        // set flag to 0 and add caption to suggested captions
        flags[index] = 0;
        let newCaption = captions[index];
        if (refinedCaptions.indexOf(newCaption) === -1) refinedCaptions.push(newCaption);
        //if (refinedCaptions.indexOf(newCaption) === -1 && newCaption.indexOf(keyword) !== -1) refinedCaptions.push(newCaption);
    }
    return refinedCaptions;
}

function testNewRefine(keyword, tags) {

}

function fetchSynonyms(keyword) {
    console.time("synonymFetch");
    var options = {
      method: 'GET',
      uri: wordapi.requrl + '/' + keyword + '/synonyms',
      headers: {
        'Accept': 'application/json',
        'X-Mashape-Key': wordapi.subscriptionkey
      }
    };
    return new Promise(function(resolve, reject) {
      return requestPK(options, function(err, res, body) {
        console.timeEnd("synonymFetch");
        if (err) {
          console.log('error with word api:', err);
          reject(err);
        }
        else {
          let data = JSON.parse(body);
          resolve(data.synonyms);
        }
      });
    });
}
