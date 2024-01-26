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

    width: 1000 * Stylesheet.pixelScaleRatio
    height: 600 * Stylesheet.pixelScaleRatio

    focus: true

    // Placehoder for setTitle function, it is set by c++
    property var setTitle: null
    property string refQtVersion: "6.5.0";

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
                            // Ctrl + Shift + 9
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

        if (!appSettings.data.creator ||
                (appSettings.data.creator.pubdate < Banana.script.getParamValue('pubdate'))) {
            // Show notification message "updated extention was installed"
            appSettings.setNotificationVisible("show_updated_version_installed", true)
        }
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

    function result() {
        return wdgInvoiceLoader.item.result()
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
        wdgInvoiceLoader.item.updateView()
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

    Rectangle {
        // Notification bar background
        visible: messageBar.visible
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: tabBar.top
        color: Stylesheet.notificationBarColor
    }

    RowLayout {
        id: messageBar

        visible: appSettings.isNotificationVisible("show_updated_version_installed")

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Stylesheet.defaultMargin

        StyledLabel {
             text: "&#x24D8; " +
                   qsTr("An updated version of Estimate and Invoices extension has been installed. The new version is %1. See %2.")
                   .arg(Banana.script.getParamValue('pubdate'))
                   .arg("<a href=\"dlginvoiceedit::changelog\">%1</a>")
                   .arg(qsTr("what's new"))
             textFormat: Text.RichText
             onLinkActivated: (link) => Banana.Ui.showHelp(link);
        }

        Item {
            Layout.fillWidth: true
        }

        StyledLabel {
             text: "Close"
             MouseArea {
                 anchors.fill: parent
                 onClicked: {
                     appSettings.setNotificationVisible("show_updated_version_installed", false)
                 }
             }
        }
    }

    StyledTabBar {
        id: tabBar

        anchors.left: parent.left
        anchors.top: messageBar.visible ? messageBar.bottom : parent.top
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

        Loader {
            id: wdgInvoiceLoader
            source: Banana.application.qtVersion >= refQtVersion ? "WdgInvoice.qml" : "WdgInvoice_OldV.qml"
            onLoaded: {
                item.invoice = invoice
                item.appSettings = appSettings
            }
        }

        // Per ora al suo posto usiamo il loader e usiamo wdgInvoiceLoader.item invece di wdgInvoice
        // WdgInvoice {
        //     id: wdgInvoice
        //     invoice: invoice
        //     appSettings: appSettings
        // }

        WdgSettings {
            id: wdgAppSettings
            invoice: invoice
            appSettings: appSettings
            wdgInvoice: wdgInvoiceLoader.item
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
                            wdgInvoiceLoader.item.updateView()

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

    RowLayout {  // Invoice's button's bar
        id: buttonBar

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Stylesheet.defaultMargin

        //                StyledButton {
        //                    text: qsTr("Export...")
        //                    onClicked: {
        //                        if (activeFocusItem)
        //                            activeFocusItem.focus = false

        //                        exportInvoice()
        //                    }
        //                }

        StyledButton {
            text: qsTr("Help")
            onClicked: showHelp()
        }

        Item {
            Layout.fillWidth: true
        }

        StyledButton {
            text: qsTr("Print")
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoiceLoader.item.printInvoice()
            }
        }

        StyledButton {
            text: qsTr("Create invoice")
            visible: invoice.isEstimate() && !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoiceLoader.item.createInvoiceFromEstimate()
            }
        }

        StyledButton {
            id: copyButton
            text: qsTr("Copy")
            visible: !invoice.isNewDocument
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                wdgInvoiceLoader.item.duplicateInvoice()
            }
        }

        StyledButton {
            text: qsTr("Save")
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
