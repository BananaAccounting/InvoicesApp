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

    // Never larger than the screen: a fixed 1000x600 pushed the button bar out of reach on
    // a small display, and both axes go full screen together or a phone ends up full width
    // but not full height. Mobile is asked of the platform, not of the size: there is no
    // window manager there, and an iPad in landscape passed the size test by coincidence.
    readonly property bool isSmallScreen: Qt.platform.os === "ios" || Qt.platform.os === "android" ||
                                          (Screen.width > 0 && Screen.height > 0 &&
                                           (Screen.width < 1000 * Stylesheet.pixelScaleRatio ||
                                            Screen.height < 600 * Stylesheet.pixelScaleRatio))

    width: Screen.width > 0 ? (isSmallScreen ? Screen.width : 1000 * Stylesheet.pixelScaleRatio)
                             : 1000 * Stylesheet.pixelScaleRatio
    height: Screen.height > 0 ? (isSmallScreen ? Screen.height : 600 * Stylesheet.pixelScaleRatio)
                              : 600 * Stylesheet.pixelScaleRatio

    // True when the bar keeps only Save and Close and the rest move to the overflow menu:
    // six buttons do not fit a phone, and this bar is outside the scrolling area, so a
    // button past the right edge is unreachable. The same condition as the single column
    // form on purpose - a private threshold would be a guess at six translated labels.
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
        let title = getDocumentName()
        if (invoice.isReadOnly) {
            title += " [" + qsTr("Read only") + "]"
        } else if (invoice.isModified) {
            title += " *"
        }
        return title
    }

    // The document being edited, "Invoice 123" or "Estimate 123": the title without the
    // read only or modified markers. Also shown at the top of the form on a narrow
    // display, where the window title is not shown - see WdgInvoice.documentName.
    function getDocumentName() {
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

    // Room the system keeps for itself on a phone: notch, status bar, gesture bar. The bars
    // and the pages move inside these margins, the backgrounds still reach the edges. Zero
    // on the desktop. Read from the root, which the host positions: an item positioned from
    // its own SafeArea would be a binding loop.
    //
    // SafeArea needs Qt 6.9 and Banana Plus carries 6.8.6, where the name is unknown and
    // reading it raised a ReferenceError per margin. typeof is the one way to ask about a
    // name that may not exist: anything else raises the error again.
    readonly property bool hasSafeArea: typeof SafeArea !== "undefined"
    readonly property real safeAreaTop: hasSafeArea ? SafeArea.margins.top : 0
    readonly property real safeAreaBottom: hasSafeArea ? SafeArea.margins.bottom : 0
    readonly property real safeAreaLeft: hasSafeArea ? SafeArea.margins.left : 0
    readonly property real safeAreaRight: hasSafeArea ? SafeArea.margins.right : 0

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
        anchors.leftMargin: safeAreaLeft - 1 // Don't draw left button border
        anchors.topMargin: tabBarTopMargin + safeAreaTop

        StyledTabButton {
            text: invoice.isEstimate() ? qsTr("Estimate") : qsTr("Invoice")
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
        anchors.leftMargin: safeAreaLeft
        anchors.rightMargin: safeAreaRight

        currentIndex: tabBar.currentIndex

        WdgInvoice {
            id: wdgInvoice
            invoice: invoice
            appSettings: appSettings
            // Built here, and not in the form, so it uses the very texts of the window
            // title, which are already translated. signalInvoiceChanged is read so the
            // binding follows a change of number: the json itself notifies nothing.
            documentName: invoice.signalInvoiceChanged && invoice.json && invoice.json.document_info ?
                              getDocumentName().trim() : ""
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
        anchors.bottomMargin: Stylesheet.defaultMargin + safeAreaBottom
        anchors.leftMargin: Stylesheet.defaultMargin + safeAreaLeft
        anchors.rightMargin: Stylesheet.defaultMargin + safeAreaRight

        // Seven columns, always: one row in both layouts. Narrow, only three controls remain,
        // so there is nothing to wrap. Every row this bar takes is a row the form loses.
        columns: 7
        columnSpacing: Stylesheet.defaultMargin
        rowSpacing: Stylesheet.defaultMargin

        StyledButton {
            // Opens the commands that do not fit a phone's bar. Only Save and Close stay
            // out here: Close in particular is the only way off this dialog on a device
            // with no keyboard, so it never goes behind a second tap.
            id: overflowButton
            visible: window.compactButtonBar
            text: "⋮"
            Layout.minimumWidth: 44 * Stylesheet.pixelScaleRatio
            Accessible.name: qsTr("More commands")
            onClicked: overflowMenu.popup(overflowButton, 0, -overflowMenu.height)
        }

        //                StyledButton {
        //                    text: qsTr("Export...")
        //                    onClicked: {
        //                        if (activeFocusItem)
        //                            activeFocusItem.focus = false

        //                        exportInvoice()
        //                    }
        //                }

        StyledButton {
            // Allowed to shrink below its label: a cell too narrow for a long translation
            // would otherwise push the last column off the edge. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Help")
            visible: !window.compactButtonBar
            onClicked: showHelp()
        }

        Item {
            // Pushes Save and Close to the right, away from Help - or, on a narrow screen,
            // away from the overflow button.
            Layout.fillWidth: true
        }

        StyledButton {
            // Allowed to shrink below its label - see the first button above.
            Layout.minimumWidth: 0
            text: qsTr("Print")
            visible: !window.compactButtonBar
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.printInvoice()
            }
        }

        StyledButton {
            // Allowed to shrink below its label - see the first button above.
            Layout.minimumWidth: 0
            text: qsTr("Create invoice")
            visible: !window.compactButtonBar && invoice.isEstimate() && !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.createInvoiceFromEstimate()
            }
        }

        StyledButton {
            id: copyButton
            // Allowed to shrink below its label - see the first button above.
            Layout.minimumWidth: 0
            text: qsTr("Copy")
            visible: !window.compactButtonBar && !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoice.duplicateInvoice()
            }
        }

        StyledButton {
            // Allowed to shrink below its label - see the first button above.
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
            // Allowed to shrink below its label - see the first button above.
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


    /* An entry of this dialog's menus, drawn in the dialog's colours: the iOS style paints
       menu backgrounds from images chosen by the application's colour scheme, which came out
       dark grey with black text in light mode, and each desktop style reads its own palette
       roles. The background needs an implicit size, or the menu appears not to open. */
    component StyledMenuEntry: MenuItem {
        id: entry

        palette.text: entry.down || entry.highlighted ? Stylesheet.accentTextColor : Stylesheet.textColor
        palette.windowText: entry.palette.text

        // The text is drawn here too, for the same reason as the background: the Material
        // style, which Android uses, takes the colour of an entry from its own theme rather
        // than from the palette, and that theme stayed light - black text on a dark menu.
        contentItem: Text {
            text: entry.text
            font: entry.font
            color: entry.down || entry.highlighted ? Stylesheet.accentTextColor :
                       entry.enabled ? Stylesheet.textColor : Stylesheet.mutedTextColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 200 * Stylesheet.pixelScaleRatio
            implicitHeight: 34 * Stylesheet.pixelScaleRatio
            color: entry.down || entry.highlighted ? Stylesheet.accentColor : "transparent"
            radius: Stylesheet.cornerRadiusSmall
        }
    }

    Menu {
        // The commands that leave the bottom bar on a narrow screen, each mirroring the
        // button of the same name. Opening the menu takes the active focus, which commits
        // whatever field was being edited.
        id: overflowMenu

        // A lighter shade in dark mode so the menu stands out from the dialog, the system
        // colours in the light theme: see Stylesheet.menuWindowColor. The palette is still
        // handed to the style for the parts it draws itself, such as a scroll indicator.
        palette.window: Stylesheet.menuWindowColor
        palette.windowText: Stylesheet.systemPalette.windowText
        palette.base: Stylesheet.menuBaseColor
        palette.text: Stylesheet.textColor
        palette.highlight: Stylesheet.accentColor
        palette.highlightedText: Stylesheet.accentTextColor

        background: Rectangle {
            implicitWidth: 200 * Stylesheet.pixelScaleRatio
            implicitHeight: 40 * Stylesheet.pixelScaleRatio
            color: Stylesheet.menuWindowColor
            border.color: Stylesheet.borderColor
            radius: Stylesheet.cornerRadius
        }

        StyledMenuEntry {
            text: qsTr("Help")
            onTriggered: showHelp()
        }

        StyledMenuEntry {
            text: qsTr("Print")
            onTriggered: wdgInvoice.printInvoice()
        }

        StyledMenuEntry {
            // An invisible menu item still reserves its row, so it has to give up its
            // height as well to disappear.
            text: qsTr("Create invoice")
            visible: invoice.isEstimate() && !invoice.isNewDocument
            height: visible ? implicitHeight : 0
            onTriggered: wdgInvoice.createInvoiceFromEstimate()
        }

        StyledMenuEntry {
            text: qsTr("Copy")
            visible: !invoice.isNewDocument
            height: visible ? implicitHeight : 0
            onTriggered: wdgInvoice.duplicateInvoice()
        }
    }

    SimpleMessageDialog { // Error message dialog
        id: errorMessageDialog
        visible: false
        // Under the tab bar on a wide window, centred on a narrow one where the top of the
        // screen belongs to the notch.
        topY: tabStackLayout.y
        centered: wdgInvoice.compactLayout
    }

    SimpleMessageDialog { // Error message dialog
        id: jsonErrorMessageDialog
        visible: false
        topY: tabStackLayout.y
        centered: wdgInvoice.compactLayout
        standardButtons: Dialog.Ok
        onAccepted: {
            tabBar.currentIndex = tabButtonSource.TabBar.index
        }
    }

    SimpleMessageDialog { // Confirm discard edit dialog
        id: cancelConfirmDialog
        centered: wdgInvoice.compactLayout
        // Capped like the component's own default: this one asks for less room, but not
        // more than the window has.
        width: Math.min(300 * Stylesheet.pixelScaleRatio,
                        parent.width - 2 * Stylesheet.defaultMargin)
        height: Math.min(120 * Stylesheet.pixelScaleRatio,
                         parent.height - 2 * Stylesheet.defaultMargin)
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
