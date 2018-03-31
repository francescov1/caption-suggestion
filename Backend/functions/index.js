'use strict';
const admin = require('firebase-admin');
const functions = require('firebase-functions');
admin.initializeApp(functions.config().firebase);
const db =  admin.database();

const requestPK = require('request');
const util = require('util');
const headers = functions.config().backend.reqheader;
const azure = functions.config().azure;
const wordapi = functions.config().wordapi;

exports.suggestCaptions = functions.https.onRequest((request, response) => {

    let data = request.body;
    var additionalKeyword;
    var synonymsPromise;
    if (request.headers[headers.keyword]) { // trim whitespace of keyword
      additionalKeyword = request.headers[headers.keyword];
      additionalKeyword = additionalKeyword.trim();
      synonymsPromise = fetchSynonyms(additionalKeyword);
    }

    let captionType = request.headers[headers.captype];
    var captionPromise = fetchCaptions(captionType);

    let numOfCaps = parseInt(request.headers[headers.numsuggestions]);

    // only request tags or description to make quicker
    // Azure Computer Vision API call
    var params = {
        "visualFeatures": "Color,Categories,Description,Tags,Faces",
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

    function callback(err, res, body) {
      console.timeEnd("computerVisionTagFetch");
      if (!err && (res.statusCode === 200 || res.statusCode === 201)) {
        console.log('Data:\n' + body);

        let data = JSON.parse(body);
        let description = data.description;
        let genCaptionsObj = description.captions;
        let tags = description.tags;

        var genCaptions = [];
        for (var i=0; i<genCaptions.length; i++) {
          genCaptions.push(genCaptionsObj[i].text);
        }

        Promise.all([captionPromise, synonymsPromise]).then(results => {
            console.time("refineTime");
            let captions = results[0];
            let synonyms = results[1];
            let refinedCaptions = captionRefine(captions, tags, additionalKeyword || null, synonyms || null, numOfCaps);
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
    }
    console.time("computerVisionTagFetch")
    requestPK(options, callback);
});


function fetchCaptions(type) {
    console.time("databaseFetch");
    return db.ref("captions/" + type).once("value").then(snapshot => {
      console.timeEnd("databaseFetch");
      return snapshot.val();
    });
}


function captionRefine(captions, tags, keyword, synonyms, n) {
    // fill flag array with 1 so that if no tags apply, first 3 captions
    // will still be chosen
    var flags = Array(captions.length);
    flags.fill(1);
    // loop through captions, check for keywords
    // if found, increment flags accordingly
    for (var j=0; j<captions.length; j++) {
      // check for tags in captions
      for (var i=0; i<tags.length; i++) {
        if(captions[j].indexOf(tags[i]) !== -1) flags[j] += 2;
      }
      // check for keyword synonyms in captions
      if (synonyms) {
        for (i=0; i<synonyms.length; i++) {
          if (captions[j].indexOf(synonyms[i]) !== -1) flags[j] += 1;
        }
      }
      // check for keyword in captions
      if(keyword && captions[j].indexOf(keyword) !== -1) flags[j] += 3;
    }

    console.log('Flags:\n' + flags);
    var refinedCaptions = []
    for(i=0; i<n; i++) {
      let max = Math.max.apply(null, flags);
      let index = flags.indexOf(max);
      // set flag to 0 and add caption to suggested captions
      flags[index] = 0;
      let newCaption = captions[index];
      if (refinedCaptions.indexOf(newCaption) === -1) refinedCaptions.push(newCaption);
    }
    return refinedCaptions;
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
