// Copyright [2021] [Banana.ch SA - Lugano Switzerland]
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/**
  The method dateAdd add days to a date and return the new date as iso string.
  @param isoDate the date in iso format
  @param days the number of days to add
  @return return the new date or null if the parameters are not valid
*/
function dateAdd(date, days) {
    if (!date || !days)
        return null
    let dateobj = Banana.Converter.toDate(date.substring(0,10))
    if (!dateobj)
        return null
    return (new Date(dateobj.valueOf() + 24*60*60*1000*days)).toISOString().substring(0,10)
}

/**
  The method dateDiff returns the number of days between two dates.
  @param fromDate the first date in iso format
  @param toDate the secondo date in iso format
  @return return the number of days between the dates, or 0 if one of the dates are invalid
*/
function dateDiff(fromDate, toDate) {
    if (!fromDate || !toDate)
        return 0;
    let d1obj = Banana.Converter.toDate(fromDate.substring(0,10))
    let d2obj = Banana.Converter.toDate(toDate.substring(0,10))
    if (!d1obj || !d2obj)
        return 0;
    const diffTime = Math.abs(d2obj - d1obj);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays + 1;
}

/**
 * The method textMatchSearch return true if the test match the search string.
 * The search pattern can contains one or more terms. The text math the search string
 * if for every search term there at least one word that start with the serach term.
 *
 * Examples:
 * - text:    "Lorenzo"
 *   seach:   "lo pa"
 *   returns:  true
 * - text:    "Lorenzo Paolini"
 *   seach:   "lo pa"
 *   returns:  true
 * - text:    "Lorenzo Paolini"
 *   seach:   "lo ma"
 *   returns:  false
 * - text:    "Lorenzo Paolini"
 *   seach:   "lo ma gi"
 *   returns:  false
 * - text:    "Lorenzo Paolini"
 *   seach:   "zo"
 *   returns:  false
 */
function textMatchSearch(text, search) {
    let descrWords = text.toLowerCase().split(" ")
    let searchWords = search.toLowerCase().split(" ")
    let matchsCount = 0;
    for (let si = 0; si < searchWords.length; ++si) {
        for (let di = 0; di < descrWords.length; ++di) {
            if (descrWords[di].startsWith(searchWords[si])) {
                matchsCount++
                break
            }
        }
    }
    if (matchsCount === searchWords.length) {
        return true
    }
    return false
}

/** Check if the Application version is equal or greater than 10.0.19.
  This function has been created after some changes to the JSON structure
  to hide in the older versions some components who works only with the new json structure
  available from the 10.0.19.
  */

function isCompatibleBananaVersion(){
    let requiredVersion = "10.1.19";
   if (Banana.compareVersion(Banana.application.version,requiredVersion) >= 0 ) {
       return true;
   }
   return false;
}
