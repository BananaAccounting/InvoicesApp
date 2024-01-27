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

import QtQuick
import QtQuick.Controls

/**
 * The StyledKeyDescrComboBox use a model with the members 'key', 'value' and 'search'.
 * It lets filter the items in the list by the description or search members.
 */
StyledComboBox {
    id: control

    // The property modified is true if the user modified the text or the selection
    property bool modified: false

    // Index the current key
    property int currentKeyIndex: -1

    // Index of current highlighted item
    property int currentHighlightIndex: -1

    // Text set when the user press esc
    property string undoKey: ""

    // If true the display text include the key
    property bool displayTextIncludesKey: false

    // If true the display text include the key
    property bool displayTextIncludesDescr: true

    // If true the ComboBox filter the model items
    property bool filterEnabled: false

    // If true the item text in the list includes the key
    property bool listItemTextIncludesKey: true

    /** If true the control output some debug info */
    property bool debugOut: false

    /** This signal is emitted when the user selected or set a new key */
    signal currentKeySet(key: string, isExistingKey: bool)    

    /** The function cleanKey is used to clean the key inserted by the user */
    property var cleanKey: function(key) {
        return key.trim();
    }

    /** This object contains private filter properties */
    QtObject {
        id: filter

        // Internally used to determine if the filtered list have to be completely reloaded
        property string lastFilterText: ""

        // This property hold a reference to the ufilted (or original) model
        property var unfilteredModel: null

        // If true the ComboBox is filtering the items in the list
        property bool running: false

        // This property hold the reference to the filtered model
        property ListModel filteredModel
    }

    ListModel {
        id: filteredModel
    }

    background: Rectangle {
        color: Stylesheet.baseColor
        border.width: 1
        border.color: "#bdbebf"
        radius: 2.0 * Stylesheet.pixelScaleRatio
    }

    contentItem: StyledTextField {
        id: textField
        readOnly: !control.editable
        text: control.displayText

        onEditingFinished: {
            control.modified = modified
            if (control.modified) {
                if (debugOut)
                    console.log("ComboBox onEditingFinished: " + text)
                let keyMatchIndex = findKey(text)
                if (keyMatchIndex >= 0) {
                    // Current text match a key
                    if (debugOut)
                        console.log("ComboBox key match: " + currentHighlightIndex)
                    control.currentKeyIndex = keyMatchIndex
                    control.currentHighlightIndex = keyMatchIndex
                    let item = model.get(keyMatchIndex)
                    control.undoKey = item.key
                    control.setDisplayText(item.key, item.descr);
                    control.currentKeySet(item.key, true);
                } else {
                    if (control.popup.visible && currentHighlightIndex >= 0) {
                        // An item is hightlighted in the popup
                        if (debugOut)
                            console.log("ComboBox highlightedIndex: " + currentHighlightIndex)
                        control.currentKeyIndex = currentHighlightIndex
                        let item = model.get(currentHighlightIndex)
                        control.undoKey = item.key
                        control.setDisplayText(item.key, item.descr);
                        control.currentKeySet(item.key, true);
                    } else {
                        let index = findDescription(text)
                        if (index >= 0) {
                            // Current text match a description
                            if (debugOut)
                                console.log("ComboBox description match: " + text)
                            control.currentKeyIndex = index
                            control.currentHighlightIndex = index
                            let item = model.get(index)
                            control.undoKey = item.key
                            control.setDisplayText(item.key, item.descr);
                            control.currentKeySet(item.key, true);
                        } else {
                            // Current text doesn't match any key and any description
                            if (debugOut)
                                console.log("ComboBox text doesn't matck any key or any description")
                            control.currentKeyIndex = -1
                            control.currentHighlightIndex = -1
                            let cleanedText = cleanKey(text)
                            control.undoKey = cleanedText
                            control.setDisplayText(cleanedText, "")
                            control.currentKeySet(cleanedText, false);
                        }
                    }
                }
                textField.modified = false
            }
        }

        onTextEdited: {
            if (!control.popup.visible) {
                control.popup.open()
            }
            control.currentHighlightIndex = -1
            control.popup.listView.positionViewAtBeginning()
            control.modified = true
            if (filterEnabled) {
                filterModelTimer.restart()
            }
            control.updateCurrentIndex(text)
        }

        onFocusChanged: {
            if (focus) {
                control.selectAll()
                control.popup.open()
                if (currentKeyIndex >= 0) {
                    control.popup.listView.positionViewAtIndex(currentKeyIndex, ListView.Beginning)
                } else {
                    control.popup.listView.positionViewAtIndex(0, ListView.Beginning)
                }
            }
        }
    }

    delegate: ItemDelegate {
        text: listItemTextIncludesKey ? key + "\t" + descr : descr
        width: control.popup.listView.width
        font.bold: currentKeyIndex === index
        highlighted: currentHighlightIndex === index
        MouseArea {
            anchors.fill: parent
            onClicked: {
                control.currentKeyIndex = index
                control.currentHighlightIndex = index
                control.contentItem.focus = false
                control.modified = true
                let item = control.model.get(control.currentHighlightIndex)
                undoKey = item.key
                control.setDisplayText(item.key, item.descr);
                control.currentKeySet(item.key, true);
                control.popup.close()
            }
        }
    }

    Timer {
        id: filterModelTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (filterEnabled) {
                if (!filter.filterRunningModel) {
                    filterModel()
                } else {
                    restart()
                }
            }
        }
    }

    Keys.onEscapePressed: {
        if (textField.focus) {
            textField.modified = false
            setCurrentKey(undoKey)
            textField.focus = false
        }
    }

    Keys.onDownPressed: {
        if (currentHighlightIndex + 1 < model.count) {
            currentHighlightIndex += 1
            control.popup.listView.positionViewAtIndex(currentHighlightIndex, ListView.Contain)
            textField.modified = true
            let item = model.get(currentHighlightIndex)
            setDisplayText(item.key, item.descr)
        }
    }

    Keys.onUpPressed: {
        if (currentHighlightIndex > 0) {
            currentHighlightIndex -= 1
            control.popup.listView.positionViewAtIndex(currentHighlightIndex, ListView.Contain)
            textField.modified = true
            let item = model.get(currentHighlightIndex)
            setDisplayText(item.key, item.descr)
        }
    }

    function filterModel() {
        if (!filterEnabled)
            return

        filter.running = true

        let text = control.editText.trim()

        if (!text.toLowerCase().startsWith(filter.lastFilterText)) {
            if (filter.unfilteredModel) {
                model = filter.unfilteredModel
                filter.unfilteredModel = null
            }
        }
        filter.lastFilterText = text

        if (!text) {
            if (filter.unfilteredModel) {
                model = filter.unfilteredModel
                filter.unfilteredModel = null
            }
            control.popup.listView.positionViewAtIndex(0, ListView.Beginning)
        } else {
            let partialKeyIndex = findPartialKey(text)
            if (partialKeyIndex >= 0) {
                if (!filter.unfilteredModel) {
                    filter.unfilteredModel = model
                }
                control.popup.listView.positionViewAtIndex(partialKeyIndex, ListView.Beginning)
            } else {
                filteredModel.clear()
                if (!filter.unfilteredModel) {
                    filter.unfilteredModel = model
                }
                for (let i = 0; i < filter.unfilteredModel.count; ++i) {
                    let obj = filter.unfilteredModel.get(i);
                    if (textMatchSearch(obj.descr, text)) {
                        filteredModel.append(obj)
                    } else if (obj.search && textMatchSearch(obj.search, text)) {
                        filteredModel.append(obj)
                    }
                }
                model = filteredModel
                control.popup.listView.positionViewAtIndex(0, ListView.Beginning)
            }
        }

        filter.running = false
    }

    function findDescription(descr) {
        if (!model || !descr || descr.length === 0) {
            return -1;
        }

        for (let i = 0; i < model.count; ++i) {
            let obj = model.get(i);
            if (obj.descr.toLowerCase() === descr.toLowerCase()) {
                return i;
            }
        }
        return -1;
    }

    function findKey(key) {
        if (!model || !key || key.length === 0) {
            return -1;
        }

        let lowerCaseKey = key.toLowerCase()
        for (let i = 0; i < model.count; ++i) {
            let obj = model.get(i);
            if (obj.key.toLowerCase() === lowerCaseKey) {
                return i;
            }
        }
        return -1;
    }

    function findPartialKey(key) {
        if (!model || !key || key.length === 0) {
            return 0;
        }

        let lowerCaseKey = key.toLowerCase()
        for (let i = 0; i < model.count; ++i) {
            let obj = model.get(i);
            if (obj.key.toLowerCase().startsWith(lowerCaseKey)) {
                return i;
            }
        }
        return -1;
    }

    function getCurrentItem() {
        if (currentKeyIndex >= 0)
            return model.get(currentKeyIndex);
        return null;
    }

    function getCurrentKey() {
        if (currentKeyIndex >= 0)
            return model.get(currentKeyIndex).key;
        return displayText;
    }

    function getDisplayTextForKey(key) {
        let index = findKey(key);
        if (index >= 0) {
            let item = model.get(findKey(key))
            if (item.descr)
                return item.descr
        }
        return key
    }

    function setCurrentKey(key) {
        undoKey = key
        let index = findKey(key);
        if (index >= 0) {
            currentHighlightIndex = index
            currentKeyIndex = index
            let item = model.get(index)
            undoKey = item.key
            setDisplayText(item.key, item.descr)
        } else {
            currentHighlightIndex = -1
            currentKeyIndex = -1
            undoKey = ""
            setDisplayText(key, "")
        }
    }

    function setDisplayText(key, descr) {
        if (textRole === "descr") {
            if (displayTextIncludesKey) {
                displayText = key ;
                if (displayTextIncludesDescr) {
                    displayText += "   " + descr;
                }
            } else if (descr) {
                displayText = descr;
            } else {
                displayText = key;
            }
        } else {
            displayText = key
        }
    }

    function updateCurrentIndex(text) {
        let index = findKey(text) // Highlight first exact match
        if (index < 0)
            index = findPartialKey(text) // Highlight first partial match
        if (index >= 0) {
            currentHighlightIndex = index
            control.popup.listView.positionViewAtIndex(index, ListView.Beginning)
        } else {
            currentHighlightIndex = -1
            control.popup.listView.positionViewAtIndex(0, ListView.Beginning)
        }
    }

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

}
