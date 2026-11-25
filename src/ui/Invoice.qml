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

import "../base/invoice.js" as Invoice

QtObject {
    // Constants
    readonly property int type_invoice: 0
    readonly property int type_estimate: 1

    // Properties
    property var json: null
    property int type: type_invoice
    property var tabPos: null

    property bool isModified: false
    property bool isNewDocument: false
    property bool isReadOnly: false

    property bool error: false
    property string errorString: ""

    // Private properties
    property var docChange: null

    /* Which operation was added to the DocumentChange last: its kind and the row it was for.
       Saving the same document twice - printing it, then saving it - must replace that
       operation rather than add a second one, which for a new document would add its row to
       the table twice. It is compared by row and not by a flag, because the dialog can now
       walk from one document to another and save more than one of them: a flag said only
       "something was added", and the second document's save then dropped the first
       document's operation. */
    property string docChangeLastOperationKey: ""

    /* Tells one new document from the next. A document that is not a row of the table yet has
       no row number to be known by - every one of them sits at the end of the table - so
       without this the save of a second new document would be taken for the save of the
       first one and would replace its operation. Bumped by beginNewDocument(). */
    property int newDocumentSerial: 0

    // Signals
    signal invoiceChanged()
    signal invoiceSaved()
    signal documentDeleted()

    property int signalInvoiceChanged: 1

    // Methods

    function calculate() {
        clearError()
        Invoice.invoiceUpdateCreatorInfo(json)
        Invoice.invoiceUpdateSupplierInfo(json)

        // Calculate
        var jsonData = JSON.stringify(json)
        jsonData = Banana.document.calculateInvoice(jsonData)
        if (jsonData && jsonData.length) {
            try {
                // Update json
                json = JSON.parse(jsonData)
                setIsModified(true)
                return true
            } catch(err) {
                error = true
                errorString = err.message
            }
        }
        return false
    }

    function clearError() {
        error = false
        errorString = null
    }

    function isEstimate() {
        return type === type_estimate;
    }

    function save() {
        Invoice.invoiceUpdateCreatorInfo(invoice.json);
        Invoice.invoiceUpdateSupplierInfo(invoice.json)

        var invoiceRow = invoiceRowGet(invoice.tabPos)
        var changedRowFields = invoiceChangedFieldsGet(invoice.json, invoiceRow)
        var invoiceDataField = invoiceUpdatedInvoiceDataFieldGet(invoice.tabPos, invoice.json)
        changedRowFields["InvoiceData"] = invoiceDataField

        // What this save is about to add. Only an operation of the very same kind, for the
        // very same document, may be replaced - see docChangeLastOperationKey. A new
        // document is told apart by its serial and not by its row, which it does not have
        // yet - see newDocumentSerial.
        var operationKey = (invoiceRow ? "modify" : "add|" + newDocumentSerial) + "|" +
                invoice.tabPos.tableName + "|" +
                (invoice.tabPos.listName ? invoice.tabPos.listName : "") + "|" +
                invoice.tabPos.rowNr

        if (invoiceRow) {
            // existing invoice / estimate
            if (docChangeLastOperationKey === operationKey)
                invoice.docChange.removeLastOperation()

            docChange.addOperationRowModify(
                        invoice.tabPos.tableName,
                        invoice.tabPos.rowNr,
                        changedRowFields);
        } else {
            // new invoice / estimate
            if (docChangeLastOperationKey === operationKey)
                docChange.removeLastOperation();

            docChange.addOperationRowAdd(tabPos.tableName, changedRowFields);
            docChange.setOperationCursorMove(
                        tabPos.tableName,
                        invoice.tabPos.rowNr,
                        "RowId");
        }

        docChangeLastOperationKey = operationKey

        setIsModified(false)
        invoiceSaved()
    }

    /* Called before a document that is not in the table yet is put on screen - a new one, a
       copy, an invoice created from an estimate - so that its save cannot be mistaken for
       the save of the previous one. See newDocumentSerial. */
    function beginNewDocument() {
        newDocumentSerial++
    }

    /* Marks the open document for deletion. Like a save, this only writes an operation into
       the DocumentChange: the row leaves the table when Banana applies it, once the dialog
       is closed. Returns false when there is no row to delete, which is the case for a
       document that has not been saved yet.

       Any change still being held for this document is dropped: it would be written to a
       row that is about to go, and the operations of a document are applied before the
       deletions are. */
    function deleteDocument() {
        if (!docChange || !tabPos)
            return false

        var invoiceRow = invoiceRowGet(tabPos)
        if (!invoiceRow)
            return false

        var operationKey = "delete|" + tabPos.tableName + "|" +
                (tabPos.listName ? tabPos.listName : "") + "|" + tabPos.rowNr

        // Deleting twice would mark the same row twice, and the second sequence would be
        // refused as a row that no longer exists.
        if (docChangeLastOperationKey === operationKey)
            return true

        docChange.addOperationRowDelete(tabPos.tableName, tabPos.rowNr)
        docChangeLastOperationKey = operationKey

        setIsModified(false)
        documentDeleted()
        return true
    }

    /* Adds a row to the Contacts table, so that the address typed into a document can be
       kept as a contact without leaving the dialog. The fields are built by
       contactRowFieldsGet in contacts.js.

       The key of the last operation is cleared afterwards: this row belongs to another
       table and must never be the one a following save replaces. */
    function addContact(fields) {
        if (!docChange || !fields)
            return false

        docChange.addOperationRowAdd("Contacts", fields)
        docChangeLastOperationKey = ""
        return true
    }

    function setIsNew(newDocument) {
        isNewDocument = newDocument
    }

    function setIsModified(modified) {
        isModified = modified
        invoiceChanged()
        signalInvoiceChanged++
    }

    function setIsEstimate(estimate) {
        if (estimate) {
            type = type_estimate
        } else {
            type = type_invoice
        }
    }

    function setDocumentChange(doc) {
        docChange = doc
    }

    function setInvoice(invoice) {
        json = invoice
        invoiceChanged()
        signalInvoiceChanged++
    }

    function setPosition(pos) {
        tabPos = pos
    }

    function setType(tp) {
        type = tp
    }

    function setVatMode(vatMode) {

        if (json && json.document_info.vat_mode !== vatMode) {
            // We will copy the unit price to the new mode (inclusive or excluve mwst)
            // The unit price will not change, but the invoice total with recalculated
            // if not the unit price is changed and from the experience this is not user friendly
            if (vatMode === "vat_excl") {
                // Copy displayed unit price to item unit price vat exlusive
                if (json.document_info.vat_mode !== "vat_excl") {
                    for (var i = 0; i < json.items.length; ++i) {
                        if (json.items[i].unit_price.amount_vat_inclusive) {
                            json.items[i].unit_price.amount_vat_exclusive = json.items[i].unit_price.amount_vat_inclusive;
                        } else if (json.items[i].unit_price.calculated_amount_vat_inclusive) {
                            json.items[i].unit_price.amount_vat_exclusive = json.items[i].unit_price.calculated_amount_vat_inclusive;
                        }

                        if (json.items[i].unit_price._vat_code) {
                            json.items[i].unit_price.vat_code = json.items[i].unit_price._vat_code
                        }
                        if (json.items[i].unit_price._vat_rate) {
                            json.items[i].unit_price.vat_rate = json.items[i].unit_price._vat_rate
                        }

                        json.items[i].unit_price.amount_vat_inclusive = null;
                        json.items[i].unit_price._vat_code = null
                        json.items[i].unit_price._vat_rate = null
                    }
                } else { // json.document_info.vat_mode === "vat_excl"
                    for (var i = 0; i < json.items.length; ++i) {
                        if (json.items[i].unit_price.amount_vat_exclusive) {
                            // Nothing to do
                        } else if (json.items[i].unit_price.calculated_amount_vat_exclusive) {
                            json.items[i].unit_price.amount_vat_exclusive = json.items[i].unit_price.calculated_amount_vat_exclusive;
                        }
                        json.items[i].unit_price.amount_vat_inclusive = null;
                     }
                }
            } else { // vatMode === "vat_none" | "vat_incl"
                // Copy displayed unit price to item unit price vat inclusive
                if (json.document_info.vat_mode === "vat_excl") {
                    // Copy unit price vat exclusive to vat inclusive
                    for (var i = 0; i < json.items.length; ++i) {
                        if (json.items[i].unit_price.amount_vat_exclusive) {
                            json.items[i].unit_price.amount_vat_inclusive = json.items[i].unit_price.amount_vat_exclusive;
                        } else if (json.items[i].unit_price.calculated_amount_vat_exclusive) {
                            json.items[i].unit_price.amount_vat_inclusive = json.items[i].unit_price.calculated_amount_vat_exclusive;
                        }
                        json.items[i].unit_price.amount_vat_exclusive = null;
                        if (vatMode === "vat_none") {
                            if (json.items[i].unit_price.vat_code) {
                                json.items[i].unit_price._vat_code = json.items[i].unit_price.vat_code
                            }
                            if (json.items[i].unit_price.vat_rate) {
                                json.items[i].unit_price._vat_rate = json.items[i].unit_price.vat_rate
                            }
                            json.items[i].unit_price.vat_code = null
                            json.items[i].unit_price.vat_rate = null
                        } else {
                            if (json.items[i].unit_price._vat_code) {
                                json.items[i].unit_price.vat_code = json.items[i].unit_price._vat_code
                            }
                            if (json.items[i].unit_price._vat_rate) {
                                json.items[i].unit_price.vat_rate = json.items[i].unit_price._vat_rate
                            }
                            json.items[i].unit_price._vat_code = null
                            json.items[i].unit_price._vat_rate = null
                        }

                    }
                } else { // json.document_info.vat_mode === "vat_none" | "vat_incl"
                     for (var i = 0; i < json.items.length; ++i) {
                        if (json.items[i].unit_price.amount_vat_inclusive) {
                            // Nothing to do
                        } else if (json.items[i].unit_price.calculated_amount_vat_inclusive) {
                            json.items[i].unit_price.amount_vat_inclusive = json.items[i].unit_price.calculated_amount_vat_inclusive;
                        }
                        json.items[i].unit_price.amount_vat_exclusive = null;
                        if (vatMode === "vat_none") {
                            if (json.items[i].unit_price.vat_code) {
                                json.items[i].unit_price._vat_code = json.items[i].unit_price.vat_code
                            }
                            if (json.items[i].unit_price.vat_rate) {
                                json.items[i].unit_price._vat_rate = json.items[i].unit_price.vat_rate
                            }
                            json.items[i].unit_price.vat_code = null
                            json.items[i].unit_price.vat_rate = null
                        } else {
                            if (json.items[i].unit_price._vat_code) {
                                json.items[i].unit_price.vat_code = json.items[i].unit_price._vat_code
                            }
                            if (json.items[i].unit_price._vat_rate) {
                                json.items[i].unit_price.vat_rate = json.items[i].unit_price._vat_rate
                            }
                            json.items[i].unit_price._vat_code = null
                            json.items[i].unit_price._vat_rate = null
                        }
                     }
                }
            }
            json.document_info.vat_mode = vatMode;
            setIsModified(true);
        }
    }

}
