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
import QtQuick.Layouts

import "./components"

import "../base/utils.js" as Utils

/**
 * Goes straight to one document of the table, instead of walking to it with the arrows.
 *
 * The list is handed in by whoever opens this - see DlgInvoice.collectDocuments(), which
 * reads it from the columns of the table rather than from the documents themselves. Here
 * there is only the choosing: type to narrow the list, the arrows to move through it,
 * Return to open, Escape to leave it alone.
 */
Dialog {
    id: dialog

    /** The documents to choose from: see DlgInvoice.collectDocuments for their shape. */
    property var documents: []

    /** Which row of the table the open document is on, so it can be marked in the list. */
    property int currentRowNr: -1

    /** Centre it on a narrow screen, where the top of the screen belongs to the notch. */
    property bool centered: false
    property real topY: 0

    signal documentChosen(int rowNr)

    x: Math.max(Stylesheet.defaultMargin, (parent.width - width) / 2)
    y: centered ? Math.max(Stylesheet.defaultMargin, (parent.height - height) / 2) : topY

    width: Math.min(560 * Stylesheet.pixelScaleRatio,
                    parent.width - 2 * Stylesheet.defaultMargin)
    height: Math.min(460 * Stylesheet.pixelScaleRatio,
                     parent.height - 2 * Stylesheet.defaultMargin)

    modal: true
    visible: false
    padding: Stylesheet.defaultMargin

    background: Rectangle {
        color: Stylesheet.baseColor
        radius: Stylesheet.cornerRadius
        border.color: Stylesheet.borderColor
    }

    ListModel {
        id: results
    }

    /** Opens the list, with nothing typed and the open document picked out. */
    function openWith(documentList, rowNr) {
        documents = documentList ? documentList : []
        currentRowNr = rowNr
        searchField.text = ""
        applyFilter("")
        visible = true
        searchField.forceActiveFocus()
    }

    /* Narrows the list to what was typed. The comparison is the one the customer selector
       uses - every word of the search has to begin a word of the entry - so that searching
       works the same way wherever it is offered in this dialog. */
    function applyFilter(search) {
        results.clear()

        let selected = 0
        let query = search ? search.trim() : ""

        for (let i = 0; i < documents.length; ++i) {
            let doc = documents[i]
            if (query.length > 0 && !Utils.textMatchSearch(doc.search, query))
                continue
            if (doc.rowNr === currentRowNr)
                selected = results.count
            results.append(doc)
        }

        resultsView.currentIndex = results.count > 0 ? selected : -1
        resultsView.positionViewAtIndex(resultsView.currentIndex, ListView.Contain)
    }

    function chooseCurrent() {
        if (resultsView.currentIndex < 0 || resultsView.currentIndex >= results.count)
            return
        let rowNr = results.get(resultsView.currentIndex).rowNr
        visible = false
        documentChosen(rowNr)
    }

    contentItem: ColumnLayout {
        spacing: Stylesheet.spacingBase

        StyledTextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Number, customer, object, amount")

            onTextChanged: dialog.applyFilter(text)

            // The list is walked from the field, so that the hands never leave it.
            Keys.onDownPressed: function(event) {
                resultsView.incrementCurrentIndex()
                event.accepted = true
            }
            Keys.onUpPressed: function(event) {
                resultsView.decrementCurrentIndex()
                event.accepted = true
            }
            Keys.onReturnPressed: function(event) {
                dialog.chooseCurrent()
                event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
                dialog.chooseCurrent()
                event.accepted = true
            }
            Keys.onEscapePressed: function(event) {
                dialog.visible = false
                event.accepted = true
            }
        }

        StyledLabel {
            Layout.fillWidth: true
            visible: results.count === 0
            text: qsTr("No document found")
        }

        ListView {
            id: resultsView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: results
            currentIndex: -1
            // The keyboard stays in the search field, which drives this view by hand.
            keyNavigationEnabled: false
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {}

            delegate: Item {
                required property int index
                required property string number
                required property string date
                required property string customer
                required property string amount
                required property bool isCurrent

                width: ListView.view.width
                implicitHeight: Stylesheet.controlHeight + Stylesheet.spacingTight

                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: Stylesheet.spacingTight
                    radius: Stylesheet.cornerRadiusSmall
                    color: index === resultsView.currentIndex ? Stylesheet.accentSurfaceColor :
                               rowHover.hovered ? Stylesheet.hoverColor : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Stylesheet.spacingBase
                    anchors.rightMargin: Stylesheet.spacingBase + Stylesheet.spacingTight
                    spacing: Stylesheet.spacingBase

                    StyledLabel {
                        // The number, and a mark on the document that is already open.
                        Layout.minimumWidth: 70 * Stylesheet.pixelScaleRatio
                        color: Stylesheet.textColor
                        font.bold: isCurrent
                        elide: Text.ElideRight
                        text: number
                    }

                    StyledLabel {
                        Layout.minimumWidth: 80 * Stylesheet.pixelScaleRatio
                        text: date
                    }

                    StyledLabel {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        color: Stylesheet.textColor
                        elide: Text.ElideRight
                        text: customer
                    }

                    StyledLabel {
                        horizontalAlignment: Text.AlignRight
                        Layout.minimumWidth: 80 * Stylesheet.pixelScaleRatio
                        color: Stylesheet.textColor
                        text: amount
                    }
                }

                HoverHandler {
                    id: rowHover
                }

                TapHandler {
                    onTapped: {
                        resultsView.currentIndex = index
                        dialog.chooseCurrent()
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        delegate: StyledButton {}
        background: Rectangle {
            x: 1
            y: 1
            color: Stylesheet.baseColor
        }

        StyledButton {
            text: qsTr("Open")
            primary: true
            enabled: results.count > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }

        StyledButton {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    onAccepted: chooseCurrent()
    onRejected: visible = false
}
