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

import "../base/settings.js" as Settings
import "../base/vatcodes.js" as VatCodes
import "./components"

Item {
    id: root

    required property Invoice invoice
    required property AppSettings appSettings
    required property WdgInvoice wdgInvoice

    // Style properties
    property int stylePropertyWidth: 220 * Stylesheet.pixelScaleRatio
    property int styleLabelWidth: 260 * Stylesheet.pixelScaleRatio
    property int styleButtonMinWidth: 140 * Stylesheet.pixelScaleRatio
    property int styleSectionSeparatorHeight: 4 * Stylesheet.defaultMargin
    property int styleColumnSpacing: 2.5 * Stylesheet.defaultMargin
    property int styleRowSpacing: 0.5 * Stylesheet.defaultMargin

    /* True when a label and its control no longer fit side by side. The threshold is what a
       row measures - label, control, gap, margins - so it follows those constants, and it is
       measured on the scroll area rather than on Screen, whose unit differs across devices.

       The per view rows keep their three switches on one line: the columns are the views, so
       a switch pushed onto the next line would stand for a different view than its title. */
    readonly property bool compactLayout: scrollView.availableWidth > 0 &&
                                          scrollView.availableWidth < styleLabelWidth + stylePropertyWidth +
                                                                      styleColumnSpacing + 2 * Stylesheet.defaultMargin

    property string programLanguage: Banana.application.locale.substring(0, 2)
    property string documentLanguage: invoice.json && invoice.json.document_info.locale && invoice.signalInvoiceChanged?
                                         invoice.json.document_info.locale.substring(0, 2) :
                                         programLanguage

    VatModesModel {
        id: vatModesModel
    }

    ListModel {
        id: taxCodesModel
    }

    Component.onCompleted: {
        loadTaxCodes()
    }

    ScrollView {
        id: scrollView
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        anchors.fill: parent
        anchors.margins: Stylesheet.defaultMargin
        //anchors.topMargin: styleSectionSeparatorHeight / 2

        // Pinned to the viewport: left unset, a ScrollView takes its content width from the
        // widest child, here a label's full text on one line, and would then hand every
        // fillWidth below 700 points on a 400 point screen. Height is left alone.
        contentWidth: availableWidth - ScrollBar.vertical.width

        ColumnLayout {
            width: scrollView.contentWidth
            height: scrollView.availableHeight

            ColumnLayout {
                Layout.fillWidth: true

                StyledLabel{
                    text: qsTr("New documents")
                    color: Stylesheet.textColor
                    font: Stylesheet.sectionTitleFont
                }

                StyledLabel {
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 200
                    text: qsTr("Changes to the following settings are applied to the current document and to future documents. If you only wish to change the current document use the Invoice tab.")
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    Layout.topMargin: styleSectionSeparatorHeight / 2

                    StyledLabel{
                        text: qsTr("Invoice title")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "new_invoice_title"
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Estimate title")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }
                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "new_estimate_title"
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged  ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("VAT mode")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledKeyDescrComboBox {
                        Layout.fillWidth: root.compactLayout
                        id: settings_vat_mode
                        implicitWidth: stylePropertyWidth

                        model: vatModesModel
                        editable: false
                        textRole: "descr"
                        listItemTextIncludesKey: false

                        Connections {
                            target: appSettings
                            function onDataChanged() {
                                if (appSettings.data.new_documents.vat_mode) {
                                    settings_vat_mode.setCurrentKey(appSettings.data.new_documents.vat_mode)
                                }
                            }
                        }

                        onCurrentKeySet: function(key, isExistingKey) {
                            appSettings.data.new_documents.vat_mode = key
                            appSettings.modified = true
                            invoice.setVatMode(key)
                             wdgInvoice.calculateInvoice()
                         }
                     }
                 }

                 GridLayout {
                     columns: root.compactLayout ? 1 : 2
                     Layout.fillWidth: root.compactLayout
                     StyledLabel{
                         text: qsTr("Default VAT code")
                         Layout.preferredWidth: styleLabelWidth
                         Layout.fillWidth: root.compactLayout
                         Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                         wrapMode: Text.WordWrap
                     }

                     StyledKeyDescrComboBox {
                         Layout.fillWidth: root.compactLayout
                         id: settings_default_vat_code
                         implicitWidth: stylePropertyWidth

                         model: taxCodesModel
                         editable: false
                         textRole: "descr"
                         listItemTextIncludesKey: true
                         displayTextIncludesKey: true
                         displayTextIncludesDescr: false;

                         Connections {
                             target: appSettings
                             function onDataChanged() {
                                 if (appSettings.data.new_documents.default_vat_code) {
                                     settings_default_vat_code.setCurrentKey(appSettings.data.new_documents.default_vat_code)
                                 }
                             }
                         }

                         onCurrentKeySet: function(key, isExistingKey) {
                             appSettings.data.new_documents.default_vat_code = key
                             appSettings.modified = true
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Currency")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        implicitWidth: stylePropertyWidth
                        text: appSettings.data.new_documents.currency
                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.new_documents.currency = text
                                appSettings.modified = true
                                invoice.json.document_info.currency = text
                                invoice.setIsModified(true)
                                focus = false
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Decimals")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        implicitWidth: stylePropertyWidth
                        text: appSettings.data.new_documents.decimals_amounts.toString()
                        validator: IntValidator{bottom: 0; top: 24;}
                        onEditingFinished: {
                            if (modified) {
                                let decimals = Number(text)
                                if (Number.isNaN(decimals)) {
                                    text: appSettings.data.new_documents.decimals_amounts.toString()
                                } else {
                                    appSettings.data.new_documents.decimals_amounts = decimals
                                    appSettings.modified = true
                                    invoice.json.document_info.decimals_amounts = decimals
                                    invoice.setIsModified(true)
                                    wdgInvoice.calculateInvoice()
                                }
                                focus = false
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Total rounding")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        implicitWidth: stylePropertyWidth
                        text: Banana.Converter.toLocaleNumberFormat(appSettings.data.new_documents.rounding_total)
                        validator: DoubleValidator{bottom: 0.00; top: 1.00; decimals: 24;}
                        onEditingFinished: {
                            if (modified) {
                                let rouding = Banana.Converter.toInternalNumberFormat(text)
                                appSettings.data.new_documents.rounding_total =rouding
                                appSettings.modified = true
                                invoice.json.document_info.rounding_total = rouding
                                invoice.setIsModified(true)
                                wdgInvoice.calculateInvoice()
                                focus = false
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Invoice payment term (days)")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        implicitWidth: stylePropertyWidth
                        text: appSettings.data.new_documents.payment_term_days
                        validator: IntValidator{bottom: 0; top: 3650;}
                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.new_documents.payment_term_days = text
                                appSettings.modified = true
                                focus = false
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Estimate validity (days)")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        implicitWidth: stylePropertyWidth
                        text: appSettings.data.new_documents.estimate_validity_days
                        validator: IntValidator{bottom: 0; top: 3650;}
                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.new_documents.estimate_validity_days = text
                                appSettings.modified = true
                                focus = false
                            }
                        }
                    }
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.separatorColor
            }

            ColumnLayout {
                Layout.fillWidth: true

                StyledLabel{
                    text: qsTr("Invoice custom fields")
                    color: Stylesheet.textColor
                    font: Stylesheet.sectionTitleFont
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 1"), "show_invoice_custom_field_1")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_1"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }

                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 2"), "show_invoice_custom_field_2")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_2"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }

                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 3"), "show_invoice_custom_field_3")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_3"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 4"), "show_invoice_custom_field_4")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_4"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 5"), "show_invoice_custom_field_5")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_5"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 6"), "show_invoice_custom_field_6")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_6"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 7"), "show_invoice_custom_field_7")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_7"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Custom field 8"), "show_invoice_custom_field_8")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        Layout.fillWidth: root.compactLayout
                        property string trId: "invoice_custom_field_8"
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: stylePropertyWidth
                        text: appSettings.signalTranslationsChanged ?
                                  Settings.getTranslatedText(appSettings.data, trId, programLanguage) :
                                  trId
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dlgTranslations.trId = parent.trId
                                dlgTranslations.appSettings = appSettings
                                dlgTranslations.visible = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.separatorColor
            }

            ColumnLayout {
                // Without this the section sizes itself to its content, and nothing inside is
                // told how much room it has. A plain "width" does not do it: a layout owns the
                // size of its children.
                Layout.fillWidth: true
                height: scrollView.availableHeight

                StyledLabel{
                    text: qsTr("Tools")
                    color: Stylesheet.textColor
                    font: Stylesheet.sectionTitleFont
                }

                Item {
                    Layout.fillHeight: true
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    visible: appSettings.isInternalVersion()

                    StyledLabel{
                        text: qsTr("Edit current settings")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledButton {
                        text: qsTr("Edit settings")
                        Layout.minimumWidth: styleButtonMinWidth
                        onClicked: {
                            dlgEditSettings.text = JSON.stringify(appSettings.data, null, "   ")
                            dlgEditSettings.format = "json";
                            dlgEditSettings.isModified = false
                            dlgEditSettings.visible = true
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Restore default settings")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledButton {
                        text: qsTr("Restore settings")
                        Layout.minimumWidth: styleButtonMinWidth
                        onClicked: restoreSettingsConfirmationDialog.visible = true
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 1 : 2
                    Layout.fillWidth: root.compactLayout
                    StyledLabel{
                        text: qsTr("Clear settings")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledButton {
                        text: qsTr("Clear settings")
                        Layout.minimumWidth: styleButtonMinWidth
                        onClicked: clearSettingsConfirmationDialog.visible = true
                    }
                }
            }

        }
    }

    StyledSwitch {
        id: width_reference
        visible: false
    }

    DlgEditSource {
        id: dlgEditSettings
        height: root.height - 50 * Stylesheet.pixelScaleRatio
        width: root.width - 200 * Stylesheet.pixelScaleRatio
        modality: Qt.WindowModal
        font.family: "Courier"

        onAccepted: {
            try {
                let newSettings = JSON.parse(text)
                appSettings.setSettings(newSettings)
                visible = false
            } catch (err) {
                errorMessageDialog.text = err.message
                errorMessageDialog.visible = true
            }
        }
    }

    DlgTranslations {
        id: dlgTranslations
        height: Math.min(500, root.height - 50 * Stylesheet.pixelScaleRatio)
        width: Math.min(800, root.width - 200 * Stylesheet.pixelScaleRatio)
        modality: Qt.WindowModal
        programLanguage: root.programLanguage
        documentLanguage: root.documentLanguage
        appSettings: root.appSettings
        trId: ""
        onTranslationChanged: {
            invoice.setIsModified(true)
        }
    }

    SimpleMessageDialog {
        id: errorMessageDialog
        visible: false
    }

    SimpleMessageDialog {
        id: restoreSettingsConfirmationDialog
        visible: false
        text: qsTr("Are you sure you want to restore the default settings?")
        standardButtons: Dialog.RestoreDefaults | Dialog.Cancel
        onReset: {
            appSettings.resetSettings()
            visible = false
        }
    }

    SimpleMessageDialog {
        id: clearSettingsConfirmationDialog
        visible: false
        text: qsTr("Are you sure you want to clear the settings?")
        standardButtons: Dialog.RestoreDefaults | Dialog.Cancel
        onReset: {
            appSettings.clearSettings()
            visible = false
        }
    }

    function addLicenseRequirementText(text, fieldId) {
        if (!appSettings.meetInvoiceFieldLicenceRequirement(fieldId)) {
            return text + " (" + qsTr("Advanced plan") + ")"
        }
        return text
    }

    function loadTaxCodes() {
        taxCodesModel.clear();
        taxCodesModel.append(
                    {
                        'key': "",
                        'descr' : "",
                        'rate': ""
                    })
        var vatCodes = VatCodes.vatCodesGet()
        for (var i = 0; i < vatCodes.length; ++i) {
            taxCodesModel.append(vatCodes[i]);
        }
    }

    function meetLicenceRequirement(fieldId) {
        return appSettings.meetInvoiceFieldLicenceRequirement(fieldId)
    }

}
