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

    /* True when a label and its control no longer fit side by side, the same idea as the
       Invoice tab's own compact layout. The threshold is not a guessed number: it is what
       one of these rows actually measures - the label column, the control next to it, the
       gap between them and the margins - so it stays right if any of those constants is
       ever retuned.

       Measured on the scroll area's own width rather than on Screen: the screen is only a
       guess at the room the rows will get, and devices report it in different units.

       Everything ends up in one column. A row of a label plus one control simply stacks.
       A per view row keeps its three switches side by side on a line of their own, under
       a label that now spans the full width: the three columns are the three views, so a
       switch pushed onto the next line would silently come to stand for a different view
       than the title above it. Three columns instead of four is what stacks the label
       while leaving that correspondence intact. */
    readonly property bool compactLayout: scrollView.availableWidth > 0 &&
                                          scrollView.availableWidth < styleLabelWidth + stylePropertyWidth +
                                                                      styleColumnSpacing + 2 * Stylesheet.defaultMargin

    property string programLanguage: Banana.application.locale.substring(0, 2)
    property string documentLanguage: invoice.json && invoice.json.document_info.locale && invoice.signalInvoiceChanged?
                                         invoice.json.document_info.locale.substring(0, 2) :
                                         programLanguage

    property var viewsSettingsModel: [appSettings.view_id_base, appSettings.view_id_short, appSettings.view_id_long]

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

        // Pin the content to the width of the viewport. Left unset, a ScrollView takes the
        // content width from the implicit width of its child, and a ColumnLayout's implicit
        // width is that of its widest child - a label's full text on a single line. It would
        // then decide the content is far wider than the screen, offer horizontal scrolling,
        // and hand the content that oversized width: every fillWidth below would faithfully
        // fill 700 points on a 400 point screen. Height is left alone, so the page still
        // scrolls vertically as far as its content needs.
        contentWidth: availableWidth - ScrollBar.vertical.width

        ColumnLayout {
            width: scrollView.contentWidth
            height: scrollView.availableHeight

            ColumnLayout {
                Layout.fillWidth: true

                StyledLabel{
                    text: qsTr("New documents")
                    font.bold: true
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
                color: Stylesheet.buttonColor
            }

            ColumnLayout {
                Layout.fillWidth: true

                StyledLabel{
                    text: qsTr("Invoice custom fields")
                    font.bold: true
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
                color: Stylesheet.buttonColor
            }
            ColumnLayout {
                // Without this the section is not stretched by the column above it: it sizes
                // itself to its own content, so nothing inside is ever told how much room it
                // actually has and the fields keep their full width off the edge of a phone.
                // A plain "width" here did not do it - a layout owns the size of its children.
                Layout.fillWidth: true
                height: scrollView.availableHeight

                StyledLabel{
                    text: qsTr("Interface")
                    font.bold: true
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight / 2

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Views")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Title")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        // Three of these share one row and stay on it even when narrow: each
                        // column is a view, so a field pushed onto the next line would edit a
                        // different view than the title above it says.
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 60 * Stylesheet.pixelScaleRatio : 0
                        property string viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.getSettingsViewTitle(viewId)
                        placeholderText: !text ? appSettings.getDefaultViewTitle(viewId) : ""
                        onEditingFinished:  {
                            if (modified) {
                                appSettings.setViewTitle(viewId, text)
                                focus = false
                            }
                        }
                    }

                    StyledTextField {
                        // Three of these share one row and stay on it even when narrow: each
                        // column is a view, so a field pushed onto the next line would edit a
                        // different view than the title above it says.
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 60 * Stylesheet.pixelScaleRatio : 0
                        property string viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.getSettingsViewTitle(viewId)
                        placeholderText: !text ? appSettings.getDefaultViewTitle(viewId) : ""
                        onEditingFinished:  {
                            if (modified) {
                                appSettings.setViewTitle(viewId, text)
                                focus = false
                            }
                        }
                    }

                    StyledTextField {
                        // Three of these share one row and stay on it even when narrow: each
                        // column is a view, so a field pushed onto the next line would edit a
                        // different view than the title above it says.
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 60 * Stylesheet.pixelScaleRatio : 0
                        property string viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.getSettingsViewTitle(viewId)
                        placeholderText: !text ? appSettings.getDefaultViewTitle(viewId) : ""
                        onEditingFinished:  {
                            if (modified) {
                                appSettings.setViewTitle(viewId, text)
                                focus = false
                            }
                        }
                    }

                    StyledLabel{
                        text: qsTr("Visible")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSwitch {
                        property string viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                        checked: appSettings.isViewVisible(viewId)
                        onToggled: appSettings.setViewVisible(viewId, checked)
                    }

                    StyledSwitch {
                        property string viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                        checked: appSettings.isViewVisible(viewId)
                        onToggled: appSettings.setViewVisible(viewId, checked)
                    }

                    StyledSwitch {
                        property string viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                        checked: appSettings.isViewVisible(viewId)
                        onToggled: appSettings.setViewVisible(viewId, checked)
                    }

                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.buttonColor
            }

            ColumnLayout {
                // Without this the section is not stretched by the column above it: it sizes
                // itself to its own content, so nothing inside is ever told how much room it
                // actually has and the fields keep their full width off the edge of a phone.
                // A plain "width" here did not do it - a layout owns the size of its children.
                Layout.fillWidth: true
                height: scrollView.availableHeight

                StyledLabel{
                    text: qsTr("Invoice fields")
                    font.bold: true
                    Layout.bottomMargin: styleRowSpacing
                }

                StyledLabel{
                    // Wraps, and fills the width so that it has something to wrap against:
                    // without both, this one sentence is the widest thing on the page.
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    text: qsTr("In this section you can select which fields are displayed.")
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("General")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Fields not empty")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_fields_if_not_empty"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_fields_if_not_empty"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_fields_if_not_empty"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Parameters")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Decimals")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_decimals"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_decimals"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_decimals"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Total rounding")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding_totals"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding_totals"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding_totals"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Language")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_language"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_language"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_language"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Currency")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_currency"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_currency"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_currency"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("VAT mode")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_vat_mode"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_vat_mode"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_vat_mode"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Details")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Invoice number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Invoice date")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_date"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_date"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_date"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Due date")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_due_date"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_due_date"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_due_date"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Order number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Order date")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_date"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_date"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_order_date"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Invoice title")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_title"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_title"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_title"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Begin text")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_begin_text"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_begin_text"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_begin_text"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("End text")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_end_text"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_end_text"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_end_text"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Internal notes")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_internal_notes"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_internal_notes"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_internal_notes"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Invoice summary")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Custom fields")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Custom field 1")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_1"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_1"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_1"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 2")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_2"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_2"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_2"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 3")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_3"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_3"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_3"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 4")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_4"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_4"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_4"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 5")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_5"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_5"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_5"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 6")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_6"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_6"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_6"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 7")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_7"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_7"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_7"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Custom field 8")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_8"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_8"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_custom_field_8"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Address")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Customer selector")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_customer_selector"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_customer_selector"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_customer_selector"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Business name")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Business unit"), "show_invoice_address_business_unit")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Business unit 2"), "show_invoice_address_business_unit_2")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_2"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_2"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_2"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Business unit 3"), "show_invoice_address_business_unit_3")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_3"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_3"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_3"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Business unit 4"), "show_invoice_address_business_unit_4")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_4"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_4"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_business_unit_4"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Prefix")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_courtesy"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_courtesy"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_courtesy"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("First and last name")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_first_and_last_name"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_first_and_last_name"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_first_and_last_name"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Address street")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_street"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_street"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_street"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Building number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_building_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_building_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_building_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Address extra")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_extra"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_extra"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_extra"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Post box")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_postbox"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_postbox"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_postbox"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Country and locality")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_country_and_locality"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_country_and_locality"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_country_and_locality"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Email")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_email"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_email"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_email"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Phone")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_phone"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_phone"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_phone"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("VAT number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_vat_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_vat_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_vat_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Fiscal number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_fiscal_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_fiscal_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_address_fiscal_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Currently we hide the content in the gridLayout below because is unused due to the changes done to the tableview.
                // We commentend also the code block related into WdgInvoice->getTableHeight()

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight
                    visible: false;

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Items")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Height of visible content in rows (0 = all rows)")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledTextField {
                        property string flagId: "invoce_max_visible_items_without_scrolling"
                        property string viewId: appSettings.view_id_base
                        validator: IntValidator{bottom: 0; top: 1024;}
                        horizontalAlignment: Qt.AlignRight
                        implicitWidth: width_reference.implicitWidth
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.data.interface.invoice.views[viewId].appearance[flagId] ?
                                  appSettings.data.interface.invoice.views[viewId].appearance[flagId].toString() : "0"

                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.interface.invoice.views[viewId].appearance[flagId] = Number(text)
                                appSettings.signalItemsVisibilityChanged++
                            }
                            focus = false
                        }

                    }

                    StyledTextField {
                        property string flagId: "invoce_max_visible_items_without_scrolling"
                        property string viewId: appSettings.view_id_short
                        validator: IntValidator{bottom: 0; top: 1024;}
                        horizontalAlignment: Qt.AlignRight
                        implicitWidth: width_reference.implicitWidth
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.data.interface.invoice.views[viewId].appearance[flagId] ?
                                  appSettings.data.interface.invoice.views[viewId].appearance[flagId].toString() : "0"

                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.interface.invoice.views[viewId].appearance[flagId] = Number(text)
                                appSettings.signalItemsVisibilityChanged++
                            }
                            focus = false
                        }

                    }

                    StyledTextField {
                        property string flagId: "invoce_max_visible_items_without_scrolling"
                        property string viewId: appSettings.view_id_long
                        validator: IntValidator{bottom: 0; top: 1024;}
                        horizontalAlignment: Qt.AlignRight
                        implicitWidth: width_reference.implicitWidth
                        Layout.alignment: Qt.AlignHCenter
                        text: appSettings.data.interface.invoice.views[viewId].appearance[flagId] ?
                                  appSettings.data.interface.invoice.views[viewId].appearance[flagId].toString() : "0"

                        onEditingFinished: {
                            if (modified) {
                                appSettings.data.interface.invoice.views[viewId].appearance[flagId] = Number(text)
                                appSettings.signalItemsVisibilityChanged++
                            }
                            focus = false
                        }
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Item columns")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Row")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_row_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_row_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_row_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Type"), "show_invoice_item_column_type")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_type"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_type"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_type"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Number")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_number"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_number"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_number"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Item date"), "show_invoice_item_column_date")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_date"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_date"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_date"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Quantity")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_quantity"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_quantity"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_quantity"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Unit")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_unit"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_unit"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_unit"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: addLicenseRequirementText(qsTr("Discount"), "show_invoice_item_column_discount")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_discount"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_discount"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_item_column_discount"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                GridLayout {
                    columns: root.compactLayout ? 3 : 4
                    Layout.fillWidth: root.compactLayout
                    columnSpacing: root.compactLayout ? Stylesheet.defaultMargin : styleColumnSpacing
                    rowSpacing: styleRowSpacing
                    Layout.topMargin: styleSectionSeparatorHeight

                    StyledLabel{
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        text: qsTr("Totals")
                        font.bold: true
                        Layout.bottomMargin: styleRowSpacing
                    }

                    Repeater {
                        model: viewsSettingsModel
                        StyledLabel{
                            text: appSettings.getViewTitle(modelData)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    StyledLabel{
                        text: qsTr("Discount")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_discount"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_discount"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_discount"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Rounding")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_rounding"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Deposit")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_deposit"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_deposit"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_deposit"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel{
                        text: qsTr("Summary")
                        Layout.preferredWidth: styleLabelWidth
                        Layout.columnSpan: root.compactLayout ? 3 : 1
                        Layout.fillWidth: root.compactLayout
                        Layout.minimumWidth: root.compactLayout ? 100 * Stylesheet.pixelScaleRatio : 0
                        wrapMode: Text.WordWrap
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_base
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_short
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledSettingsSwitch {
                        flagId: "show_invoice_summary"
                        viewId: appSettings.view_id_long
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.buttonColor
            }

            ColumnLayout {
                // Without this the section is not stretched by the column above it: it sizes
                // itself to its own content, so nothing inside is ever told how much room it
                // actually has and the fields keep their full width off the edge of a phone.
                // A plain "width" here did not do it - a layout owns the size of its children.
                Layout.fillWidth: true
                height: scrollView.availableHeight

                StyledLabel{
                    text: qsTr("Tools")
                    font.bold: true
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
