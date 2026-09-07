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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "."
import "./components"

Item {
    id: window

    // Never request a size bigger than the screen: on small displays (tablet,
    // laptop with a low-resolution screen) a fixed 1000x600 dialog can end up
    // taller/wider than the available space, pushing the button bar (Save,
    // Close...) off-screen and out of reach. If the screen is too small on
    // EITHER axis (e.g. a phone in portrait: narrow but tall) we treat it as
    // a small/mobile screen and go fullscreen on both axes together, instead
    // of shrinking width and height independently - otherwise a phone would
    // end up full-width but not full-height (or vice versa in landscape).
    // On desktop the screen is always bigger than 1000x600 on both axes, so
    // this has no effect there. Screen.width/height fall back to 0 if not yet
    // resolved (e.g. before the item is placed in a window), in which case we
    // keep the original fixed size.
    readonly property bool isSmallScreen: Screen.width > 0 && Screen.height > 0 &&
                                           (Screen.width < 1000 * Stylesheet.pixelScaleRatio ||
                                            Screen.height < 600 * Stylesheet.pixelScaleRatio)

    width: Screen.width > 0 ? (isSmallScreen ? Screen.width : 1000 * Stylesheet.pixelScaleRatio)
                             : 1000 * Stylesheet.pixelScaleRatio
    height: Screen.height > 0 ? (isSmallScreen ? Screen.height : 600 * Stylesheet.pixelScaleRatio)
                              : 600 * Stylesheet.pixelScaleRatio

    // True when the buttons have to be laid out two per row instead of one long line.
    // Unlike the form above them, these are anchored to the bottom of the dialog, outside
    // the scrolling area: a button that runs past the right edge is unreachable, since no
    // amount of scrolling brings it back. On a phone that means being unable to close the
    // dialog at all - an estimate shows six buttons ("Create invoice" on top of the usual
    // five) and loses Close entirely.
    //
    // Deliberately the same condition that stacks the form into one column, rather than a
    // second threshold of its own: a row of buttons cannot measure whether it fits without
    // the column count depending on the width it is trying to decide, so any private
    // threshold would be a guess at how wide six translated labels are - and a guess that
    // is too low is unusable, not just ugly. Wherever the form is too narrow for two
    // columns, six buttons on one row are not plausible either.
    readonly property bool compactButtonBar: wdgInvoice.compactLayout

    focus: true

    // Placehoder for setTitle function, it is set by c++
    property var setTitle: null

    property int result: 0;

    Keys.onEscapePressed: function(event) {
        focus = true
        if (invoice.isModified) {
            cancelConfirmDialog.open()
            event.accepted = true
        } else {
            closeDialog()
            event.accepted = true
        }
    }

    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_9) &&
                            (event.modifiers & Qt.AltModifier) &&
                            (event.modifiers & Qt.ControlModifier)) {
                            // Ctrl + Alt + 9
                            pixelMetricsDialog.visible = true
                            event.accepted = true
                        }
                    }

    Keys.onReleased: (event) => {
                         if (event.key === Qt.Key_Help || event.key === Qt.Key_F1) {
                             showHelp()
                             event.accepted = true
                         }
                     }

    Component.onCompleted: {
        appSettings.loadSettings()
        // Check for changing dialog title
        if (Banana.document.cursor.tableName === "Invoices")
            setIsEstimate(false)
        else
            setIsEstimate(true)
    }

    // Interface

    function getInvoice(invoice) {
        return invoice.json
    }

    function getTitle() {
        let title = qsTr("Document")
        if (invoice.json.document_info.number) {
            if (invoice.isEstimate()) {
                title = qsTr("Estimate %1").arg(invoice.json.document_info.number)
            } else  {
                title = qsTr("Invoice %1").arg(invoice.json.document_info.number)
            }
        } else {
            if (invoice.isEstimate()) {
                title = qsTr("New estimate %1").arg(invoice.json.document_info.number)
            } else  {
                title = qsTr("New invoice %1").arg(invoice.json.document_info.number)
            }
        }
        if (invoice.isReadOnly) {
            title += " [" + qsTr("Read only") + "]"
        } else if (invoice.isModified) {
            title += " *"
        }
        return title
    }

    function setIsNew(newDocument) {
        invoice.setIsNew(newDocument)
    }

    function setIsModified(modified) {
        invoice.setIsModified(modified)
    }

    function setIsEstimate(estimate) {
        invoice.setIsEstimate(estimate)
    }

    function setIsReadOnly(readOnly) {
        invoice.isReadOnly = readOnly
        updateTitle()
    }

    function setInvoice(json) {
        invoice.setInvoice(json)
        wdgInvoice.updateView()
        updateTitle()
    }

    function setPosition(tabPos) {
        invoice.setPosition(tabPos)
    }

    function setDocumentChange(docChange) {
        invoice.setDocumentChange(docChange)
    }

    function showHelp() {
        if (tabBar.currentIndex === 1) {
            Banana.Ui.showHelp("dlginvoiceedit::settings");
        } else {
            Banana.Ui.showHelp("dlginvoiceedit");
        }
    }

    function updateTitle() {
        let title = getTitle()
        if (setTitle) {
            window.setTitle(title)
        }
    }

    function closeDialog() {
        appSettings.saveSettings()
        Qt.quit()
    }

    // Data objects

    DevSettings {
        id: devSettings
    }

    AppSettings {
        id: appSettings
        devSettings: devSettings
    }

    Invoice {
        id: invoice
        onInvoiceChanged: {
            updateTitle()
        }
    }

    // Visual content

    // Questo margine permette sotto windows di separare la tab bar dal windows frame,
    // che essendo bianco si fondono e non creano alcuna separazione
    // Per semplicità applichiamo questo spazio a tutti i sistemi operativi
    property int tabBarTopMargin: 12 * Stylesheet.pixelScaleRatio

    Rectangle {
        // Window background
        anchors.fill: parent
        color: Stylesheet.baseColor
    }

    Rectangle {
        // Tab bar background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: tabBar.bottom
        color: Stylesheet.buttonColor
    }

    StyledTabBar {
        id: tabBar

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -1 // Don't draw left button border
        anchors.topMargin: tabBarTopMargin

        StyledTabButton {
            text: qsTr("Invoice")
        }

        StyledTabButton {
            text: qsTr("Settings")
        }

        StyledTabButton {
            id: tabButtonSource
            text: qsTr("Source")
            visible: appSettings.isInternalVersion()
            onVisibleChanged: tabBar.removeItem(tabButtonSource)
        }

        StyledTabButton {
            id: tabDevelopment
            text: qsTr("Development")
            visible: appSettings.isInternalVersion()
            onVisibleChanged: tabBar.removeItem(tabDevelopment)
        }

        StyledTabButton {
            id: tabChangeLog
            text: qsTr("Changelog")
            visible: appSettings.isInternalVersion()
            onVisibleChanged: tabBar.removeItem(tabChangeLog)
        }
    }

    StackLayout {
        id: tabStackLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabBar.bottom
        anchors.bottom: buttonBar.top

        currentIndex: tabBar.currentIndex

        WdgInvoice {
            id: wdgInvoice
            invoice: invoice
            appSettings: appSettings
        }

        WdgSettings {
            id: wdgAppSettings
            invoice: invoice
            appSettings: appSettings
            wdgInvoice: wdgInvoice
        }

        WdgSource {
            id: wdgSource
            format: "json"
            isReadOnly: invoice.isReadOnly

            onRevertRequested: {
                wdgSource.clearError()
                text = JSON.stringify(invoice.json, null, "    ")
                isModified = false
            }

            onVisibleChanged: {
                if (visible) {
                    if (!error) {
                        text = JSON.stringify(invoice.json, null, "    ")
                    }

                } else {
                    if (isModified) {
                        try {
                            let invoiceObj = JSON.parse(text)
                            invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                            invoice.json = invoiceObj
                            invoice.setIsModified(true)
                            wdgInvoice.updateView()

                        } catch (err) {
                            setError(err.message, err.lineNumber)
                            jsonErrorMessageDialog.text = err.toString()
                            jsonErrorMessageDialog.visible = true
                            error = true

                        }
                    }
                }
            }
        }

        WdgDevelopment {
            id: wdgMessages
            appSettings: appSettings
            devSettings: devSettings
            invoice: invoice
            onGoToHome: {
                tabBar.currentIndex = 0
            }
        }

        WdgChangelog {
            text: getText()
            textFormat: TextEdit.MarkdownText
            function getText() {
                let file = Banana.IO.getLocalFile("file:script/changelog.md")
                return file.read()
            }
        }

    }

    Rectangle {
        // Button bar background, mirrors the tab bar background above.
        // Extends a bit above the buttons themselves, so they don't sit flush
        // against the top edge of the colored area.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: buttonBar.top
        anchors.topMargin: -Stylesheet.defaultMargin
        anchors.bottom: parent.bottom
        color: Stylesheet.buttonColor
    }

    GridLayout {  // Invoice's button's bar
        id: buttonBar

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Stylesheet.defaultMargin

        // One row while everything fits, three per row when it does not: six buttons then
        // take two rows rather than three, which matters because this bar eats into the
        // form on a screen that has little height to spare. A fixed column count rather
        // than free wrapping, so the rows come out even instead of leaving a single button
        // stranded at the bottom.
        columns: window.compactButtonBar ? 3 : 7
        columnSpacing: Stylesheet.defaultMargin
        rowSpacing: Stylesheet.defaultMargin

        //                StyledButton {
        //                    text: qsTr("Export...")
        //                    onClicked: {
        //                        if (activeFocusItem)
        //                            activeFocusItem.focus = false

        //                        exportInvoice()
        //                    }
        //                }

        StyledButton {
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Help")
            onClicked: showHelp()
        }

        Item {
            // Splits Help from the actions on a single row. On two rows it would eat one
            // of the cells, so it steps aside and the buttons share the width evenly.
            visible: !window.compactButtonBar
            Layout.fillWidth: true
        }

        StyledButton {
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Print")
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.printInvoice()
            }
        }

        StyledButton {
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Create invoice")
            visible: invoice.isEstimate() && !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.createInvoiceFromEstimate()
            }
        }

        StyledButton {
            id: copyButton
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Copy")
            visible: !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.duplicateInvoice()
            }
        }

        StyledButton {
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Save")
            primary: true
            visible: !invoice.isReadOnly
            enabled: invoice.isModified
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                if (!invoice.isReadOnly) {
                    invoice.save()
                    result = 1
                    closeDialog()
                }
            }
        }

        StyledButton {
            Layout.fillWidth: window.compactButtonBar
            // Allowed to shrink below its label. Without this a cell too narrow for a long
            // translation (German is half again as long as Italian here) would not give
            // way, and the grid would push the last column off the edge again - the very
            // failure this bar was rearranged to prevent. The label elides instead.
            Layout.minimumWidth: 0
            text: invoice.isModified && !invoice.isReadOnly ? qsTr("Cancel") : qsTr("Close")
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                if (invoice.isModified && !invoice.isReadOnly) {
                    cancelConfirmDialog.open()
                } else {
                    closeDialog()
                }
            }
        }
    }


    SimpleMessageDialog { // Error message dialog
        id: errorMessageDialog
        visible: false
        y: tabStackLayout.y
    }

    SimpleMessageDialog { // Error message dialog
        id: jsonErrorMessageDialog
        visible: false
        y: tabStackLayout.y
        standardButtons: Dialog.Ok
        onAccepted: {
            tabBar.currentIndex = tabButtonSource.TabBar.index
        }
    }

    SimpleMessageDialog { // Confirm discard edit dialog
        id: cancelConfirmDialog
        width: 300 * Stylesheet.pixelScaleRatio
        height: 120 * Stylesheet.pixelScaleRatio
        text: qsTr("Discard changes?")
        standardButtons: Dialog.Discard | Dialog.Cancel
        visible: false;
        onRejected: {
            cancelConfirmDialog.close()
        }
        onDiscarded: {
            closeDialog()
        }
    }

    DlgPixelMetrics {
        id: pixelMetricsDialog
    }
}
