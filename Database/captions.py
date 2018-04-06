import pandas as pd
import numpy as np
import json
import pprint

oldCaps = pd.read_json('caption-suggestion-export-caps.json')

captions = pd.read_csv('newcaptions.csv')

lyric = captions['captions_lyric']
lyric = lyric.dropna()
lyric = lyric.values

funny = captions['captions_funny']
funny = funny.dropna()
funny = funny.values

sentimental = captions['captions_sentimental']
sentimental = sentimental.dropna()
sentimental = sentimental.values

selfie = captions['captions_selfie']
selfie = selfie.dropna()
selfie = selfie.values

newCaps = {'captions': {
                'funny': funny,
                'sentimental': sentimental,
                'selfie': selfie,
                'lyric': lyric}
            }


newCaps = pd.DataFrame(newCaps)
print('newcaps:\n', newCaps)
print('\noldcaps:\n', oldCaps)

oldFunny = np.array(oldCaps.loc['funny'][0])
newFunny = np.array(newCaps.loc['funny'][0])
combFunny = np.concatenate((oldFunny, newFunny))

oldSentimental = np.array(oldCaps.loc['sentimental'][0])
newSentimental = np.array(newCaps.loc['sentimental'][0])
combSentimental = np.concatenate((oldSentimental, newSentimental))

oldSelfie = np.array(oldCaps.loc['selfie'][0])
newSelfie = np.array(newCaps.loc['selfie'][0])
combSelfie = np.concatenate((oldSelfie, newSelfie))

oldLyric = np.array(oldCaps.loc['lyric'][0])
newLyric = np.array(newCaps.loc['lyric'][0])
combLyric = np.concatenate((oldLyric, newLyric))

generic = np.array(oldCaps.loc['generic'][0], dtype=object)
motivational = np.array(oldCaps.loc['motivational'][0], dtype=object)
pun = np.array(oldCaps.loc['pun'][0], dtype=object)

combinedCaps = {'captions': {
                'funny': combFunny.tolist(),
                'sentimental': combSentimental.tolist(),
                'selfie': combSelfie.tolist(),
                'lyric': combLyric.tolist(),
                'generic': generic.tolist(),
                'motivational': motivational.tolist(),
                'pun': pun.tolist()
                }
            }
pprint.pprint(combinedCaps)

with open('data.json', 'w') as outfile:
    json.dump(combinedCaps, outfile, ensure_ascii=False)

#combinedCaps = pd.concat([oldCaps, newCaps], axis=1)
#print(combinedCaps)
#