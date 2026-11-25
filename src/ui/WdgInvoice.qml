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
import Qt.labs.qmlmodels

import "."
import "./components"

import "../base/utils.js" as Utils
import "../base/invoice.js" as Invoice
import "../base/contacts.js" as Contacts
import "../base/items.js" as Items
import "../base/settings.js" as Settings
import "../base/vatcodes.js" as VatCodes

/*
   The form of one estimate or invoice, read from top to bottom in the order the document is
   filled in:

   - who it is for, and what it is: the customer beside the document's own data;
   - what it is about: the object;
   - what is being charged: the items table and its commands;
   - what it comes to: the totals;
   - and last the texts, the additional fields and the internal notes, which most documents
     leave empty and which are therefore folded away until they hold something.

   Every field of the document is here, always: there is one single form and nothing is
   hidden behind a choice of view. What is secondary is folded into the group it belongs to,
   never taken away, and a group that already holds something opens by itself.
*/
Item {
    id: window

    property bool isVatModeVatNone: false
    property bool isVatModeVatInclusive : true

    required property AppSettings appSettings
    required property Invoice invoice

    /* True when the customer and the document cannot sit side by side and stack into one
       column instead. Measured on the room available, not on Screen.width, whose unit
       differs across devices. Scaled, like the widths it stands for: two panels of 320
       plus the space between them and the room the scroll bar takes. */
    readonly property bool compactLayout: columnLayout.width > 0 &&
                                          columnLayout.width < 760 * Stylesheet.pixelScaleRatio

    /* What the document comes to, shown in the window's own bar above this form: defined
       here because this is where the figures and their formatting live. */
    readonly property string invoiceTotalText:
        qsTr("Total") + (invoice.signalInvoiceChanged && invoice.json && invoice.json.document_info.currency ?
                             " " + invoice.json.document_info.currency.toLocaleUpperCase() : "") +
        " " + toLocaleNumberFormat(invoice.json ? invoice.json.billing_info.total_to_pay : "", true)

    /* One form, one view. The appearance settings are still read for the widths of the
       items table's columns, which is what the "full" view stores; its field flags say
       that everything is shown, which is what this form does. */
    readonly property string currentView: appSettings.view_id_full

    /* Whether the folded groups already hold something, and should therefore start open.
       Read through signalInvoiceChanged: the json notifies nothing on its own, so without
       it a document opened later would be measured against the previous one. */

    readonly property bool hasCustomerExtraFields: {
        if (!invoice.signalInvoiceChanged || !invoice.json || !invoice.json.customer_info)
            return false
        let customer = invoice.json.customer_info
        return Boolean(customer.business_unit || customer.business_unit2 ||
                       customer.business_unit3 || customer.business_unit4 ||
                       customer.address2 || customer.address3 ||
                       customer.phone || customer.email ||
                       customer.vat_number || customer.fiscal_number)
    }

    readonly property bool hasDocumentExtraFields: {
        if (!invoice.signalInvoiceChanged || !invoice.json || !invoice.json.document_info)
            return false
        let documentInfo = invoice.json.document_info
        if (documentInfo.order_number || documentInfo.order_date)
            return true
        // The additional fields are part of this group: they are fields of the document and
        // are printed together with the rest of its data.
        for (let i = 1; i <= 8; ++i) {
            if (invoiceCustomFieldGet(invoice.json, "custom_field_" + i))
                return true
        }
        return false
    }

    /** Shows a short message over the form - a document copied, deleted, a contact added. */
    function notify(message) {
        notificationPopUp.text = message
        notificationPopUp.visible = true
    }

    /* Says that the document has been saved. Here rather than where the Save button is, so
       that the two sentences are the ones this file already has translated: the same words
       under another file's name would be a translation of their own. */
    function notifySaved() {
        notify(invoice.isEstimate() ? qsTr("Estimate saved") : qsTr("Invoice saved"))
    }

    /* The contacts created while this dialog was open, by id. They reach the Contacts table
       only when the dialog is closed and Banana applies the DocumentChange, so until then
       the table cannot be asked about them - see the customer selector. */
    property var createdContacts: ({})

    /** True when there is an address worth keeping as a contact: a name of some kind. */
    readonly property bool hasAddressToSaveAsContact: {
        if (!invoice.signalInvoiceChanged || !invoice.json || !invoice.json.customer_info)
            return false
        let customer = invoice.json.customer_info
        return Boolean(customer.business_name || customer.last_name || customer.first_name)
    }

    /** Asks for the id of the new contact; the row itself is written by onContactConfirmed
        below, once the user has confirmed it. */
    function createContactFromAddress() {
        if (invoice.isReadOnly || !invoice.json || !invoice.json.customer_info)
            return

        // Acquire focus, if a text field is in edit mode it will commit changes
        window.forceActiveFocus()

        let customerInfo = invoice.json.customer_info
        dlgNewContact.openFor(Contacts.contactsGetNextId(),
                              Contacts.contactBriefDescriptionFromCustomerInfo("", customerInfo))
    }

    function createInvoiceFromEstimate() {
        if (invoice.isModified) {
            invoice.save()
        }
        // This is a document of its own, not another save of the one it comes from: see
        // Invoice.newDocumentSerial.
        invoice.beginNewDocument()
        invoice.setType(invoice.type_invoice)
        invoice.json = Invoice.invoiceCreateFromEstimateObj(invoice.json)
        invoice.tabPos.tableName = "Invoices"
        invoice.tabPos.rowNr = -1

        invoice.isNewDocument = true
        invoice.isReadOnly = false

        updateView()
        setDocumentModified()

        notificationPopUp.text = qsTr("Invoice created");
        notificationPopUp.visible = true
    }

    function duplicateInvoice() {
        if (invoice.isModified && !invoice.isReadOnly) {
            invoice.save()
        }
        // This is a document of its own, not another save of the one it was copied from:
        // see Invoice.newDocumentSerial.
        invoice.beginNewDocument()
        invoice.json = Invoice.invoiceDuplicateObj(invoice.json, invoice.tabPos)
        // Check if doc_type is invoice or estimate
        if (invoice.json.document_info.doc_type === "10")
            invoice.setType(invoice.type_invoice)
        else
            invoice.setType(invoice.type_estimate)
        invoice.tabPos.rowNr = -1
        if (invoice.tabPos.tableName === "Archive" || invoice.tabPos.tableName === "Templates" ||
                invoice.tabPos.tableName === "Extract") {
            invoice.tabPos.tableName = invoice.tabPos.parentTableName
                }

        invoice.isNewDocument = true
        invoice.isReadOnly = false

        updateView()
        setDocumentModified()

        notificationPopUp.text = invoice.isEstimate() ? qsTr("Estimate copied") : qsTr("Invoice copied");
        notificationPopUp.visible = true
    }

    function printInvoice() {
        if (appSettings.modified) {
            // We have to save the settings before printing
            // if not the changes to customs fields are not taken over
            appSettings.saveSettings()
        }

        if (invoice.isModified) {
            invoice.save()

            notificationPopUp.text = invoice.isEstimate() ? qsTr("Estimate saved") : qsTr("Invoice saved");
            notificationPopUp.visible = true
        }

        invoiceUpdateCustomFields()

        Invoice.invoicePrint(invoice.json,invoice.tabPos.tableName);
    }

    Component.onCompleted: {
        loadLanguages()
        loadCurrencies()
        loadCustomerAddresses()
        loadItems()
        loadTaxRates()
        invoiceItemsTable.updateColDescrWidth()
    }

    /* An entry of the row menu, drawn like StyledMenuEntry in DlgInvoice.qml and for the
       same reason: see there. The background needs an implicit size, or the menu
       appears not to open. */
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

    TableModel {
        id: invoiceItemsModel

        TableModelColumn { display: "row"}
        TableModelColumn { display: "item_type"}
        TableModelColumn { display: "number"}
        TableModelColumn { display: "date"}
        TableModelColumn { display: "description"}
        TableModelColumn { display: "quantity"}
        TableModelColumn { display: "mesure_unit"}
        TableModelColumn { display: "price"}
        TableModelColumn { display: "discount"}
        TableModelColumn { display: "total"}
        TableModelColumn { display: "vat_code"}

        rows: [
            {
                "row": "",
                "item_type": "",
                "number": "",
                "date": "",
                "description": "",
                "quantity": "",
                "mesure_unit": "",
                "price": "",
                "discount": "",
                "total": "",
                "vat_code": ""
            },
        ]

        property var headers: [
            {
                'id': 'invoice_item_column_row_number',
                'align': Text.AlignLeft,
                'role':  'row',
                'title': qsTr("#"),
                'visible': true,
                'width': 30
            },
            {
                'id': 'invoice_item_column_type',
                'align': Text.AlignLeft,
                'role':  'item_type',
                'title': qsTr("Type"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_number',
                'align': Text.AlignLeft,
                'role':  'number',
                'title': qsTr("Item"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_date',
                'align': Text.AlignLeft,
                'role':  'date',
                'title': qsTr("Date"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_description',
                'align': Text.AlignLeft,
                'role':  'description',
                'title': qsTr("Description"),
                'visible': true,
                'width': 220
            },
            {
                'id': 'invoice_item_column_quantity',
                'align': Text.AlignRight,
                'role':  'quantity',
                'title': qsTr("Qty"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_unit',
                'align': Text.AlignRight,
                'role':  'mesure_unit',
                'title': qsTr("Unit"),
                'visible': true,
                'width': 60
            },
            {
                'id': 'invoice_item_column_price',
                'align': Text.AlignRight,
                'role':  'price',
                'title': qsTr("Price"), // TODO: isVatModeVatNone ? qsTr("Price") : isVatModeVatInclusive ? qsTr("Price incl.") : qsTr("Price excl."),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_discount',
                'align': Text.AlignRight,
                'role':  'discount',
                'title': qsTr("Discount"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_total',
                'align': Text.AlignRight,
                'role':  'total',
                'title': qsTr("Total"),
                'visible': true,
                'width': 100
            },
            {
                'id': 'invoice_item_column_vat',
                'align': Text.AlignRight,
                'role':  'vat_code',
                'title': qsTr("VAT"),
                'visible': true,
                'width': 80
            }
        ]

        }

    VatModesModel {
        id: vatModesModel
    }

    InvoiceItemTypesModel {

        id: invoiceItemTypesModel
    }

    ListModel {
        id: taxRatesModel
    }

    ListModel {
        id: customerAddressesModel
    }

    ListModel {
        id: itemsModel
    }

    ListModel {
        id: languagesModel
    }

    ListModel {
        id: currenciesModel
    }

    ColumnLayout { // The form: a banner for a locked document, then one scrolling page
        anchors.fill: parent
        anchors.margins: Stylesheet.defaultMargin
        spacing: Stylesheet.defaultMargin

        // Hack for qt6, to resolve overlapping items after dialog load
        visible: appSettings.loaded

        Rectangle { // Read only banner
            // A locked document otherwise looks exactly like an editable one: the only
            // other hint is the "[Read only]" line under the title, which is easy to miss.
            Layout.fillWidth: true
            visible: invoice.isReadOnly
            implicitHeight: readOnlyLabel.implicitHeight + Stylesheet.defaultMargin
            color: Stylesheet.accentSurfaceColor
            radius: Stylesheet.cornerRadiusSmall
            border.width: 1
            border.color: Stylesheet.accentColor

            Rectangle {
                // Accent stripe, same language as the notification pop up
                id: readOnlyStripe
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: 4 * Stylesheet.pixelScaleRatio
                radius: Stylesheet.cornerRadiusSmall
                color: Stylesheet.accentColor
            }

            StyledLabel {
                id: readOnlyLabel
                anchors.verticalCenter: parent.verticalCenter
                // Anchored to the stripe, so the gap stays right if either changes width
                anchors.left: readOnlyStripe.right
                anchors.right: parent.right
                anchors.leftMargin: Stylesheet.defaultMargin
                anchors.rightMargin: Stylesheet.defaultMargin
                // A notice, not a label naming a field: full strength, and at the size of
                // something meant to be read rather than glanced at.
                color: Stylesheet.textColor
                font: Stylesheet.bodyFont
                text: qsTr("This document is read only and cannot be modified.")
            }
        }

        ScrollView { // The page
            id: scrollView
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: columnLayout.height

            // The page never scrolls sideways: left unset, a ScrollView takes its content
            // width from its child, and one element wider than the screen drags the whole
            // form. The trade: such an element is cut off instead. The table scrolls itself.
            contentWidth: availableWidth - ScrollBar.vertical.width

            ColumnLayout {
                id: columnLayout
                width: scrollView.availableWidth - scrollView.ScrollBar.vertical.width - Stylesheet.defaultMargin

                spacing: Stylesheet.defaultMargin

                GridLayout { // Who the document is for, and what it is
                    // Side by side while there is room for both, stacked otherwise, so a
                    // narrow screen never has to scroll sideways to reach the address.
                    columns: window.compactLayout ? 1 : 2
                    columnSpacing: Stylesheet.defaultMargin
                    rowSpacing: Stylesheet.defaultMargin

                    // Without this the grid takes the width of its content and the cards have
                    // nothing to fill against.
                    Layout.fillWidth: true

                    StyledCard { // The customer the document is addressed to
                        id: customerCard

                        title: qsTr("Customer")
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            // The contact this document is addressed to, and the button that
                            // keeps the address below as a new contact.
                            Layout.fillWidth: true
                            Layout.bottomMargin: Stylesheet.spacingBase
                            spacing: Stylesheet.spacingTight

                            StyledKeyDescrComboBox {
                                id: address_customer_selector
                                filled: true
                                Layout.fillWidth: true
                                // Never force the drop-down wider than the dialog itself: the
                                // popup is right-aligned to the field, so any excess width hangs
                                // off the left edge of a narrow screen and is simply not shown.
                                popupMinWidth: Math.min(400 * Stylesheet.pixelScaleRatio, columnLayout.width)
                                popupAlign: Qt.AlignRight

                                enabled: !invoice.isReadOnly
                                editable: true
                                model: customerAddressesModel
                                textRole: "descr"
                                filterEnabled: true
                                displayTextIncludesKey: true

                                Connections {
                                    target: invoice
                                    function onInvoiceChanged() {
                                        address_customer_selector.setCurrentKey(
                                                    invoice.json && invoice.json.customer_info.number ?
                                                        invoice.json.customer_info.number : ""
                                                    )
                                    }
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    if (isExistingKey) {
                                        var contactId = key
                                        /* A contact created here is not in the Contacts table
                                           yet - it is written when the dialog is closed - so
                                           reading it from the table would hand back an empty
                                           address and wipe the one it was made from. */
                                        if (window.createdContacts[contactId]) {
                                            invoice.json.customer_info =
                                                    JSON.parse(JSON.stringify(window.createdContacts[contactId]))
                                            invoice.json.customer_info.number = contactId
                                            updateViewAddress()
                                            setDocumentModified()
                                            return
                                        }
                                        invoice.json.customer_info = Contacts.contactAddressGet(contactId)
                                        invoice.json.customer_info.number = contactId
                                        setDocumentLocale(Contacts.contactLocaleGet(contactId))
                                        setDocumentCurrency(Contacts.contactCurrencyGet(contactId))
                                        setDocumentDueDate(Contacts.contactPaymentTermInDaysGet(contactId))
                                        setDocumentDiscountPercentage(Contacts.contactDiscountPercentageGet(contactId))
                                        invoice_due_date.update()
                                        updateViewAddress()
                                    } else {
                                        invoice.json.customer_info.number = ""
                                    }
                                    setDocumentModified()
                                }
                            }

                            StyledButton {
                                // Keeps the address below as a new contact, so an address
                                // typed straight into a document does not have to be typed
                                // again in the Contacts table.
                                id: newContactButton
                                text: "+"
                                Layout.minimumWidth: 40 * Stylesheet.pixelScaleRatio
                                Accessible.name: qsTr("New contact")
                                visible: !invoice.isReadOnly
                                enabled: window.hasAddressToSaveAsContact
                                onClicked: window.createContactFromAddress()
                            }
                        }

                        StyledLabel {
                            id: addressLabel
                            text: qsTr("Address")
                        }

                        StyledTextField {
                            id: address_business_name
                            filled: true
                            Layout.fillWidth: true
                            readOnly: invoice.isReadOnly
                            placeholderText: qsTr("Business name")
                            onEditingFinished: {
                                if (modified) {
                                    invoice.json.customer_info.business_name = text
                                    setDocumentModified()
                                }
                            }
                        }

                        StyledTextField {
                            id: address_courtesy
                            filled: true
                            Layout.fillWidth: true
                            readOnly: invoice.isReadOnly
                            placeholderText: qsTr("Prefix")
                            onEditingFinished: {
                                if (modified) {
                                    invoice.json.customer_info.courtesy = text
                                    setDocumentModified()
                                }
                            }
                        }

                        RowLayout {
                            // Must be able to shrink with the card: without this the row keeps
                            // the sum of its fields, which scales with pixelScaleRatio and
                            // overflows a narrow screen.
                            Layout.fillWidth: true
                            spacing: Stylesheet.spacingTight

                            StyledTextField {
                                id: address_first_name
                                filled: true
                                Layout.fillWidth: true
                                Layout.minimumWidth: 60 * Stylesheet.pixelScaleRatio
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("First name")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.first_name = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_last_name
                                filled: true
                                Layout.fillWidth: true
                                Layout.minimumWidth: 60 * Stylesheet.pixelScaleRatio
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("Last name")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.last_name = text
                                        setDocumentModified()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Stylesheet.spacingTight

                            StyledTextField {
                                id: address_address1
                                filled: true
                                Layout.fillWidth: true
                                Layout.minimumWidth: 80 * Stylesheet.pixelScaleRatio
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("Street")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.address1 = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_building_number
                                filled: true
                                Layout.preferredWidth: 70 * Stylesheet.pixelScaleRatio
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("Nr")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.building_number = text
                                        setDocumentModified()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Stylesheet.spacingTight

                            StyledTextField {
                                id: address_country_code
                                filled: true
                                Layout.preferredWidth: 46 * Stylesheet.pixelScaleRatio
                                placeholderText: qsTr("CC")
                                //NB.: disable tooltips because crashing the app when closing the dialog
                                //ToolTip.visible: hovered
                                //ToolTip.text: qsTr("Country code")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.country_code = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_postal_code
                                filled: true
                                Layout.preferredWidth: 70 * Stylesheet.pixelScaleRatio
                                placeholderText: qsTr("Zip")
                                //NB.: disable tooltips because crashing the app when closing the dialog
                                //ToolTip.visible: hovered
                                //ToolTip.text: qsTr("Postal code")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.postal_code = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_city
                                filled: true
                                Layout.fillWidth: true
                                Layout.minimumWidth: 80 * Stylesheet.pixelScaleRatio
                                placeholderText: qsTr("City")
                                readOnly: invoice.isReadOnly
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.city = text
                                        setDocumentModified()
                                    }
                                }
                            }
                        }

                        StyledCard { // The rest of the address
                            /* Folded away, not taken away: most documents need none of these,
                               and the ones that do open the group by themselves. */
                            id: customerExtraGroup

                            plain: true
                            collapsible: true
                            expanded: window.hasCustomerExtraFields
                            title: qsTr("More customer fields")
                            Layout.fillWidth: true
                            Layout.topMargin: Stylesheet.spacingBase

                            StyledTextField {
                                id: address_business_unit
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit")
                                placeholderText: qsTr("Business unit")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.business_unit = text
                                        setDocumentModified()
                                    }
                                }
                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit")) {
                                        dlgLicense.visible = true
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_business_unit_2
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_2")
                                placeholderText: qsTr("Business unit 2")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.business_unit2 = text
                                        setDocumentModified()
                                    }
                                }
                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_2")) {
                                        dlgLicense.visible = true
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_business_unit_3
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_3")
                                placeholderText: qsTr("Business unit 3")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.business_unit3 = text
                                        setDocumentModified()
                                    }
                                }
                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_3")) {
                                        dlgLicense.visible = true
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_business_unit_4
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_4")
                                placeholderText: qsTr("Business unit 4")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.business_unit4 = text
                                        setDocumentModified()
                                    }
                                }
                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_address_business_unit_4")) {
                                        dlgLicense.visible = true
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_address2
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("Extra")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.address2 = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_address3
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly
                                placeholderText: qsTr("P.O.Box")
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.address3 = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_phone
                                filled: true
                                Layout.fillWidth: true
                                placeholderText: qsTr("Phone")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.phone = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_email
                                filled: true
                                Layout.fillWidth: true
                                placeholderText: qsTr("Email")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.email = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_vat_number
                                filled: true
                                Layout.fillWidth: true
                                placeholderText: qsTr("VAT number")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.vat_number = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledTextField {
                                id: address_fiscal_number
                                filled: true
                                Layout.fillWidth: true
                                placeholderText: qsTr("Fiscal number")
                                readOnly: invoice.isReadOnly

                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.customer_info.fiscal_number = text
                                        setDocumentModified()
                                    }
                                }
                            }
                        }
                    }

                    StyledCard { // The document's own data
                        id: documentCard

                        /* No alignment, so the layout stretches this panel to the height
                           of the row: the two panels end at the same line instead of each
                           stopping where its own content does. */
                        title: invoice.isEstimate() ? qsTr("Estimate") : qsTr("Invoice")
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GridLayout {
                            // Label, then its field. Two columns at every width: the card is
                            // never narrower than a label and a field side by side, because
                            // when it is the only thing on the row it has the whole width.
                            columns: 2
                            rowSpacing: Stylesheet.spacingTight
                            columnSpacing: Stylesheet.spacingBase
                            Layout.fillWidth: true

                            StyledLabel {
                                text: invoice.isEstimate() ? qsTr("Estimate No") : qsTr("Invoice No")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledTextField {
                                id: invoice_number
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly
                                text: invoice.json && invoice.json.document_info.number ? invoice.json.document_info.number : "{invoice_no}"
                                onEditingFinished: {
                                    if (modified) {
                                        invoice.json.document_info.number = text
                                        setDocumentModified()
                                    }
                                }
                            }

                            StyledLabel {
                                text: invoice.isEstimate() ? qsTr("Estimate date") : qsTr("Invoice date")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledTextField {
                                id: invoice_date
                                filled: true
                                Layout.fillWidth: true
                                property int updateText: 1 // Binding for updating the text

                                readOnly: invoice.isReadOnly
                                text: {
                                    if (updateText && invoice.json && invoice.json.document_info.date) {
                                        var dateString = invoice.json.document_info.date.split('T')[0]
                                        Banana.Converter.toLocaleDateFormat(dateString)
                                    } else {
                                        ""
                                    }
                                }

                                onEditingFinished: {
                                    if (modified) {
                                        // Check date
                                        let date = Banana.Converter.toInternalDateFormat(text)
                                        let localDate = Banana.Converter.toLocaleDateFormat(date)
                                        if (!localDate || localDate.length === 0) {
                                            errorMessageDialog.text = qsTr("Invalid date: " + text)
                                            errorMessageDialog.visible = true
                                            updateText++
                                            return
                                        }
                                        // Set date
                                        invoiceSetDate(invoice.json, date);
                                        invoice_due_date.update()
                                        setDocumentModified()
                                    }
                                }
                                function getDate() {
                                    if (updateText > 0) {
                                        if (invoice.json && invoice.json.document_info.date) {
                                            var dateString = invoice.json.document_info.date.split('T')[0]
                                            return Banana.Converter.toLocaleDateFormat(dateString)
                                        }
                                    }
                                    return ""

                                }
                            }

                            StyledLabel {
                                // Same field for both documents: on an estimate payment_info.due_date holds
                                // the end of its validity, computed from the estimate validity days.
                                text: invoice.isEstimate() ? qsTr("Validity") : qsTr("Due date")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledTextField {
                                id: invoice_due_date
                                filled: true
                                Layout.fillWidth: true
                                readOnly: invoice.isReadOnly

                                text: getDate()

                                onEditingFinished: {
                                    if (modified) {
                                        // Check date
                                        let date = text
                                        if (date) {
                                            date = Banana.Converter.toInternalDateFormat(text)
                                            let localDate = Banana.Converter.toLocaleDateFormat(date)
                                            if (!localDate) {
                                                errorMessageDialog.text = qsTr("Invalid date: " + text)
                                                errorMessageDialog.visible = true
                                                update()
                                                return
                                            }
                                        }
                                        // Set date
                                        invoice.json.payment_info.due_date = date
                                        setDocumentModified()
                                    }
                                }

                                function update() {
                                    text = getDate()
                                }

                                function getDate() {
                                    if (invoice.json && invoice.json.payment_info.due_date) {
                                        var date = invoice.json.payment_info.due_date.split('T')[0]
                                        return Banana.Converter.toLocaleDateFormat(date)
                                    } else {
                                        return ""
                                    }
                                }
                            }

                            StyledLabel {
                                text: qsTr("Currency")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledKeyDescrComboBox {
                                id: invoice_currency
                                filled: true
                                Layout.fillWidth: true
                                editable: true
                                enabled: !invoice.isReadOnly
                                model: currenciesModel
                                textRole: "key"

                                cleanKey: function(text) {
                                    return text.trim().toUpperCase()
                                }

                                Connections {
                                    target: invoice
                                    function onInvoiceChanged() {
                                        invoice_currency.setCurrentKey(
                                                    invoice.json && invoice.json.document_info.currency ?
                                                        invoice.json.document_info.currency : ""
                                                    )
                                    }
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    invoice.json.document_info.currency = key
                                    setDocumentModified()
                                }
                            }

                            StyledLabel {
                                text: qsTr("Language")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledKeyDescrComboBox {
                                id: invoice_language
                                filled: true
                                Layout.fillWidth: true
                                enabled: !invoice.isReadOnly

                                editable: true
                                model: languagesModel
                                textRole: "descr"

                                Connections {
                                    target: invoice
                                    function onInvoiceChanged() {
                                        invoice_language.setCurrentKey(
                                                    invoice.json && invoice.json.document_info.locale ?
                                                        invoice.json.document_info.locale : ""
                                                    )
                                    }
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    setDocumentLocale(key)
                                }

                            }

                            StyledLabel {
                                text: qsTr("VAT mode")
                                Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                            }

                            StyledKeyDescrComboBox {
                                id: invoice_vat_mode
                                filled: true
                                Layout.fillWidth: true
                                enabled: !invoice.isReadOnly

                                editable: false
                                model: vatModesModel
                                textRole: "descr"
                                listItemTextIncludesKey: false

                                Connections {
                                    target: invoice
                                    function onInvoiceChanged() {
                                        if (invoice.json && invoice.json.document_info.vat_mode) {
                                            invoice_vat_mode.setCurrentKey(invoice.json.document_info.vat_mode)
                                        }
                                    }
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    invoice.setVatMode(key)
                                    calculateInvoice()
                                }

                            }
                        }

                        StyledCard { // The rest of the document's data
                            /* The order it answers to, and how the figures are rounded: set
                               once in the settings for most people, so folded away here. */
                            id: documentExtraGroup

                            plain: true
                            collapsible: true
                            expanded: window.hasDocumentExtraFields
                            title: qsTr("More document fields")
                            Layout.fillWidth: true
                            Layout.topMargin: Stylesheet.spacingBase

                            GridLayout {
                                columns: 2
                                rowSpacing: Stylesheet.spacingTight
                                columnSpacing: Stylesheet.spacingBase
                                Layout.fillWidth: true

                                StyledLabel {
                                    text: qsTr("Order No")
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_order_no
                                    filled: true
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly
                                    text: invoice.json && invoice.json.document_info.order_number ? invoice.json.document_info.order_number : ""
                                    onEditingFinished: {
                                        if (modified) {
                                            invoice.json.document_info.order_number = text
                                            setDocumentModified()
                                        }
                                    }
                                }

                                StyledLabel {
                                    text: qsTr("Order date")
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_order_date
                                    filled: true
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly
                                    text: invoice.json && invoice.json.document_info.order_date ? toLocaleDateTimeFormat(invoice.json.document_info.order_date) : ""
                                    onEditingFinished: {
                                        if (modified) {
                                            invoice.json.document_info.order_date = toInternalDateTimeFormat(text)
                                            setDocumentModified()
                                        }
                                    }
                                }

                                StyledLabel {
                                    text: qsTr("Decimal points")
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_decimal_amounts
                                    filled: true
                                    Layout.fillWidth: true
                                    text: invoice.json && invoice.json.document_info.decimals_amounts ? invoice.json.document_info.decimals_amounts : ""
                                    readOnly: invoice.isReadOnly

                                    onEditingFinished: {
                                        if (modified) {
                                            invoice.json.document_info.decimals_amounts = Number(text)
                                            setDocumentModified(true)
                                            calculateInvoice()
                                        }
                                    }
                                }

                                StyledLabel {
                                    text: qsTr("Total rounding")
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_rounding_total
                                    filled: true
                                    Layout.fillWidth: true
                                    text: invoice.json && invoice.json.document_info.rounding_total ?
                                              Banana.Converter.toLocaleNumberFormat(invoice.json.document_info.rounding_total) : ""
                                    readOnly: invoice.isReadOnly

                                    onEditingFinished: {
                                        if (modified) {
                                            invoice.json.document_info.rounding_total =
                                                    Banana.Converter.toInternalNumberFormat(text)
                                            window.setDocumentModified(true)
                                            window.calculateInvoice()
                                        }
                                    }
                                }

                                StyledLabel {
                                    // The fields whose names the user chooses, in the
                                    // settings. They are fields of the document and are
                                    // printed together with the data above them.
                                    Layout.columnSpan: 2
                                    Layout.topMargin: Stylesheet.spacingBase
                                    text: qsTr("Additional info")
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_1"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_1
                                    filled: true
                                    property string customFieldId: "custom_field_1"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_1")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_1")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_2"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_2
                                    filled: true
                                    property string customFieldId: "custom_field_2"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_2")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_2")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_3"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_3
                                    filled: true
                                    property string customFieldId: "custom_field_3"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_3")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_3")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_4"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_4
                                    filled: true
                                    property string customFieldId: "custom_field_4"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_4")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_4")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_5"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_5
                                    filled: true
                                    property string customFieldId: "custom_field_5"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_5")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_5")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_6"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_6
                                    filled: true
                                    property string customFieldId: "custom_field_6"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_6")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_6")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_7"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_7
                                    filled: true
                                    property string customFieldId: "custom_field_7"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_7")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_7")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }

                                StyledLabel {
                                    property string trId: "invoice_custom_field_8"
                                    text: appSettings.signalTranslationsChanged ?
                                              Settings.getTranslatedText(appSettings.data, trId, Banana.application.locale.substring(0, 2)) :
                                              trId
                                    Layout.minimumWidth: 100 * Stylesheet.pixelScaleRatio
                                }

                                StyledTextField {
                                    id: invoice_custom_field_8
                                    filled: true
                                    property string customFieldId: "custom_field_8"
                                    Layout.fillWidth: true
                                    readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_8")
                                    text: invoiceCustomFieldGet(invoice.json, customFieldId)
                                    onEditingFinished: {
                                        if (modified) {
                                            invoiceUpdateCustomFields();
                                            setDocumentModified()
                                        }
                                    }
                                    onPressed: {
                                        if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_custom_field_8")) {
                                            dlgLicense.visible = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                StyledCard { // What the document is about, and how it opens
                    /* Two fields in one panel: the object is the line the document is
                       titled with and the begin text the paragraph under it, and on the
                       printed page they follow one another. A panel each made two frames
                       where the thing itself is one.

                       The object carries no label of its own - the title of the panel
                       names it, as the customer panel names its selector. */
                    title: qsTr("Object")
                    Layout.fillWidth: true

                    StyledTextField {
                        id: invoice_description
                        filled: true
                        readOnly: invoice.isReadOnly
                        Layout.fillWidth: true
                        text: invoice.json && invoice.json.document_info.description ? invoice.json.document_info.description : ""
                        onEditingFinished: {
                            if (modified) {
                                invoice.json.document_info.description = text
                                setDocumentModified()
                            }
                        }
                    }

                    StyledLabel {
                        text: qsTr("Begin text")
                        Layout.topMargin: Stylesheet.spacingTight
                    }

                    StyledTextArea {
                        id: ivoice_begin_text
                        filled: true
                        Layout.fillWidth: true
                        readOnly: invoice.isReadOnly
                        text: invoice.json && invoice.json.document_info && invoice.json.document_info.text_begin
                              ? invoice.json.document_info.text_begin  : ""

                        onEditingFinished: {
                            if (modified) {
                                invoice.json.document_info.text_begin = text
                                setDocumentModified()
                            }
                        }

                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: invoiceItemsTable
                    }
                }

                RowLayout { // What is being charged
                    /* No bar of commands: Add, Remove, Move up and Move Down are reached
                       from the ⋮ menu of each row, in the row number cell, at every width.
                       They act on one row, so that is where they belong - and a bar of
                       buttons cost a row of height and sat far from the rows it moved. */
                    Layout.fillWidth: true
                    Layout.topMargin: Stylesheet.spacingBase
                    spacing: Stylesheet.spacingBase

                    StyledLabel {
                        text: qsTr("Items")
                        // A heading, not a label naming a field: full strength and a step
                        // larger - the same weight the title of a card carries.
                        color: Stylesheet.textColor
                        font: Stylesheet.cardTitleFont
                    }

                    StyledLabel {
                        // Says where the commands of a row are, which is not obvious before
                        // the first time the menu is opened.
                        Layout.fillWidth: true
                        visible: !invoice.isReadOnly
                        elide: Text.ElideRight
                        text: qsTr("Use the ⋮ of a row to add, remove or move it")
                    }

                    StyledLabel {
                        visible: appSettings.isInternalVersion()
                        text: "Cur.pos.: " + invoiceItemsTable.currentRow + ", " + invoiceItemsTable.currentColumn
                    }
                }

                // There is a warning on the HorizontalHeaderView row, but apparently nothing appens.
                // Maybe some values are not immediately loaded
                HorizontalHeaderView {
                    id: horizontalHeader
                    //Do NOT set 'model' when using syncView.
                    //From Qt 6.10 this causes the header to render one row per data row.
                    //Compatible with previous versions
                    // model: invoiceItemsModel
                    syncView: invoiceItemsTable
                    reuseItems: false
                    visible: true
                    // Unlike the items table this view had no clipping, so any header cell
                    // laid out past its right edge stayed painted instead of being cut off.
                    clip: true

                    Layout.fillWidth: true
                    Layout.topMargin: Stylesheet.defaultMargin

                    Component.onCompleted: {
                        if (resizableColumns) {
                            resizableColumns = false; // otherwise QTBUG-111013 happens
                            // NB.: resizableColumns was introduced in Qt 6.5
                        }
                    }

                    delegate: DelegateChooser {
                        DelegateChoice {
                            Item {
                                Rectangle {
                                    /* The same grey the cards use, in its opaque form: it
                                       used to take the grey of the system buttons, which
                                       belongs to another family and drifts from the rest in
                                       dark mode. Opaque and not the plain tint, because this
                                       cell has to cover what the view leaves behind it - see
                                       Stylesheet.surfaceColorOpaque. */
                                    anchors.fill: parent
                                    color: Stylesheet.surfaceColorOpaque
                                }

                                StyledLabel {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4 * Stylesheet.pixelScaleRatio
                                    anchors.rightMargin: 4 * Stylesheet.pixelScaleRatio
                                    verticalAlignment: Qt.AlignVCenter

                                    clip: true
                                    text: invoiceItemsModel.headers[model.column].title
                                    horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                    // A heading, not a label naming a field: full strength.
                                    color: Stylesheet.textColor
                                    font: Stylesheet.scaledFont(1.0, Font.DemiBold)
                                }

                                Rectangle {
                                    // Marks where one column ends, on the inside edge of the
                                    // heading: the columns touch now, so there is no gap left
                                    // between them to stand for it.
                                    x: parent.width - 1
                                    y: 0
                                    width: 1
                                    height: parent.height
                                    color: Stylesheet.borderColor
                                }

                                Rectangle {
                                    // Separates the header from the first item row
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 1
                                    color: Stylesheet.borderColor
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: headerdragarea
                        anchors.fill: parent
                        preventStealing: true
                        hoverEnabled: true

                        drag.axis: Drag.XAxis
                        drag.smoothed: false
                        drag.minimumX: 0
                        drag.maximumX: 1200

                        property bool isDragging: false
                        property real dragInitialPos: 0
                        property int dragColumnNo: 0
                        property int dragColumnWidth: 0

                        onPositionChanged: function(event) {
                            if (isDragging) {
                                cursorShape = Qt.SplitHCursor
                                let newColWidth = dragColumnWidth + (event.x - dragInitialPos)
                                if (newColWidth >= 20) {
                                    let header = invoiceItemsModel.headers[dragColumnNo]
                                    let columnWidthId = 'width_' + header.id
                                    saveInvoiceItemColumnWidth(columnWidthId, newColWidth)
                                    //invoiceItemsTable.forceLayout()
                                }
                            } else if (isOverDragHandle(event.x)) {
                                cursorShape = Qt.SplitHCursor
                            } else {
                                cursorShape = Qt.ArrowCursor
                            }
                        }

                        onPressed: function(event) {
                            if (isOverDragHandle(event.x)) {
                                isDragging = true
                                dragInitialPos = event.x
                                dragColumnWidth = invoiceItemsTable.columnWidth(dragColumnNo)
                            }
                        }

                        onReleased: function(event) {
                            isDragging = false
                            if (dragColumnNo !== 3) {
                                invoiceItemsTable.updateColDescrWidth()
                            }
                        }

                        function isOverDragHandle(posx) {
                            dragColumnNo = -1
                            let colPos = 0;
                            for (let c = 0; c < horizontalHeader.columns; ++c) {
                                /* Where this column ends. The old reckoning took one and a half
                                   points off each column, to make up for a gap between them that
                                   the header no longer leaves: with the columns touching, the
                                   edge is simply the sum of their widths, and taking anything off
                                   moved every handle further out than the last. */
                                colPos += horizontalHeader.columnWidth(c) + horizontalHeader.columnSpacing
                                if (Math.abs(colPos - posx) < 7) {
                                    dragColumnNo = c
                                    return true;
                                }
                            }
                            return false;
                        }

                    }

                }

                TableView {
                    // Items table
                    id: invoiceItemsTable
                    model: invoiceItemsModel
                    reuseItems: false
                    clip: true

                    Layout.fillWidth: true
                    contentHeight: getTableHeigth()
                    // Room under the rows for the horizontal bar, so it does not sit on top
                    // of the last one. The view is exactly as tall as its content, so the
                    // strip has to be asked for.
                    Layout.minimumHeight: contentHeight + horizontalBarHeight
                    /* The cells touch: a gap between them would cut the tint of a row
                       into pieces, and the tint is what tells one row from the next now
                       that the cells carry no frame. Each cell pads its own text. */
                    rowSpacing: 0
                    columnSpacing: 0

                    /* A bar to drag the table sideways with: on a touch screen a drag started
                       on a cell puts it into edit and raises the keyboard. Always shown when
                       narrow, so it is also visible that the table continues past the edge. */
                    // Reserved only where a bar will occupy it: always when narrow, and when
                    // wide only while the columns do not fit. Otherwise the desktop would
                    // carry an empty gap under the table.
                    readonly property int horizontalBarHeight: (window.compactLayout
                                                               || contentWidth > width)
                                                              ? 14 * Stylesheet.pixelScaleRatio : 0

                    ScrollBar.horizontal: ScrollBar {
                        // Always there when narrow, since the table is wider than the screen
                        // whatever the document contains. On a wide screen only when the columns
                        // really do not fit - a dialog left narrow, or every column switched on.
                        policy: window.compactLayout ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        // Thickness through implicitHeight, never height: Qt places an attached
                        // scroll bar from its implicit size, and setting height outright moves
                        // it over the first row. Same value as the strip reserved above.
                        implicitHeight: invoiceItemsTable.horizontalBarHeight
                    }

                    flickableDirection: Flickable.AutoFlickIfNeeded
                    pointerNavigationEnabled: !invoice.isReadOnly
                    keyNavigationEnabled: !invoice.isReadOnly

                    selectionModel: ItemSelectionModel {}

                    property int signalUpdateRowHeights: 1
                    property int signalUpdateTableHeight: 1

                    Connections {
                        target: appSettings
                        function onFieldsVisibilityChanged() {
                            // Toggling a column in the Settings tab changes what
                            // columnWidthProvider() returns, but the view is not notified.
                            invoiceItemsTable.updateColDescrWidth()
                        }
                    }

                    Connections {
                        target: invoiceItemsTable
                        function onLayoutChanged() {
                        let curContentHeight = invoiceItemsTable.contentHeight
                        let desiredHeight = invoiceItemsTable.getTableHeigth()
                        if (curContentHeight !== desiredHeight)
                            invoiceItemsTable.contentHeight = desiredHeight
                        }
                    }


                    Keys.onPressed: function(event) {
                        let curItem = null
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Tab) {
                            if (!invoice.isReadOnly) {
                                curItem = invoiceItemsTable.itemAtCell(invoiceItemsTable.currentColumn, invoiceItemsTable.currentRow)
                                if (curItem.contentItem) {
                                    curItem.contentItem.focus = false
                                }
                                if (curItem) {
                                    curItem.focus = false
                                }
                                event.accepted = true
                                if (event.modifiers & Qt.ShiftModifier) {
                                    invoiceItemsTable.selectPreviousItem()
                                } else if (event.modifiers & Qt.ControlModifier) {
                                    var rowIndex = invoiceItemsTable.selectionModel.currentIndex.row
                                    if (rowIndex < 0 || (rowIndex + 1 < rowIndex.count)) {
                                        invoice.json.items.push(emptyInvoiceItem())
                                    } else {
                                        invoice.json.items.splice(rowIndex + 1, 0, emptyInvoiceItem())
                                    }
                                    invoice.setIsModified(true)
                                    updateViewItems()
                                    invoiceItemsTable.signalUpdateTableHeight++
                                    event.accepted = true
                                } else {
                                    invoiceItemsTable.selectNextItem()
                                }

                            } else {
                                event.accepted = true
                            }
                        } else if (event.key === Qt.Key_Backspace) {
                            if (!invoice.isReadOnly) {
                                curItem = invoiceItemsTable.itemAtCell(invoiceItemsTable.currentColumn, invoiceItemsTable.currentRow)
                                if (curItem) {
                                    if ('text' in curItem) {
                                        // we are on a textfield or textarea
                                        curItem.focus = true
                                        curItem.text = ""
                                        event.accepted = true
                                    } else if (curItem.contentItem && ('text' in curItem.contentItem)) {
                                        // we are on a combobox
                                        curItem.focus = true
                                        curItem.contentItem.focus = true
                                        curItem.contentItem.text = ""
                                        event.accepted = true
                                    }
                                }
                            } else {
                                event.accepted = true
                            }
                        } else if (/[A-Za-z0-9\-\.,]+/.test(event.text)) {
                            if (!invoice.isReadOnly) {
                                curItem = invoiceItemsTable.itemAtCell(invoiceItemsTable.currentColumn, invoiceItemsTable.currentRow)
                                if (curItem) {
                                    if ('text' in curItem) {
                                        // we are on a textfield or textarea
                                        curItem.focus = true
                                        curItem.text = event.text
                                        curItem.cursorPosition = 1
                                        event.accepted = true
                                    } else if (curItem.contentItem && ('text' in curItem.contentItem)) {
                                        // we are on a combobox
                                        curItem.focus = true
                                        curItem.contentItem.focus = true
                                        curItem.contentItem.text = event.text
                                        curItem.contentItem.cursorPosition = 1
                                        event.accepted = true
                                    }
                                }
                            } else {
                                event.accepted = true
                            }
                        }
                    }

                    columnWidthProvider: function(column) {
                        let header = invoiceItemsModel.headers[column]
                        if (header) {
                            let settingIdColumnVisible = 'show_' + header.id
                            let settingIdColumnWidth = 'width_' + header.id
                            let viewAppearance = appSettings.data.interface.invoice.views[currentView].appearance
                            if (settingIdColumnVisible in viewAppearance) {
                                let visible = viewAppearance[settingIdColumnVisible]
                                if (!visible) {
                                    return 0
                                }
                            } else {
                                let defaultViewAppearance = Settings.getDefaultSettings().interface.invoice.views[currentView].appearance
                                if (settingIdColumnVisible in defaultViewAppearance) {
                                    let visible = defaultViewAppearance[settingIdColumnVisible]
                                    if (!visible) {
                                        return 0
                                    }
                                }
                            }

                            // Room for the menu affordance beside the row number, only where
                            // that menu exists. Placed after the visibility checks above, so a
                            // column switched off still reports zero.
                            if (column === 0 && !invoice.isReadOnly) {
                                return 46 * Stylesheet.pixelScaleRatio
                            }

                            if (settingIdColumnWidth in viewAppearance) {
                                let width = viewAppearance[settingIdColumnWidth]
                                if (width > 10) {
                                    return width
                                }
                            } else {
                            }
                            return header.width
                        }
                    }

                    rowHeightProvider: function(row) {
                        /* A negative value sizes the row from its cells, so it grows by one line per
                           line of description; the original threw instead, which Qt treats the same
                           way. A changed implicit height is not noticed: see updateRowHeights(). */
                        return -1
                    }

                    delegate: DelegateChooser {

                        DelegateChoice {
                            // Column row number
                            column: 0
                            StyledTextField {
                                id: rowNumberCell
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                // Only while the keyboard is on the table: the current cell
                                // stays set afterwards, and would go on looking like it is being
                                // edited once the focus has moved to a field outside.
                                selected: current && invoiceItemsTable.activeFocus

                                // Captured from the model, so the mouse area below does not have
                                // to resolve them through its own context.
                                readonly property int cellRow: model.row
                                readonly property int cellColumn: model.column

                                readOnly: true
                                borderless: true
                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: model.display
                                verticalAlignment: Qt.AlignVCenter

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(row, column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }

                                /* The row's own menu, which is where the commands of the
                                   items table live at every width. In the row number cell:
                                   it is read only, and adding a column would shift the hard
                                   coded indices below. */
                                StyledLabel {
                                    visible: !invoice.isReadOnly
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "⋮"
                                    color: Stylesheet.mutedTextColor
                                }

                                MouseArea {
                                    // Clicking the cell makes its row the current one and
                                    // opens the menu of that row.
                                    enabled: !invoice.isReadOnly
                                    anchors.fill: parent
                                    onClicked: {
                                        let index = invoiceItemsModel.index(rowNumberCell.cellRow,
                                                                            rowNumberCell.cellColumn)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(
                                                    index, ItemSelectionModel.SelectCurrent)
                                        itemRowMenu.targetRow = rowNumberCell.cellRow
                                        itemRowMenu.popup(rowNumberCell, 0, rowNumberCell.height)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column item type
                            column: 1
                            StyledKeyDescrComboBox {
                                id: invoice_item_types
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                Layout.preferredWidth: 300 * Stylesheet.pixelScaleRatio
                                enabled: !invoice.isReadOnly

                                editable: false
                                model: invoiceItemTypesModel
                                textRole: "descr"
                                filterEnabled: true
                                currentIndex: -1
                                listItemTextIncludesKey: false

                                displayText: {
                                    // NB.: can't use model.row bz the widget has his hown model property, use simply row instead
                                    undoKey = display
                                    getDisplayText()
                                }

                                Connections {
                                    //                                    target: invoice
                                    //                                    function onInvoiceChanged() {
                                    //                                        if (invoice.json && invoice.json.document_info.vat_mode) {
                                    //                                            invoice_vat_mode.setCurrentKey(invoice.json.document_info.vat_mode)
                                    //                                        }
                                    //                                    }
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    if (!invoiceItemsTable.ensureItemForRow(row, key !== "")) {
                                        return
                                    }
                                    if (isExistingKey) {
                                        invoice.json.items[row].item_type = key
                                        if (!invoice.json.items[row].description) {
                                            if (key === "total" || key === "total1" || key === "total2") {
                                                let index = findKey(key)
                                                invoice.json.items[row].description = invoiceItemTypesModel.get(index).descr
                                            }
                                        }
                                        setDocumentModified()
                                        calculateInvoice()
                                    }
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(row, column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }

                                function getDisplayText() {
                                    if (row >= 0 && invoice.json && row < invoice.json.items.length) {
                                        let itemType = invoice.json.items[row].item_type
                                        let index = findKey(itemType)
                                        if (index > 0) {
                                            return invoiceItemTypesModel.get(index).descr
                                        }
                                    }
                                    return "";
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_item_column_type")
                                    onClicked: {
                                        dlgLicense.visible = true
                                    }
                                }

                            }
                        }

                        DelegateChoice {
                            // Column article number
                            column: 2
                            StyledKeyDescrComboBox {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                // Capped to the dialog width, see address_customer_selector.
                                popupMinWidth: Math.min(300 * Stylesheet.pixelScaleRatio, columnLayout.width)
                                editable: true
                                enabled: !invoice.isReadOnly
                                model: itemsModel
                                /** Usiamo "descr" al posto di "key" come già viene fatto dai altri combobox (vedi address_customer_selector) per
                                risolvere il problema della selezione con il click dalla lista*/
                                textRole: "descr"
                                filterEnabled: true

                                //currentIndex: -1
                                displayText: {
                                    // NB.: can't use model.row bz the widget has his hown model property, use simply row instead
                                    undoKey = display
                                    display
                                }

                                onCurrentKeySet: function(key, isExistingKey) {
                                    // NB.: can't use model.row bz the widget has his hown model property, use simply row instead
                                    if (!invoiceItemsTable.ensureItemForRow(row, key !== "")) {
                                        return
                                    }

                                    if (isExistingKey) {
                                        var itemId = key
                                        var vatExclusive = !isVatModeVatNone && !isVatModeVatInclusive
                                        let item = Items.itemGet(itemId, vatExclusive)
                                        if (item) {
                                            var vatCode = VatCodes.vatCodeGet(item.unit_price.vat_code)
                                            if (vatCode) {
                                                item.unit_price.vat_rate = vatCode.rate
                                            } else {
                                                // Fill with the default vat amount
                                                let hasAmount = item.unit_price.amount_vat_inclusive ||
                                                    item.unit_price.amount_vat_exclusive;
                                                if (hasAmount && !isVatModeVatNone && !item.unit_price.vat_rate) {
                                                    if (appSettings.data.new_documents.default_vat_code) {
                                                        item.unit_price.vat_code = appSettings.data.new_documents.default_vat_code
                                                        var defaultVatCode = VatCodes.vatCodeGet(item.unit_price.vat_code)
                                                        if (defaultVatCode) {
                                                            item.unit_price.vat_rate = defaultVatCode.rate
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            item = emptyInvoiceItem()
                                        }
                                        invoice.json.items[row] = item
                                        setDocumentModified()
                                        calculateInvoice()
                                    } else {
                                        invoice.json.items[row].number = key
                                        setDocumentModified()
                                    }
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(row, column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column date
                            column: 3
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                property int updateText: 1  // Binding for updating the text
                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: updateText && model.display ? Banana.Converter.toLocaleDateFormat( model.display) : ""
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_item_column_date")

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }

                                        let date = text
                                        if (date) {
                                            date = Banana.Converter.toInternalDateFormat(date)
                                            // Check date
                                            let localDate = Banana.Converter.toLocaleDateFormat(date)
                                            if (!localDate || localDate.length === 0) {
                                                errorMessageDialog.text = qsTr("Invalid date: " + text)
                                                errorMessageDialog.visible = true
                                                updateText++
                                                modified = false
                                                focus = false
                                                return
                                            }
                                        }
                                        invoice.json.items[model.row].date = date
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        setItemsModelDisplay(index, date)

                                        setDocumentModified()
                                        modified = false
                                    }
                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }

                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_item_column_date")) {
                                        dlgLicense.visible = true
                                    }
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column description
                            column: 4
                            StyledTextArea {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                id: textArea
                                selected: current && invoiceItemsTable.activeFocus

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: model.display
                                readOnly: invoice.isReadOnly

                                // As these rows come out on the printed document. The
                                // signalInvoiceChanged dependency is what re-evaluates this
                                // when the row type is changed from the Type combo box.
                                font.bold: invoice.signalInvoiceChanged &&
                                           (invoiceItemsTable.isHeaderRow(model.row) ||
                                            invoiceItemsTable.isTotalRow(model.row))

                                Keys.onTabPressed: function (event) {
                                    // Steal tab key
                                    if (focus) {
                                        focus = false
                                    }
                                    if (event.modifiers & Qt.ShiftModifier) {
                                        invoiceItemsTable.selectPreviousItem()
                                    } else {
                                        invoiceItemsTable.selectNextItem()
                                    }
                                    event.accepted = true;
                                }

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }

                                        invoice.json.items[model.row].description = text
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        setItemsModelDisplay(index, text)

                                        setDocumentModified()
                                        modified = false
                                    }
                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }

                                // In case the lines count change we emit a signal to update the row heigth
                                property int textLinesCount: 1

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }

                                onTextChanged: {
                                    /** Abbiamo aggiunto il nuovo controllo sull'esistenza della riga del modello perchè è apparso un warning nuovo
                                        che prima non cera, inizialmente non viene trovato l'oggetto: invoice.json.items[model.row]. Sembra che il controllo non cambi il comportamento corretto del programma, ma è
                                        da testare*/
                                    /* Edits typed by the user only: this also runs when `text` is
                                       re-evaluated from `model.display`, which pushed text into
                                       rows nobody had touched. Replaces StyledTextArea's guard. */
                                    if (!focus)
                                        return

                                    if (invoice.json.items[model.row]){
                                        if (model.row >= 0 && model.row < invoice.json.items.length) {
                                            invoice.json.items[model.row].description = text;
                                        }
                                    }
                                }

                                onImplicitHeightChanged: {
                                    // The height the text needs has changed: a line break, the
                                    // text wrapping on its own, a bold font, a new column width.
                                    // Counting lines from the text instead missed the wrapping.
                                    invoiceItemsTable.updateRowHeights()
                                }
                            }
                        }

                        DelegateChoice {
                            // Column quantity
                            column: 5
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                /**
                                  Abbiamo rimosso il "Banana.Converter.toLocaleNumberFormat(model.display)" per permettere
                                  all'utente di inserire la quantità come un testo libero, in modo che i decimali non vengano
                                  sempre formattati allo stesso modo. Sarà da aggiungere un controllo per non permettere all'utente di
                                  inserire un testo, come già accade per altri campi (vedi data) */
                                text: model.display  ? model.display: "";
                                readOnly: invoice.isReadOnly
                                enabled: !invoiceItemsTable.isTotalRow(model.row)

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }
                                        let quantity = text ? Banana.Converter.toInternalNumberFormat(text) : ""
                                        invoice.json.items[model.row].quantity = quantity
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        setItemsModelDisplay(index, text)
                                        setDocumentModified()
                                        calculateInvoice()
                                        modified = false
                                    }
                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column mesure unit
                            column: 6
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: model.display
                                readOnly: invoice.isReadOnly
                                enabled: !invoiceItemsTable.isTotalRow(model.row)

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }

                                        invoice.json.items[model.row].mesure_unit = text
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        setItemsModelDisplay(index, text)

                                        setDocumentModified()
                                        modified = false
                                    }
                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column quantity
                            column: 7
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: toLocaleItemNumberFormat(model.display)
                                readOnly: invoice.isReadOnly
                                enabled: !invoiceItemsTable.isTotalRow(model.row)

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }

                                        let item = invoice.json.items[row];
                                        let internalAmountFormat = text ? toInternalItemNumberFormat(text) : ""
                                        if (isVatModeVatInclusive) {
                                            item.unit_price.amount_vat_inclusive = internalAmountFormat
                                            item.unit_price.amount_vat_exclusive = null
                                        } else {
                                            item.unit_price.amount_vat_inclusive = null
                                            item.unit_price.amount_vat_exclusive = internalAmountFormat
                                        }
                                        if (internalAmountFormat && !invoice.json.items[model.row].quantity) {
                                            // Set quantity if a price is set
                                            invoice.json.items[model.row].quantity = "1"
                                            // Fill quantity if a price is set
                                            item.quantity = "1"
                                        }
                                        if (internalAmountFormat && !isVatModeVatNone && !item.unit_price.vat_rate) {
                                            // Set default vat code
                                            if (appSettings.data.new_documents.default_vat_code) {
                                                item.unit_price.vat_code = appSettings.data.new_documents.default_vat_code
                                                var vatCode = VatCodes.vatCodeGet(item.unit_price.vat_code)
                                                if (vatCode) {
                                                    item.unit_price.vat_rate = vatCode.rate
                                                }
                                            }
                                        }

                                        setDocumentModified()
                                        calculateInvoice()
                                        modified = false
                                    }

                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column discount
                            column: 8
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: toLocaleItemDiscountFormat(model.display)
                                placeholderText: hovered ? qsTr("30% or 30.00") : ""
                                readOnly: invoice.isReadOnly || !appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_item_column_discount")
                                enabled: !invoiceItemsTable.isTotalRow(model.row)

                                onEditingFinished: {
                                    if (modified) {
                                        if (!invoiceItemsTable.ensureItemForRow(row, text.trim() !== "")) {
                                            modified = false
                                            focus = false
                                            return
                                        }

                                        let discount = parseDiscountFormat(text)
                                        if (discount.isZero) {
                                            delete invoice.json.items[model.row].discount
                                        } else if (discount.isPercentage) {
                                            invoice.json.items[model.row].discount = {
                                                'percent' : discount.value
                                            }
                                        } else {
                                            invoice.json.items[model.row].discount = {
                                                'amount' : discount.value
                                            }
                                        }
                                        setDocumentModified()
                                        calculateInvoice()
                                        modified = false
                                    }

                                    focus = false // call at the end, if not with the tab key the edited text is lost
                                }
                                onPressed: {
                                    if (!appSettings.meetInvoiceFieldLicenceRequirement("show_invoice_item_column_discount")) {
                                        dlgLicense.visible = true
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column total
                            column: 9
                            StyledTextField {
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                readOnly: true
                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: toLocaleItemTotalFormat(model.display, model.row)
                                // Subtotal rows carry the figure that matters on that line
                                font.bold: invoice.signalInvoiceChanged &&
                                           invoiceItemsTable.isTotalRow(model.row)

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }

                        DelegateChoice {
                            // Column vat
                            column: 10
                            StyledKeyDescrComboBox {
                                id: invoice_item_vat
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)
                                selected: current && invoiceItemsTable.activeFocus

                                // Capped to the dialog width, see address_customer_selector.
                                popupMinWidth: Math.min(300 * Stylesheet.pixelScaleRatio, columnLayout.width)
                                popupAlign: Qt.AlignRight

                                currentIndex: getCurrentVatCodeIndex()
                                displayText: getDisplayText()

                                model: taxRatesModel
                                textRole: "key"
                                editable: true // set to true to make tab navitation working
                                enabled: !invoice.isReadOnly && !invoiceItemsTable.isTotalRow(row)

                                onCurrentKeySet: function(key, isExistingKey) {
                                    // NB.: can't use model.row bz the widget has his hown model property, use simply row instead
                                    let vatItem = invoice_item_vat.getCurrentItem()
                                    if (!invoiceItemsTable.ensureItemForRow(row, vatItem ? true : false)) {
                                        return
                                    }

                                    if (vatItem) {
                                        invoice.json.items[row].unit_price.vat_code = vatItem.key
                                        invoice.json.items[row].unit_price.vat_rate = vatItem.rate
                                        setDocumentModified()
                                        calculateInvoice()
                                    }

                                }

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(row, column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }

                                function getDisplayText() {
                                    if (display) {
                                        return display
                                    } else if (row >= 0 && invoice.json && row < invoice.json.items.length) {
                                        // If the code is not set, show the rate
                                        if (invoice.json.items[row].unit_price.vat_rate) {
                                            return invoice.json.items[row].unit_price.vat_rate
                                        }
                                    }
                                    return "";
                                }

                                function updateInvoiceItem() {
                                    if (row >= 0 && row < invoice.json.items.length) {
                                        var vatRate = getCurrentVatCode()
                                        invoice.json.items[row].unit_price.vat_rate = vatRate.rate
                                        if (vatRate.code)
                                            invoice.json.items[row].unit_price.vat_code = vatRate.code
                                        else
                                            delete invoice.json.items[row].unit_price.vat_code
                                        setDocumentModified()
                                        calculateInvoice()
                                    }
                                }

                                function getCurrentVatCodeIndex() {
                                    if (row >= 0 && row < invoice.json && invoice.json.items.length) {
                                        if (invoice.json.items[row].unit_price.vat_code) {
                                            var itemVatCode = invoice.json.items[row].unit_price.vat_code
                                            for (var i = 0; i < model.count; i++) {
                                                if (model.get(i).code === itemVatCode) {
                                                    return i
                                                }
                                            }
                                        }
                                        invoice_item_vat.editText = invoice.json.items[row].unit_price.vat_rate
                                    }
                                    return -1
                                }

                                function getCurrentVatCode() {
                                    var vatRate = ""
                                    if (currentIndex > 0) {
                                        var currentVatRate = model.get(currentIndex)
                                        vatRate = {
                                            rate: currentVatRate.rate,
                                            code: currentVatRate.code,
                                        }

                                    } else if (currentIndex === 0) {
                                        vatRate = {
                                            rate: ""
                                        }

                                    } else if (currentIndex < 0) {
                                        var vatCode = VatCodes.vatCodeGet(editText)
                                        vatRate = {
                                            rate: editText,
                                        }

                                    } else {
                                        vatRate = {
                                            rate: ""
                                        }
                                    }

                                    if (Banana.SDecimal.isZero(vatRate.rate))
                                        vatRate.rate = ""

                                    return vatRate
                                }
                            }
                        }

                        DelegateChoice {
                            // Column default (not used)
                            StyledTextField {
                                required property bool selected
                                required property bool current
                                /* Declared rather than taken from the context: the
                                   colour of the row is read at binding time, and a
                                   context property that is not there yet reads as
                                   undefined - every row would come out the same. */
                                required property int row
                                // A cell of the table: the colour of its row, no
                                // frame of its own - see StyledTextField.cellMode.
                                cellMode: true
                                cellBackground: invoiceItemsTable.rowColor(row)

                                horizontalAlignment: invoiceItemsModel.headers[model.column].align
                                text: model.display
                                readOnly: invoice.isReadOnly

                                onFocusChanged: {
                                    if (focus) {
                                        let index = invoiceItemsModel.index(model.row, model.column)
                                        invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                                    }
                                }
                            }
                        }
                    }

                    onWidthChanged: {
                        invoiceItemsTable.updateColDescrWidth()
                    }


                    function appendNewRow() {
                        // Add new item in invoice, will be set next
                        let newItem = emptyInvoiceItem()
                        invoice.json.items.push(newItem)
                        // Set row nr in model
                        let index = invoiceItemsModel.index(invoiceItemsModel.rowCount - 1, 0)
                        setItemsModelDisplay(index, invoiceItemsModel.rowCount)
                        // Add new row in model
                        let newRowItem = invoiceItemToModelItem(newItem, '*');
                        invoiceItemsModel.appendRow(newRowItem)
                        signalUpdateTableHeight++
                    }

                    /* Called by a cell before it writes into its row. The trailing "*" row becomes a
                       real item here, but only when the cell was left with a value: leaving a cell
                       counts as an edit, which added an empty row every time. False: caller stops. */
                    function ensureItemForRow(row, hasValue) {
                        if (!isNewRow(row))
                            return true
                        if (!hasValue)
                            return false
                        appendNewRow()
                        return true
                    }

                    FontMetrics {
                        id: fontMetrics
                    }

                    function estimateWordWrapLines(text) {
                        let texts = text.split("\n");
                        // in case columnWidth = -1 assign number of lines
                        let numberOfLines = texts.length;
                        let columnWidth = invoiceItemsTable.columnWidth(4);
                        if (columnWidth <= 0) {
                            // Through the provider, not columnWidth(): that one returns -1 while the
                            // table is being built and whenever the column is scrolled out of sight,
                            // and a fixed width in its place made the rows many times too tall.
                            columnWidth = invoiceItemsTable.columnWidthProvider(4)
                        }
                        if (columnWidth > 0 ){
                            numberOfLines = 0;
                            for (var i = 0; i < texts.length; i++) {
                                if (texts[i].length > 1 ) {
                                    let elementWidth = fontMetrics.advanceWidth(texts[i]);
                                    let elementLines = elementWidth / columnWidth
                                    numberOfLines += Math.ceil(elementLines)
                                } else {
                                    numberOfLines ++;
                                }
                            }
                        }

                        return numberOfLines;
                    }

                    function getTableHeigth() {
                        if (!invoice.json || !invoice.json.items){
                            return 400 * Stylesheet.pixelScaleRatio
                        }

                        // Just for binding
                        if (!signalUpdateRowHeights || !signalUpdateTableHeight || !appSettings.signalItemsVisibilityChanged) {
                            return 400 * Stylesheet.pixelScaleRatio
                        }

                        // Currently we disable the mechanism wich activate the table scroll based on
                        //the height of visible content in rows 24.01.2024
                        /*let maxVisibleItems = getMaxVisibleItems()
                        if (maxVisibleItems > 0) {
                            return (30 + 30 * maxVisibleItems)  * Stylesheet.pixelScaleRatio

                        }*/
                        else {
                            // The trailing "*" row is measured here rather than given a fixed
                            // height, which cut off text typed into it. Only the fixed numbers are
                            // scaled: the measured heights are scaled pixels already.
                            let newRowHeight = rowHeight(invoice.json.items.length)
                            let height = Math.max(34 * Stylesheet.pixelScaleRatio, newRowHeight);
                            for (let rowNr = 0; rowNr < invoice.json.items.length; ++rowNr) {
                                // This function does not correctly calculate the heigth when there is a word wrap.
                                // We should try to use directly the line hiegth.
                                //let linesCount = invoice.json.items[rowNr].description.split('\n').length
                                let linesCount = estimateWordWrapLines(invoice.json.items[rowNr].description)
                                let lineHeight = (30 + 16 * (linesCount - 1)) * Stylesheet.pixelScaleRatio
                                if (rowHeight(rowNr) > 0){
                                    lineHeight = rowHeight(rowNr) + rowSpacing
                                }
                                height += lineHeight
                            }
                            return height
                        }
                    }
                    function getMaxVisibleItems() {
                        let maxVisibleItems = 0
                        if (currentView === appSettings.view_id_full) {
                            return 0
                        }
                        if (appSettings.data.interface.invoice.views[currentView] &&
                                ('invoce_max_visible_items_without_scrolling' in appSettings.data.interface.invoice.views[currentView].appearance)) {
                            maxVisibleItems = appSettings.data.interface.invoice.views[currentView].appearance['invoce_max_visible_items_without_scrolling'];
                                }
                        return maxVisibleItems
                    }

                    /* The four commands the items table offers. Here rather than inside the
                       buttons, because the row menu offers the same four on a narrow screen.
                       Each body is what its button did, moved unchanged. */

                    function addItemRow(rowIndex) {
                        // "rowIndex.count" is undefined on a number, so this reads as "append
                        // when no row is current, otherwise insert below it". Left as found:
                        // tidying it would change what the button has always done.
                        if (rowIndex < 0 || (rowIndex + 1 < rowIndex.count)) {
                            invoice.json.items.push(emptyInvoiceItem())
                        } else {
                            invoice.json.items.splice(rowIndex + 1, 0, emptyInvoiceItem())
                        }
                        invoice.setIsModified(true)
                        updateViewItems()
                        invoiceItemsTable.signalUpdateTableHeight++
                    }

                    function removeItemRow(rowIndex) {
                        if (rowIndex >= 0 && rowIndex < invoiceItemsModel.rowCount) {
                            invoice.json.items.splice(rowIndex, 1)
                        }
                        invoice.setIsModified(true)
                        calculateInvoice()
                        updateView()
                        //signalUpdateTableHeight++ not necessary cz updateView
                    }

                    function moveItemRowUp(itemRow, itemCol) {
                        if (itemRow > 0 && itemRow < invoiceItemsModel.rowCount) {
                            var itemCopy = invoice.json.items[itemRow]
                            if (!itemCopy)
                                itemCopy = emptyInvoiceItem()
                            invoice.json.items[itemRow] = invoice.json.items[itemRow-1]
                            invoice.json.items[itemRow - 1] = itemCopy
                            calculateInvoice()
                            updateViewItems()
                            invoiceItemsTable.focus = true

                            let index = invoiceItemsModel.index(itemRow - 1, itemCol)
                            invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                        }
                    }

                    function moveItemRowDown(itemRow, itemCol) {
                        if (itemRow >= 0 && itemRow < invoiceItemsModel.rowCount - 1) {
                            var itemCopy = invoice.json.items[itemRow]
                            invoice.json.items[itemRow] = invoice.json.items[itemRow+1]
                            invoice.json.items[itemRow + 1] = itemCopy
                            calculateInvoice()
                            updateViewItems()
                            invoiceItemsTable.focus = true

                            let index = invoiceItemsModel.index(itemRow + 1, itemCol)
                            invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                        }
                    }

                    /* The colour of one row: every other one carries a tint, and the
                       trailing "*" row carries none - it is not a row of the document yet. */
                    function rowColor(row) {
                        if (row < 0 || isNewRow(row))
                            return "transparent"
                        return (row % 2 === 1) ? Stylesheet.rowAlternateColor : "transparent"
                    }

                    function isNewRow(row) {
                        if (row >= invoice.json.items.length) {
                            return true
                        }
                        return false
                    }

                    function isTotalRow(row) {
                        if (row >= 0 && invoice && invoice.json && invoice.json.items && row < invoice.json.items.length) {
                            let item_type = invoice.json.items[row].item_type
                            if (item_type === "total" || item_type === "total1" || item_type === "total2") {
                                return true
                            }
                        }
                        return false
                    }

                    /* Header rows are printed bold (description only), like isTotalRow above.
                       Callers must depend on invoice.signalInvoiceChanged to re-evaluate, as
                       this reads invoice.json directly and is not bindable on its own. */
                    function isHeaderRow(row) {
                        if (row >= 0 && invoice && invoice.json && invoice.json.items && row < invoice.json.items.length) {
                            return invoice.json.items[row].item_type === "header"
                        }
                        return false
                    }

                    function selectNextItem() {
                        let nextItem = null
                        let nextRow = invoiceItemsTable.currentRow
                        let nextColumn = 0
                        // Find next item on the same row
                        for (nextColumn = invoiceItemsTable.currentColumn + 1; nextColumn <  invoiceItemsTable.columns; ++nextColumn) {
                            if (invoiceItemsTable.columnWidth(nextColumn) > 0) {
                                nextItem  = invoiceItemsTable.itemAtCell(nextColumn, nextRow)
                                if (nextItem) {
                                    break;
                                }
                            }
                        }
                        // Find next item on the next row
                        if (!nextItem) {
                            nextRow++
                            for (nextColumn = 0; nextColumn <  invoiceItemsTable.columns; ++nextColumn) {
                                if (invoiceItemsTable.columnWidth(nextColumn) > 0) {
                                    nextItem  = invoiceItemsTable.itemAtCell(nextColumn, nextRow)
                                    if (nextItem) {
                                        break;
                                    }
                                }
                            }
                        }
                        if (nextItem) {
                            let index = invoiceItemsModel.index(nextRow, nextColumn)
                            invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                            // The keyboard belongs to the table, not to the cell: the table is
                            // what sends a typed character to the current cell, and what the
                            // cells read to mark themselves - see "selected" in the delegates.
                            invoiceItemsTable.forceActiveFocus()
                            return nextItem
                        }
                        return null
                    }

                    function selectPreviousItem() {
                        let prevItem = null
                        let prevRow = invoiceItemsTable.currentRow
                        let prevColumn = 0
                        // Find previous item on the same row
                        for (prevColumn = invoiceItemsTable.currentColumn - 1; prevColumn >= 0; --prevColumn) {
                            if (invoiceItemsTable.columnWidth(prevColumn) > 0) {
                                prevItem  = invoiceItemsTable.itemAtCell(prevColumn, prevRow)
                                if (prevItem) {
                                    break;
                                }
                            }
                        }
                        // Find previous item on the previous row
                        if (!prevItem) {
                            prevRow--
                            for (prevColumn = invoiceItemsTable.columns - 1; prevColumn >= 0; --prevColumn) {
                                if (invoiceItemsTable.columnWidth(prevColumn) > 0) {
                                    prevItem  = invoiceItemsTable.itemAtCell(prevColumn, prevRow)
                                    if (prevItem) {
                                        break;
                                    }
                                }
                            }
                        }
                        if (prevItem) {
                            let index = invoiceItemsModel.index(prevRow, prevColumn)
                            invoiceItemsTable.selectionModel.setCurrentIndex(index, ItemSelectionModel.SelectCurrent)
                            invoiceItemsTable.forceActiveFocus()
                            return prevItem
                        }
                        return null
                    }

                    Timer {
                        // updateColDescrWidth() runs from onWidthChanged, and forceLayout() from
                        // inside a layout pass is re-entrant, undefined per Qt docs. A 0-interval
                        // timer runs it after, and coalesces the width changes of a resize.
                        id: updateColDescrWidthTimer
                        interval: 0
                        repeat: false
                        onTriggered: invoiceItemsTable.applyColDescrWidth()
                    }

                    function updateColDescrWidth() {
                        updateColDescrWidthTimer.restart()
                    }

                    function applyColDescrWidth() {
                        let colDescriptionIndex = 4
                        let headerColDescription = invoiceItemsModel.headers[colDescriptionIndex]
                        if (!headerColDescription || width <= 0)
                            return
                        if (columnWidthProvider(colDescriptionIndex) <= 0)
                            return // Description hidden in this view: nothing to size

                        // Through columnWidthProvider(), NOT contentWidth: that one is the layout
                        // on screen, the provider already the current view, and the two disagree
                        // after a view switch. Mixing them blew Description up, and it was saved.
                        let otherColumnsWidth = 0
                        let visibleColumns = 0
                        for (let col = 0; col < invoiceItemsModel.headers.length; ++col) {
                            let colWidth = columnWidthProvider(col)
                            if (colWidth > 0) {
                                ++visibleColumns
                                if (col !== colDescriptionIndex)
                                    otherColumnsWidth += colWidth
                            }
                        }

                        let spacing = columnSpacing * Math.max(0, visibleColumns - 1)
                        let newColDescriptionWidth = Math.max(200 * Stylesheet.pixelScaleRatio,
                                                              width - otherColumnsWidth - spacing)
                        let columnWidthId = 'width_' + headerColDescription.id
                        saveInvoiceItemColumnWidth(columnWidthId, newColDescriptionWidth)
                        // Relayout AFTER storing the new width: otherwise the view keeps the
                        // previous layout while columnWidthProvider() already reports the new one.
                        invoiceItemsTable.forceLayout()

                        // If the fresh layout still overflows, take the overflow off
                        // Description. Runs at most once: the new width is strictly smaller.
                        if (contentWidth > width) {
                            let corrected = Math.max(200 * Stylesheet.pixelScaleRatio,
                                                     newColDescriptionWidth - (contentWidth - width))
                            if (corrected < newColDescriptionWidth) {
                                saveInvoiceItemColumnWidth(columnWidthId, corrected)
                                invoiceItemsTable.forceLayout()
                            }
                        }
                    }

                    Timer {
                        // Deferred like updateColDescrWidthTimer above: the request comes from a
                        // cell still handling a key press, which forceLayout() would resize in the
                        // middle of its own update. Zero interval also merges the requests.
                        id: updateRowHeightsTimer
                        interval: 0
                        repeat: false
                        onTriggered: {
                            invoiceItemsTable.forceLayout()
                            invoiceItemsTable.signalUpdateRowHeights++
                        }
                    }

                    function updateRowHeights() {
                        updateRowHeightsTimer.restart()
                    }
                    }

                Menu {
                    /* The commands for one row, from the row number cell on a narrow screen.
                       Each entry calls the function its button calls. The trailing "*" row does
                       not exist yet, so there is nothing there to remove or move. */
                    id: itemRowMenu

                    property int targetRow: -1
                    readonly property bool onNewRow: targetRow < 0
                                                     || invoiceItemsTable.isNewRow(targetRow)

                    // Same colours and same drawing as the menu of the bottom bar, for the
                    // same reason: see overflowMenu in DlgInvoice.qml.
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
                        text: qsTr("Add")
                        onTriggered: invoiceItemsTable.addItemRow(itemRowMenu.targetRow)
                    }

                    StyledMenuEntry {
                        // An invisible menu entry still reserves its row, so it gives up its
                        // height as well to disappear.
                        text: qsTr("Remove")
                        visible: !itemRowMenu.onNewRow
                        height: visible ? implicitHeight : 0
                        onTriggered: invoiceItemsTable.removeItemRow(itemRowMenu.targetRow)
                    }

                    StyledMenuEntry {
                        text: qsTr("Move up")
                        visible: !itemRowMenu.onNewRow && itemRowMenu.targetRow > 0
                        height: visible ? implicitHeight : 0
                        onTriggered: invoiceItemsTable.moveItemRowUp(itemRowMenu.targetRow, 0)
                    }

                    StyledMenuEntry {
                        text: qsTr("Move Down")
                        visible: !itemRowMenu.onNewRow
                                 && itemRowMenu.targetRow + 2 < invoiceItemsTable.rows
                        height: visible ? implicitHeight : 0
                        onTriggered: invoiceItemsTable.moveItemRowDown(itemRowMenu.targetRow, 0)
                    }
                }

                RowLayout { // What the document comes to
                    /* On the trailing edge, under the table it adds up. What sits beside
                       it is left empty on purpose: the texts were tried there and read as
                       two unrelated things pushed together to fill the room. */
                    Layout.fillWidth: true
                    Layout.topMargin: Stylesheet.spacingBase
                    spacing: Stylesheet.defaultMargin

                    Item {
                        // Holds the totals to the trailing edge. In a single column there
                        // is no spare width to give away.
                        visible: !window.compactLayout
                        Layout.fillWidth: true
                    }

                    ColumnLayout { // What the document comes to
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        Layout.fillWidth: window.compactLayout
                        spacing: Stylesheet.spacingBase

                        StyledCard {
                            id: totalsCard

                            Layout.alignment: Qt.AlignRight
                            Layout.fillWidth: window.compactLayout
                            // Room for a description, the figure that is typed into it, and the
                            // amount it works out to, side by side.
                            implicitWidth: 360 * Stylesheet.pixelScaleRatio
                            contentSpacing: Stylesheet.spacingTight

                            GridLayout {
                                id: columnLayoutTotal

                                columns: 2
                                columnSpacing: Stylesheet.spacingBase
                                rowSpacing: Stylesheet.spacingTight
                                Layout.fillWidth: true

                                StyledLabel {
                                    Layout.fillWidth: true
                                    text: isVatModeVatNone ? qsTr("Subtotal") : isVatModeVatInclusive ? qsTr("Subtotal") : qsTr("Total Net")
                                }

                                StyledTextField {
                                    id: subtotal_amount
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: invoice.json ?
                                              toLocaleNumberFormat(
                                                  (isVatModeVatNone || isVatModeVatInclusive) ?
                                                      invoice.json.billing_info.total_amount_vat_inclusive_before_discount :
                                                      invoice.json.billing_info.total_amount_vat_exclusive_before_discount,
                                                  true
                                                  ) : ""
                                }

                                RowLayout {
                                    // The discount as it is agreed - a percentage or an amount -
                                    // beside the name it is printed under.
                                    Layout.fillWidth: true
                                    spacing: Stylesheet.spacingTight

                                    StyledTextField {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 60 * Stylesheet.pixelScaleRatio
                                        text: getDiscountDescription()
                                        readOnly: invoice.isReadOnly
                                        borderless: !hovered && !focus

                                        onEditingFinished: {
                                            if (modified) {
                                                setDiscountDescription(text)
                                                if (!text) {
                                                    text = qsTr("Discount")
                                                }
                                            }
                                        }

                                        function getDiscountDescription() {
                                            if (invoice.json && invoice.json.billing_info && invoice.json.billing_info.discount) {
                                                if (invoice.json.billing_info.discount.description)
                                                    return invoice.json.billing_info.discount.description
                                            }
                                            return qsTr("Discount");
                                        }

                                        function setDiscountDescription(description) {
                                            if (!invoice.json)
                                                return
                                            if (!invoice.json.billing_info)
                                                invoice.json.billing_info = {}
                                            if (!invoice.json.billing_info.discount)
                                                invoice.json.billing_info.discount = {}
                                            invoice.json.billing_info.discount.description = description
                                                }
                                    }

                                    StyledTextField {
                                        id: discount_amount
                                        filled: true
                                        Layout.preferredWidth: 90 * Stylesheet.pixelScaleRatio
                                        readOnly: invoice.isReadOnly
                                        text: invoice.json ? getDiscount() : ""
                                        placeholderText: hovered && !text ? qsTr("30% or 30.00") : ""
                                        horizontalAlignment: Text.AlignRight

                                        onEditingFinished: {
                                            if (modified) {
                                                let discount = parseDiscountFormat(text)
                                                if (discount.isZero) {
                                                    delete invoice.json.billing_info.discount
                                                } else if (discount.isPercentage) {
                                                    if (!invoice.json.billing_info.discount)
                                                        invoice.json.billing_info.discount = {}
                                                    delete invoice.json.billing_info.discount.percent
                                                    delete invoice.json.billing_info.discount.percent_vat_inclusive
                                                    delete invoice.json.billing_info.discount.percent_vat_exclusive
                                                    delete invoice.json.billing_info.discount.amount
                                                    delete invoice.json.billing_info.discount.amount_vat_inclusive
                                                    delete invoice.json.billing_info.discount.amount_vat_exclusive
                                                    if (!isVatModeVatInclusive) {
                                                       invoice.json.billing_info.discount.percent_vat_exclusive = discount.value
                                                    } else {
                                                       invoice.json.billing_info.discount.percent_vat_inclusive = discount.value
                                                    }
                                                } else {
                                                    if (!invoice.json.billing_info.discount)
                                                        invoice.json.billing_info.discount = {}
                                                    delete invoice.json.billing_info.discount.percent
                                                    delete invoice.json.billing_info.discount.percent_vat_inclusive
                                                    delete invoice.json.billing_info.discount.percent_vat_exclusive
                                                    delete invoice.json.billing_info.discount.amount
                                                    delete invoice.json.billing_info.discount.amount_vat_inclusive
                                                    delete invoice.json.billing_info.discount.amount_vat_exclusive
                                                    if (!isVatModeVatInclusive) {
                                                        invoice.json.billing_info.discount.amount_vat_exclusive = discount.value
                                                    } else {
                                                        invoice.json.billing_info.discount.amount_vat_inclusive = discount.value
                                                    }
                                                        }
                                                calculateInvoice()
                                            }
                                        }

                                        function getDiscount() {
                                            if (invoice.json && invoice.json.billing_info && invoice.json.billing_info.discount) {
                                                if (invoice.json.billing_info.discount.percent) {
                                                    let value = invoice.json.billing_info.discount.percent
                                                    let dec = getDecimalsCount(value);
                                                    return Banana.Converter.toLocaleNumberFormat(value, dec, true) + "%"
                                                } else if (invoice.json.billing_info.discount.percent_vat_inclusive) {
                                                    let value = invoice.json.billing_info.discount.percent_vat_inclusive
                                                    let dec = getDecimalsCount(value);
                                                    return Banana.Converter.toLocaleNumberFormat(value, dec, true) + "%"
                                                } else if (invoice.json.billing_info.discount.percent_vat_exclusive) {
                                                    let value = invoice.json.billing_info.discount.percent_vat_exclusive
                                                    let dec = getDecimalsCount(value);
                                                    return Banana.Converter.toLocaleNumberFormat(value, dec, true) + "%"
                                                } else if (invoice.json.billing_info.discount.amount_vat_inclusive) {
                                                    let value = invoice.json.billing_info.discount.amount_vat_inclusive
                                                    return toLocaleNumberFormat(value, false)
                                                } else if (invoice.json.billing_info.discount.amount_vat_exclusive) {
                                                    let value = invoice.json.billing_info.discount.amount_vat_exclusive
                                                    return toLocaleNumberFormat(value, false)
                                                } else if (invoice.json.billing_info.discount.amount) {
                                                    let value = invoice.json.billing_info.discount.amount
                                                    return toLocaleNumberFormat(value, false)
                                                }
                                            }
                                            return ""
                                        }
                                    }
                                }

                                StyledTextField {
                                    id: invoice_totals_discount
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: toLocaleNumberFormat(invoice.json ? getDiscountAmount() : "", true)

                                    function getDiscountAmount() {
                                        let amount = ""
                                        if (invoice.json && invoice.json.billing_info) {
                                            if (isVatModeVatNone || isVatModeVatInclusive) {
                                                if (invoice.json.billing_info.total_discount_vat_inclusive) {
                                                    amount = invoice.json.billing_info.total_discount_vat_inclusive
                                                } else if (invoice.json.billing_info.discount && invoice.json.billing_info.discount.amount) {
                                                    amount = invoice.json.billing_info.discount.amount
                                                }
                                            } else {
                                                if (invoice.json.billing_info.total_discount_vat_exclusive) {
                                                    amount = invoice.json.billing_info.total_discount_vat_exclusive
                                                } else if (invoice.json.billing_info.discount && invoice.json.billing_info.discount.amount) {
                                                    amount = invoice.json.billing_info.discount.amount
                                                }
                                            }
                                        }
                                        if (amount)
                                            amount = Banana.SDecimal.invert(amount)
                                        return amount
                                    }
                                }

                                StyledLabel {
                                    Layout.fillWidth: true
                                    visible: vattotal_amount.visible
                                    text: qsTr("VAT")
                                }

                                StyledTextField {
                                    id: vattotal_amount
                                    // Only where the prices are net: with VAT included in them
                                    // there is nothing to add on top.
                                    visible: !isVatModeVatNone && !isVatModeVatInclusive
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: toLocaleNumberFormat(
                                              invoice.json ? invoice.json.billing_info.total_vat_amount : "",
                                              true)
                                }

                                StyledLabel {
                                    Layout.fillWidth: true
                                    text: qsTr("Rounding")
                                    visible: rounding_total_amounts.visible
                                }

                                StyledTextField {
                                    id: rounding_total_amounts
                                    // Only when it actually rounds something: a line of zeroes
                                    // says nothing and the totals are easier to read without it.
                                    visible: !isLocaleZero(text)
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: toLocaleNumberFormat(
                                              invoice.json ? invoice.json.billing_info.total_rounding_difference : "",
                                              true)
                                }

                                RowLayout {
                                    // What has already been paid, beside the name it is printed
                                    // under - written like the discount above it.
                                    Layout.fillWidth: true
                                    spacing: Stylesheet.spacingTight

                                    StyledTextField {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 60 * Stylesheet.pixelScaleRatio
                                        text: getDepositDescription()
                                        readOnly: invoice.isReadOnly
                                        borderless: !hovered && !focus

                                        onEditingFinished: {
                                            if (modified) {
                                                setDepositDescription(text)
                                                if (!text)
                                                    text = qsTr("Deposit")
                                            }
                                        }

                                        function getDepositDescription() {
                                            if (invoice.json && invoice.json.billing_info && invoice.json.billing_info.total_advance_payment_description) {
                                                return invoice.json.billing_info.total_advance_payment_description
                                            }
                                            return qsTr("Deposit");
                                        }

                                        function setDepositDescription(description) {
                                            if (!invoice.json || !invoice.json.billing_info)
                                                return
                                            invoice.json.billing_info.total_advance_payment_description = description
                                            setDocumentModified()
                                        }
                                    }

                                    StyledTextField {
                                        id: deposit_amount
                                        filled: true
                                        horizontalAlignment: Text.AlignRight
                                        Layout.preferredWidth: 90 * Stylesheet.pixelScaleRatio
                                        readOnly: invoice.isReadOnly
                                        text: toLocaleNumberFormat(invoice.json ? getDepositAmount() : "")

                                        onEditingFinished: {
                                            if (modified) {
                                                let amount = ""
                                                if (!isLocaleZero(text)) {
                                                    amount = toInternalNumberFormat(text)
                                                    amount = Banana.SDecimal.invert(amount)
                                                    amount = Banana.SDecimal.round(amount, {'decimals': getRoundingDecimals()})
                                                    }
                                                invoice.json.billing_info.total_advance_payment = amount
                                                calculateInvoice()
                                            }
                                        }

                                        function getDepositAmount() {
                                            if (invoice.json && invoice.json.billing_info && invoice.json.billing_info.total_advance_payment) {
                                                return Banana.SDecimal.invert(invoice.json.billing_info.total_advance_payment)
                                            }
                                            return "";
                                        }
                                    }
                                }

                                StyledTextField {
                                    id: invoice_totals_deposit
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: invoice.json ? getDepositAmount() : ""

                                    function getDepositAmount() {
                                        if (invoice.json && invoice.json.billing_info && invoice.json.billing_info.total_advance_payment) {
                                            return toLocaleNumberFormat(invoice.json.billing_info.total_advance_payment)
                                        }
                                        return toLocaleNumberFormat("", true);
                                    }
                                }

                                Rectangle {
                                    // Separates the grand total from the figures above, which all
                                    // looked alike. Accent coloured and thicker than the rules of
                                    // the form: this one is not structure, it belongs to the
                                    // total below it.
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4 * Stylesheet.pixelScaleRatio
                                    Layout.preferredHeight: 2 * Stylesheet.pixelScaleRatio
                                    color: Stylesheet.accentColor
                                }

                                StyledLabel {
                                    Layout.fillWidth: true
                                    font: Stylesheet.totalFont
                                    color: Stylesheet.accentColor
                                    text: qsTr("Total") +
                                          (invoice.signalInvoiceChanged && invoice.json && invoice.json.document_info.currency ?
                                               " " + invoice.json.document_info.currency.toLocaleUpperCase() : "")
                                }

                                StyledTextField {
                                    id: total_amount
                                    readOnly: true
                                    borderless: true
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 110 * Stylesheet.pixelScaleRatio
                                    text: toLocaleNumberFormat(invoice.json ? invoice.json.billing_info.total_to_pay : "", true)
                                    // The figure the whole document is about: same emphasis as the
                                    // total shown in the bar at the top of the window.
                                    font: Stylesheet.totalFont
                                    color: Stylesheet.accentColor
                                }
                            }
                        }
                        ColumnLayout { // How the total breaks down, in words
                            // Under the totals and aligned with them, because that is what they
                            // explain. Full sentences, so they take the width of the page and wrap.
                            Layout.fillWidth: true
                            spacing: Stylesheet.spacingTight

                            StyledLabel {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.WordWrap
                                visible: !isVatModeVatNone && text.length > 0

                                // Figures, not the name of a field: read at full strength, like
                                // the accounting details below it.
                                color: Stylesheet.textColor
                                text: invoice.json && invoice.json.billing_info.total_vat_rates ? getVatDetails() : ""

                                function getVatDetails() {
                                    var vatDetails = "";
                                    var totalVatRatesLength = invoice.json.billing_info.total_vat_rates.length;
                                    for (var i = 0; i < totalVatRatesLength; i++) {
                                        var vatRatesObj = invoice.json.billing_info.total_vat_rates[i];
                                        var vatText = getVatRateDetails(vatRatesObj);
                                        if (vatDetails.length > 0)
                                            vatDetails += "\n";
                                        vatDetails += vatText;
                                    }
                                    if (invoice.json.billing_info.total_vat_rate_zero &&
                                            invoice.json.billing_info.total_vat_rate_zero.total_amount_vat_exclusive) {
                                        if (vatDetails.length > 0)
                                            vatDetails += "\n";
                                        vatDetails += getVatRateDetails(invoice.json.billing_info.total_vat_rate_zero);
                                            }
                                    return vatDetails;
                                }

                                function getVatRateDetails(vatRateObj) {
                                    var vatText = qsTr("VAT %1% %4 %2 (%4 %3)");
                                    vatText = vatText.replace("%1", vatRateObj["vat_rate"] ? vatRateObj["vat_rate"] : "0");
                                    vatText = vatText.replace("%2", Banana.Converter.toLocaleNumberFormat(vatRateObj["total_vat_amount"], invoice.json.document_info.decimals_amounts, true));
                                    vatText = vatText.replace("%3", Banana.Converter.toLocaleNumberFormat(vatRateObj["total_amount_vat_exclusive"], invoice.json.document_info.decimals_amounts, true));
                                    vatText = vatText.replace(/%4/g, (invoice.signalInvoiceChanged && invoice.json.document_info.currency ?
                                                                          invoice.json.document_info.currency.toUpperCase() : ""));
                                    return vatText;
                                }
                            }

                            Text { // Accounting details
                                id: accounting_details

                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.WordWrap

                                color: Stylesheet.textColor
                                text: invoice.json ? getAccountingDetails() : ""
                                visible: text.length > 0

                                function getAccountingDetails() {
                                    var accDetails = ""
                                    if (invoice.json && invoice.json.accounting_info) {
                                        if (invoice.signalInvoiceChanged && invoice.json.document_info.currency !== appAccountingSettings.value("base_currency", "CHF")) {
                                            // Accounting amount 1'200 EUR (1 EUR / 1.2 CHF)
                                            var amount_acc_currency = Banana.Converter.toLocaleNumberFormat(invoice.json.accounting_info.amount)
                                            var multiplier = invoice.json.accounting_info.multiplier ? invoice.json.accounting_info.multiplier : "1.00"
                                            var exchangeRate = Banana.Converter.toLocaleNumberFormat(invoice.json.accounting_info.exchange_rate, 4)
                                            accDetails = "Base currency total %1 %2 (%3 %4 / %5 %6)".arg(amount_acc_currency).arg(invoice.json.accounting_info.currency)
                                            if (Banana.SDecimal.sign(multiplier) >= 0) {
                                                if (Banana.SDecimal.compare(multiplier, "1") === 0)
                                                    multiplier = "1"
                                                accDetails = accDetails.arg(multiplier).arg(invoice.json.document_info.currency)
                                                accDetails = accDetails.arg(exchangeRate).arg(invoice.json.accounting_info.currency)
                                            } else {
                                                multiplier = Banana.SDecimal.invert(multiplier)
                                                if (Banana.SDecimal.compare(multiplier, "1") === 0)
                                                    multiplier = "1"
                                                accDetails = accDetails.arg(exchangeRate).arg(invoice.json.document_info.currency)
                                                accDetails = accDetails.arg(multiplier).arg(invoice.json.accounting_info.currency)
                                            }
                                        }
                                    }
                                    return accDetails
                                }

                                function update() {
                                    text = getAccountingDetails()
                                }
                            }
                        }
                    }
                }

                StyledCard {
                    /* Printed after the totals, and so placed after them: the companion of the opening
                       text above the table, kept apart from it because that is how they are printed. */
                    title: qsTr("End text")
                    Layout.fillWidth: true

                    StyledTextArea {
                        id: ivoice_notes
                        filled: true
                        Layout.fillWidth: true
                        readOnly: invoice.isReadOnly
                        text: invoice.json && invoice.json.note && invoice.json.note[0] &&
                              invoice.json.note[0].description ? invoice.json.note[0].description : ""

                        onEditingFinished: {
                            if (modified) {
                                var noteObj = {
                                    'date': null,
                                    'description': text
                                }
                                invoice.json.note = [noteObj]
                                setDocumentModified()
                            }
                        }

                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: invoice_internal_notes
                    }
                }

                StyledCard {
                    /* The only field of this dialog that never reaches the document: notes to self,
                       kept in the file. Said in the title, since there is nowhere else to learn it,
                       and folded away because hardly any document has any. */
                    title: qsTr("Internal notes (not printed)")
                    Layout.fillWidth: true
                    collapsible: true
                    // Opens by itself on a document that has notes, like the other folded
                    // groups of the form.
                    expanded: invoice.signalInvoiceChanged && invoice.json ?
                                  Boolean(invoice.json.internalNote) : false

                    StyledTextArea {
                        id: invoice_internal_notes
                        filled: true
                        Layout.minimumHeight: 60 * Stylesheet.pixelScaleRatio
                        Layout.fillWidth: true
                        text: invoice.json && invoice.json.internalNote ? invoice.json.internalNote : ""
                        readOnly: invoice.isReadOnly
                        onEditingFinished: {
                            if (modified) {
                                invoice.json.internalNote = text
                                setDocumentModified()
                            }
                        }
                    }
                }

            }
        }
    }

    // Dialogs

    NotificationPopUp {
        id: notificationPopUp
        visible: false
    }

    SimpleMessageDialog { // Error message dialog
        id: errorMessageDialog
        visible: false
    }

    DlgLincense {
        id: dlgLicense
        visible: false
    }

    DlgNewContact {
        id: dlgNewContact
        visible: false
        centered: window.compactLayout

        onContactConfirmed: function(contactId) {
            if (!invoice.json || !invoice.json.customer_info)
                return

            let customerInfo = invoice.json.customer_info
            let documentInfo = invoice.json.document_info

            let fields = Contacts.contactRowFieldsGet(
                    contactId, customerInfo,
                    documentInfo ? documentInfo.locale : "",
                    documentInfo ? documentInfo.currency : "")

            if (!invoice.addContact(fields))
                return

            // Kept here as well, because the Contacts table does not hold it yet.
            createdContacts[contactId] = JSON.parse(JSON.stringify(customerInfo))

            invoice.json.customer_info.number = contactId

            // Shown in the selector straight away: its list is read from the Contacts
            // table, which this contact will only reach when the dialog is closed.
            customerAddressesModel.append({
                'key': contactId,
                'descr': Contacts.contactBriefDescriptionFromCustomerInfo(contactId, customerInfo),
                'search': ''
            })
            address_customer_selector.setCurrentKey(contactId)

            setDocumentModified()
            notify(qsTr("Contact created"))
        }
    }

    // Document methods
    function isWithoutVat() {
        if (invoice.json && invoice.json.document_info.vat_mode === "vat_none") {
            return true
        }
        return false
    }

    function arePricesVatExclusive() {
        if (invoice.json && invoice.json.document_info.vat_mode === "vat_excl") {
            return true
        }
        return false
    }

    function getRoundingDecimals() {
        if (invoice.json && invoice.json.document_info.decimals_amounts !== null) {
            if (invoice.json.document_info.decimals_amounts >= 0) {
                return invoice.json.document_info.decimals_amounts
            }
        }
        return Banana.document.rounding.decimals
    }

    function setDocumentLocale(lang) {
        if (lang) {
            let curLang = invoice.json.document_info.locale;
            if (curLang !== lang) {
                // Update document title if not modified
                let docNr = invoice.json.document_info.number;
                let defaultTitle = Invoice.invoiceGetTitle(invoice.isEstimate(), docNr, curLang);
                if (defaultTitle === invoice.json.document_info.description) {
                    // Update document title
                    let newDescription = Invoice.invoiceGetTitle(invoice.isEstimate(), docNr, lang);
                    invoice_description.text = newDescription;
                    invoice.json.document_info.description = newDescription;
                }
            }
            invoice.json.document_info.locale = lang;
            invoiceUpdateCustomFields();
            setDocumentModified()
        }
    }

    function setDocumentCurrency(currency) {
        let defaultCurrency = appSettings.data.new_documents.currency
        if (currency) {
            let curCurrency = invoice.json.document_info.currency
            if (curCurrency !== currency) {
                // Update currency
                invoice.json.document_info.currency = currency
            }
            setDocumentModified()
        } else {
            invoice.json.document_info.currency = defaultCurrency
            setDocumentModified()
        }
    }

    /* The discount agreed with the customer, taken from the contact when the customer is
       chosen, like the currency and the payment term above. An empty or zero discount leaves
       the document as it is: changing customer must not throw away a discount typed by hand.

       Written where the Discount field of the totals writes, so that typing there afterwards
       simply replaces it. */
    function setDocumentDiscountPercentage(percentage) {

        // Used as it comes: a column of Contacts is read in the internal format, whatever was
        // typed into it and however the locale shows it, which is the format the discount is
        // stored in - see InvoiceDiscountPercentage in main.js, read the same way.
        if (!percentage || Banana.SDecimal.isZero(percentage))
            return

        if (!invoice.json.billing_info)
            invoice.json.billing_info = {}
        if (!invoice.json.billing_info.discount)
            invoice.json.billing_info.discount = {}

        // One of these keys at a time, as the Discount field does: which one is decided by
        // the VAT mode, and a leftover from another mode would be counted as well.
        delete invoice.json.billing_info.discount.percent
        delete invoice.json.billing_info.discount.percent_vat_inclusive
        delete invoice.json.billing_info.discount.percent_vat_exclusive
        delete invoice.json.billing_info.discount.amount
        delete invoice.json.billing_info.discount.amount_vat_inclusive
        delete invoice.json.billing_info.discount.amount_vat_exclusive

        if (!isVatModeVatInclusive)
            invoice.json.billing_info.discount.percent_vat_exclusive = percentage
        else
            invoice.json.billing_info.discount.percent_vat_inclusive = percentage

        setDocumentModified()
        calculateInvoice()
            }

    function setDocumentDueDate(paymentTermInDays) {
        let defaultPaymentTerm = appSettings.data.new_documents.payment_term_days;
        if (paymentTermInDays) {
            let curPaymentTermInDays = dateDiff(invoice.json.document_info.date, invoice.json.payment_info.due_date)
            if (curPaymentTermInDays !== Number(paymentTermInDays)) {
                // Update due date
                invoice.json.payment_info.due_date = dateAdd(invoice.json.document_info.date, paymentTermInDays)
                setDocumentModified()
            }
        } else {
            invoice.json.payment_info.due_date = dateAdd(invoice.json.document_info.date, defaultPaymentTerm)
            setDocumentModified()
        }
    }

    function setDocumentModified() {
        invoice.setIsModified(true)
    }

    function setAddressModified() {
        updateViewAddress()
        setDocumentModified()
    }

    function emptyInvoiceItem() {
        var invoiceItem = {
            "description": "",
            "item_type": "",
            "mesure_unit": "",
            "number": "",
            "quantity": "",
            "unit_price": {}
        };

        if (isVatModeVatInclusive) {
            invoiceItem.unit_price.amount_vat_inclusive = ""
            invoiceItem.unit_price.amount_vat_exclusive = null
        } else {
            invoiceItem.unit_price.amount_vat_inclusive = null
            invoiceItem.unit_price.amount_vat_exclusive = ""
        }
        return invoiceItem;
    }

    function invoiceItemToModelItem(invoiceItem, row) {
        var modelItem = {
            'row': row,
            'item_type' : "",
            'number': "",
            'date': "",
            'description' : "",
            'quantity' : "",
            'price' : "",
            'mesure_unit' : "",
            'discount' : "",
            'vat_rate' : "",
            'vat_code' : "",
            'total' : ""
        }

        if (invoiceItem) {
            // Don't let assign 'null' if not the table will not show any text afterwards
            modelItem.item_type = invoiceItem.item_type ? invoiceItem.item_type : ""
            modelItem.number = invoiceItem.number ? invoiceItem.number : ""
            modelItem.date = invoiceItem.date ? invoiceItem.date : ""
            modelItem.description = invoiceItem.description ? invoiceItem.description : ""
            modelItem.quantity = invoiceItem.quantity ? invoiceItem.quantity : ""
            modelItem.mesure_unit = invoiceItem.mesure_unit ? invoiceItem.mesure_unit : ""
            if (invoiceItem.unit_price) {
                if (isVatModeVatNone) {
                    modelItem.price = invoiceItem.unit_price.amount_vat_inclusive ? invoiceItem.unit_price.amount_vat_inclusive : ""
                    modelItem.total = invoiceItem.total_amount_vat_inclusive ? invoiceItem.total_amount_vat_inclusive : ""

                } else {
                    modelItem.vat_rate = invoiceItem.unit_price.vat_rate ? invoiceItem.unit_price.vat_rate : ""
                    modelItem.vat_code = invoiceItem.unit_price.vat_code ? invoiceItem.unit_price.vat_code : ""
                    if (isVatModeVatInclusive) {
                        if (invoiceItem.unit_price.amount_vat_inclusive)
                            modelItem.price = invoiceItem.unit_price.amount_vat_inclusive ? invoiceItem.unit_price.amount_vat_inclusive : ""
                        else
                            modelItem.price = invoiceItem.unit_price.calculated_amount_vat_inclusive ? invoiceItem.unit_price.calculated_amount_vat_inclusive : ""
                        modelItem.total = invoiceItem.total_amount_vat_inclusive ? invoiceItem.total_amount_vat_inclusive : ""
                    } else {
                        if (invoiceItem.unit_price.amount_vat_exclusive)
                            modelItem.price = invoiceItem.unit_price.amount_vat_exclusive ? invoiceItem.unit_price.amount_vat_exclusive : ""
                        else
                            modelItem.price = invoiceItem.unit_price.calculated_amount_vat_exclusive ? invoiceItem.unit_price.calculated_amount_vat_exclusive : ""
                        modelItem.total = invoiceItem.total_amount_vat_exclusive ? invoiceItem.total_amount_vat_exclusive : ""
                    }
                }

            } else {
                modelItem.vat_rate = ""
                modelItem.vat_code = ""
                modelItem.price = ""
                modelItem.total = ""
                modelItem.quantity = ""

            }

            if (invoiceItem.discount) {
                if (invoiceItem.discount.percent) {
                    modelItem.discount = invoiceItem.discount.percent + "%"
                } else if (invoiceItem.discount.amount) {
                    modelItem.discount = invoiceItem.discount.amount
                } else {
                    modelItem.discount = ""
                }
            } else {
                modelItem.discount = ""
            }

        }

        return modelItem
    }

    function addItemToInvoice(invoiceItem) {
        if (invoiceItem) {
            if (invoiceItemsTable.currentRow < 0) {
                invoice.json.items.push(invoiceItem)
            } else {
                invoice.json.items.splice(invoiceItemsTable.currentRow, 0, invoiceItem)
            }
            calculateInvoice()
            invoiceItemsTable.selection.clear()
            invoiceItemsTable.currentRow = insertPos
            invoiceItemsTable.selection.select(insertPos)
        }
    }

    // Address methods
    function addressToModelAddress(addressRow) {
        var invoiceAddress = {
            'number': addressRow.ContactId,
            'courtesy' : addressRow.ContactSalutation,
            'business_name' : addressRow.ContactOrganisation,
            'first_name' : addressRow.ContactFirstName,
            'last_name' : addressRow.ContactLastName,
            'address1' : addressRow.ContactAddress1,
            'building_number' : addressRow.ContactBuildingNumber,
            'address2' : addressRow.ContactAddress2,
            'address3' : addressRow.ContactAddress3,
            'postal_code' : addressRow.ContactPostalCode,
            'city' : addressRow.ContactCity,
            'country' : addressRow.ContactCountry,
            'vat_number' : addressRow.ContactVatNumber,
            'fiscal_number' : addressRow.ContactFiscalNumber,
            'phone' : addressRow.ContactPhone,
            'mobile' : addressRow.ContactMobile,
            'email' : addressRow.ContactEmail,
        }
        return invoiceAddress
    }


    // View methods

    function loadCustomerAddresses() {
        customerAddressesModel.clear()
        customerAddressesModel.append({'key': '','descr': ''})
        var contacts = Contacts.contactsAddressesGet()
        for (var i = 0; i < contacts.length; ++i) {
            customerAddressesModel.append(contacts[i])
        }
        }

    function loadItems() {
        itemsModel.clear();
        itemsModel.append({'key': '','descr': ''})
        var items = Items.itemsGet()
        for (var i = 0; i < items.length; ++i) {
            itemsModel.append(items[i]);
        }
        }

    function loadLanguages() {
        // Get default languages
        var languages = {
            'de' : {"englishName":  'German', "nativeName": 'Deutsch'},
            'en' : {"englishName":  'English', "nativeName": 'English'},
            'es' : {"englishName":  'Spanish', "nativeName": 'Español'},
            'fr' : {"englishName":  'French', "nativeName": 'Français'},
            'it' : {"englishName":  'Italian', "nativeName": 'Italiano'},
            'nl' : {"englishName":  'Dutch', "nativeName": 'Nederlands'},
            'pt' : {"englishName":  'Portuguese', "nativeName": 'Portuguese'},
            'ru' : {"englishName":  'Russian', "nativeName": 'Русский'},
            'zh' : {"englishName":  'Chinese', "nativeName": '简体中文'}
            }

        // Fill default languages with the customer languages
        let contactsLocales = contactsLocalesGet()
        let contactsLanguagesCodes = Object.keys(contactsLocales);
        for (let i = 0; i < contactsLanguagesCodes.length; ++i) {
            let langCode = contactsLanguagesCodes[i]
            if (!languages[langCode]) {
                languages[langCode] = contactsLocales[langCode]
            }
        }

        // Sort languages by code and fill the model
        let languagesCodes = Object.keys(languages).sort();
        for (let i = 0; i < languagesCodes.length; ++i) {
            let langCode = languagesCodes[i]
            let language = languages[langCode];
            languagesModel.append({key: langCode, descr: language.nativeName})
            }
    }

    function loadCurrencies() {
        // Get default currencies
        var currencies = {
            'CHF' : {"descr":  qsTr('Swiss Franc')},
            'EUR' : {"descr":  qsTr('Euro')},
            'USD' : {"descr":  qsTr('US Dollar')},
            }

        // Fill default currencies with the customer currencies
        /**
            let contactsCurrencies = contactsCurrenciesGet()
            let contactsLanguagesCodes = Object.keys(contactsCurrencies);
            for (let i = 0; i < contactsLanguagesCodes.length; ++i) {
                let currencyCode = contactsLanguagesCodes[i]
                if (!currencies[currencyCode]) {
                    currencies[currencyCode] = contactsCurrencies[currencyCode]
                }
            }
            */

        // Fill default currencies with the invoices currencies
        /**
            let invoicesCurrencies = invoicesCurrenciesGet()
            let invoicesLanguagesCodes = Object.keys(invoicesCurrencies);
            for (let i = 0; i < invoicesLanguagesCodes.length; ++i) {
                let currencyCode = contactsLanguagesCodes[i]
                if (!currencies[currencyCode]) {
                    currencies[currencyCode] = invoicesCurrencies[currencyCode]
                }
            }
            */

        // Sort languages by code and fill the model
        currenciesModel.clear()
        let currenciesAbbreviations = Object.keys(currencies).sort();
        for (let i = 0; i < currenciesAbbreviations.length; ++i) {
            let currencyCode = currenciesAbbreviations[i]
            currenciesModel.append({key: currencyCode, descr: currencies[currencyCode].descr})
            }
    }

    function loadTaxRates() {
        taxRatesModel.clear();
        taxRatesModel.append(
                    {
                        'key': "",
                        'descr' : "",
                        'rate': ""
                    })
        var vatCodes = VatCodes.vatCodesGet()
        for (var i = 0; i < vatCodes.length; ++i) {
            taxRatesModel.append(vatCodes[i]);
        }
    }

    function updateView() {
        updateViewAddress()
        updateViewVatMode()
        updateViewItems()
        invoiceItemsTable.updateColDescrWidth();
    }

    function updateViewAddress() {
        if (!invoice.json)
            return

        address_business_name.text = invoice.json ? invoice.json.customer_info.business_name : ""
        address_business_unit.text = invoice.json && invoice.json.customer_info.business_unit ? invoice.json.customer_info.business_unit : ""
        address_business_unit_2.text = invoice.json && invoice.json.customer_info.business_unit2 ? invoice.json.customer_info.business_unit2 : ""
        address_business_unit_3.text = invoice.json && invoice.json.customer_info.business_unit3 ? invoice.json.customer_info.business_unit3 : ""
        address_business_unit_4.text = invoice.json && invoice.json.customer_info.business_unit4 ? invoice.json.customer_info.business_unit4 : ""
        address_courtesy.text = invoice.json.customer_info.courtesy ? invoice.json.customer_info.courtesy : ""
        address_first_name.text = invoice.json.customer_info.first_name
        address_last_name.text = invoice.json.customer_info.last_name
        address_address1.text = invoice.json.customer_info.address1 ? invoice.json.customer_info.address1 : ""
        address_building_number.text = invoice.json.customer_info.building_number ? invoice.json.customer_info.building_number : ""
        address_address2.text = invoice.json.customer_info.address2 ? invoice.json.customer_info.address2 : ""
        address_address3.text = invoice.json.customer_info.address3 ? invoice.json.customer_info.address3 : ""
        address_postal_code.text = invoice.json.customer_info.postal_code
        address_city.text = invoice.json.customer_info.city
        address_country_code.text = invoice.json.customer_info.country_code
        address_phone.text = invoice.json.customer_info.phone ? invoice.json.customer_info.phone : ""
        address_email.text = invoice.json.customer_info.email ? invoice.json.customer_info.email : ""
        address_vat_number.text = invoice.json.customer_info.vat_number ? invoice.json.customer_info.vat_number : ""
        address_fiscal_number.text = invoice.json.customer_info.fiscal_number ? invoice.json.customer_info.fiscal_number : ""
    }

    function updateViewVatMode() {
        isVatModeVatNone = isWithoutVat();
        isVatModeVatInclusive = !arePricesVatExclusive()
    }

    /* Writes one cell of the items table model. TableModel.setData() takes (index, role, value)
       on Qt 6.8 and (index, value, role) from Qt 6.10, and the wrong order fails without a
       warning: edited cells went back to their previous value. New order first, then the old. */
    function setItemsModelDisplay(index, value) {
        if (!invoiceItemsModel.setData(index, value, "display"))
            invoiceItemsModel.setData(index, "display", value)
    }

    function updateViewItems() {
        var modelItem = null
        var modelIndex = 0;
        var jsonItemIndex = 0;

        // Aggiorna items esistenti
        for (modelIndex = 0, jsonItemIndex = 0; modelIndex < invoiceItemsModel.rowCount && jsonItemIndex < invoice.json.items.length; modelIndex++, jsonItemIndex++) {
            modelItem = invoiceItemToModelItem(invoice.json.items[jsonItemIndex], jsonItemIndex + 1)
            invoiceItemsModel.setRow(modelIndex, modelItem)
        }

        if (jsonItemIndex < invoice.json.items.length) {
            // Aggiungi nuovi items
            for (;jsonItemIndex < invoice.json.items.length; modelIndex++, jsonItemIndex++) {
                modelItem = invoiceItemToModelItem(invoice.json.items[jsonItemIndex], jsonItemIndex + 1)
                invoiceItemsModel.appendRow(modelItem)
            }
        } else if (invoiceItemsModel.rowCount > invoice.json.items.length) {
            // Rimuovi items cancellati
            invoiceItemsModel.removeRow(modelIndex, invoiceItemsModel.rowCount - invoice.json.items.length)
        }

        // Add new row
        let newRowItem = invoiceItemToModelItem(null, '*');
        invoiceItemsModel.appendRow(newRowItem)
    }

    function calculateInvoice() {
        if (invoice.calculate()) {
            updateView()
        } else {
            errorMessageDialog.text = invoice.errorString
            errorMessageDialog.visible = true
        }
    }

    function exportInvoice() {
        // ...
    }

    function setInvoiceCustomerAddress(invoice, address) {
        if (invoice && address) {
            if (!invoice.customer_info)
                invoice.customer_info = {}

            invoice.customer_info.number = address.number
            invoice.customer_info.courtesy = address.courtesy
            invoice.customer_info.business_name = address.business_name
            invoice.customer_info.first_name = address.first_name
            invoice.customer_info.last_name = address.last_name
            invoice.customer_info.address1 = address.address1
            invoice.customer_info.building_number = address.building_number
            invoice.customer_info.address2 = address.address2
            invoice.customer_info.address3 = address.address3
            invoice.customer_info.postal_code = address.postal_code
            invoice.customer_info.city = address.city
            invoice.customer_info.country_code = address.country_code
            invoice.customer_info.vat_number = address.vat_number
            invoice.customer_info.fiscal_number = address.fiscal_number
            invoice.customer_info.phone = address.phone
            invoice.customer_info.mobile = address.mobile
            invoice.customer_info.email = address.email
                }
    }

    function setInvoiceShippingAddress(invoice, address) {
        if (invoice && address) {
            if (!invoice.shipping_info)
                invoice.shipping_info = {}

            invoice.shipping_info.courtesy = address.courtesy
            invoice.shipping_info.business_name = address.business_name
            invoice.shipping_info.first_name = address.first_name
            invoice.shipping_info.last_name = address.last_name
            invoice.shipping_info.address1 = address.address1
            invoice.shipping_info.building_number = address.building_number
            invoice.shipping_info.address2 = address.address2
            invoice.shipping_info.address3 = address.address3
            invoice.shipping_info.postal_code = address.postal_code
            invoice.shipping_info.city = address.city
            invoice.shipping_info.country_code = address.country_code
            invoice.shipping_info.phone = address.phone
            invoice.shipping_info.mobile = address.mobile
            invoice.shipping_info.email = address.email
                }
    }

    function invoiceCompleteMissingFields(invoice) {
        if (!invoice)
            invoice = {}

        invoice.version = "1.0"

        if (!invoice.document_info)
            invoice.document_info = {}
        if (!invoice.document_info.decimals_amounts)
            invoice.document_info.decimals_amounts = 2
        if (!invoice.document_info.rounding_total)
            invoice.document_info.rounding_total = "0.05"

        if (!invoice.customer_info)
            invoice.customer_info = {}
        if (!invoice.customer_info.address)
            invoice.customer_info.address = {}

        if (!invoice.shipping_info)
            invoice.shipping_info = {}
        if (!invoice.shipping_info.address) {
            invoice.shipping_info.different_shipping_address = false
            invoice.shipping_info.address = {}
            }

        if (!invoice.items)
            invoice.items = []
            }

    function invoiceUpdateCustomFields() {

        // Read form custom fields
        let language = invoice && invoice.json && invoice.json.document_info && invoice.json.document_info.locale ?
                invoice.json.document_info.locale.substring(0,2) : Banana.document.locale.substring(0,2);
        let custom_fields = []
        if (invoice_custom_field_1.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_1.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_1.customFieldId, language),
                                   "value": invoice_custom_field_1.text
                               });
        }
        if (invoice_custom_field_2.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_2.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_2.customFieldId, language),
                                   "value": invoice_custom_field_2.text
                               });
        }
        if (invoice_custom_field_3.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_3.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_3.customFieldId, language),
                                   "value": invoice_custom_field_3.text
                               });
        }
        if (invoice_custom_field_4.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_4.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_4.customFieldId, language),
                                   "value": invoice_custom_field_4.text
                               });
        }
        if (invoice_custom_field_5.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_5.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_5.customFieldId, language),
                                   "value": invoice_custom_field_5.text
                               });
        }
        if (invoice_custom_field_6.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_6.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_6.customFieldId, language),
                                   "value": invoice_custom_field_6.text
                               });
        }
        if (invoice_custom_field_7.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_7.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_7.customFieldId, language),
                                   "value": invoice_custom_field_7.text
                               });
        }
        if (invoice_custom_field_8.text) {
            custom_fields.push({
                                   'id': invoice_custom_field_8.customFieldId,
                                   "title": Settings.getTranslatedText(appSettings.data, "invoice_" + invoice_custom_field_8.customFieldId, language),
                                   "value": invoice_custom_field_8.text
                               });
        }

        // Keeps custom fields not present in the form
        if (invoice.json.document_info.custom_fields) {
            let implFields = [
                    'invoice_custom_field_1',
                    'invoice_custom_field_2',
                    'invoice_custom_field_3',
                    'invoice_custom_field_4',
                    'custom_field_1',
                    'custom_field_2',
                    'custom_field_3',
                    'custom_field_4',
                    'custom_field_5',
                    'custom_field_6',
                    'custom_field_7',
                    'custom_field_8',
                ]
            for (let i = 0; i < invoice.json.document_info.custom_fields; ++i) {
                if (implFields.indexOf(invoice.json.document_info.custom_fields[i].id) === -1) {
                    custom_fields.push(invoice.json.document_info.custom_fields[i]);
                }
            }
        }

        invoice.json.document_info.custom_fields = custom_fields;
    }

    // Convertion functions

    /**
         * Return the number of decimals.
         */
    function getDecimalsCount(value) {
        if (value) {
            var separatorPos = value.indexOf('.')
            if (separatorPos > -1) {
                return value.length - separatorPos - 1
            }
        }
        return 0
    }

    function isLocaleZero(value) {
        if (!value)
            return true
        return Banana.SDecimal.isZero(Banana.Converter.toInternalNumberFormat(value))
    }

    function parseDiscountFormat(value) {
        let result = {
            'isZero': true,
            'isPercentage': false,
            'value': null
        }

        if (value.indexOf('%') >= 0) {
            result.isPercentage = true
            let perc = Banana.Converter.toInternalNumberFormat(value.substring(0, value.indexOf('%')))
            if (!Banana.SDecimal.isZero(perc)) {
                result.isZero = false
                result.value = perc
            }
        } else {
            result.isPercentage = false
            let amount = Banana.Converter.toInternalNumberFormat(value)
            if (!Banana.SDecimal.isZero(amount)) {
                result.isZero = false
                result.value = amount
            }
        }

        return result
    }

    function toLocaleNumberFormat(value, convZeroValues) {
        return Banana.Converter.toLocaleNumberFormat(value, getRoundingDecimals(), convZeroValues)
    }

    function toLocaleItemNumberFormat(value) {
        let dec = getDecimalsCount(value);
        return Banana.Converter.toLocaleNumberFormat(value, dec, false)
    }

    function toLocaleItemDiscountFormat(value) {
        if (value.indexOf('%') >= 0) {
            let perc = value.substring(0, value.indexOf('%'))
            if (!perc || perc.trim().length === 0)
                return ""
            let dec = getDecimalsCount(perc);
            return Banana.Converter.toLocaleNumberFormat(perc, dec, true) + "%"

        } else {
            if (!value || value.trim().length === 0)
                return ""
            let dec = getDecimalsCount(value);
            return Banana.Converter.toLocaleNumberFormat(value, dec, false)
        }
    }

    function toLocaleItemTotalFormat(value, row) {
        let convIfZero = false
        if (invoiceItemsModel && invoiceItemsModel.rowCount > row && row >= 0) {
            convIfZero = invoiceItemsModel.getRow(row).price && invoiceItemsModel.getRow(row).price.length > 0
        }
        return Banana.Converter.toLocaleNumberFormat(value, getRoundingDecimals(), convIfZero);
    }

    /* This method convert an iso date/time string to the local date/time format */
    function toLocaleDateTimeFormat(value) {
        if (!value || !value.length)
            return value

        var datetimeParts = value.split('T');
        if (datetimeParts.length === 2) {
            return Banana.Converter.toLocaleDateFormat(datetimeParts[0]) + " " +
                    Banana.Converter.toLocaleTimeFormat(datetimeParts[1])
        }
        return Banana.Converter.toLocaleDateFormat(datetimeParts[0])
    }

    /* This method convert a local amount to the interal amount format */
    function toInternalNumberFormat(value) {
        if (!value)
            return ""
        let retValue = Banana.Converter.toInternalNumberFormat(value)
        if (Banana.SDecimal.isZero(retValue))
            return ""
        var dec = getRoundingDecimals()
        retValue = Banana.SDecimal.round(retValue, {'decimals': dec})
        return retValue
        }

    /* This method convert a local amount to the interal amount format */
    function toInternalItemNumberFormat(value) {
        if (!value)
            return ""
        var amount = Banana.Converter.toInternalNumberFormat(value)
        if (Banana.SDecimal.isZero(amount))
            return ""
        if (getDecimalsCount(amount) < getRoundingDecimals()) {
            amount = Banana.SDecimal.round(amount, {'decimals': getRoundingDecimals()})
            }
        return amount
    }

    /* This method convert a local date/time string to the iso format */
    function toInternalDateTimeFormat(value) {
        if (!value || !value.length)
            return value;

        var datetimeParts = value.trim().split(' ');
        if (datetimeParts.length === 2) {
            return Banana.Converter.toInternalDateFormat(datetimeParts[0]) + "T" +
                    Banana.Converter.toInternalTimeFormat(datetimeParts[1])
        }
        return Banana.Converter.toInternalDateFormat(datetimeParts[0]);
    }

    function showHelp() {
        Banana.Ui.showHelp("dlginvoiceedit");
    }

    // Appearance methods

    /* There is no longer a field that the form hides: every one of them is shown, folded
       into its group at worst, so there is nothing left to ask about. What is still read
       from the appearance settings is the width of the items table's columns, below. */

    function saveInvoiceItemColumnWidth(columnId, width) {
        let viewAppearance = appSettings.data.interface.invoice.views[currentView].appearance
        viewAppearance[columnId] = width
    }

    }
