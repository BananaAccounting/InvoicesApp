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

// @id = ch.banana.application.invoice.default
// @api = 1.0
// @pubdate = 2024-02-01
// @publisher = Banana.ch SA
// @description = Estimates and Invoices extension
// @doctype = *
// @task = application.invoice

// @includejs = base/utils.js
// @includejs = base/invoice.js
// @includejs = base/invoices.js
// @includejs = base/contacts.js
// @includejs = base/documentchange.js
// @includejs = base/settings.js

var JsAction = class JsAction {

    constructor() {
        this.version = '1.0';
        // Create a new version when changes to the InvoiceApp are no more compatible
        // with a previous version of Banana that use an older version of QT
        //
        // When you have to create a new version follow this steps:
        // - create a new directory under ui example QTXX
        // - copy the files under UI and the components directory under QTXX
        // - Open with an editor the ch.banana.application.invoice.default.qrc
        //   create the entries for the new files, by copying the existing one
        //   and add the /QTXX at the begin of the file name
        // - Go through alla new files and change when you find the include
        //   from import "../base/.." "../../base/.."
        this.getUiFileName = function () {
            if (Banana.application.qtVersion &&
                Banana.compareVersion(Banana.application.qtVersion, "6.5.0") > 0) {
                return 'ui/DlgInvoice.qml';
            } else if (Banana.application.qtVersion &&
                       Banana.compareVersion(Banana.application.qtVersion, "6.4.0") > 0){
                // Qt 6.5 has introduced changes to the TableView
                // The existing QML create scroll problems
                // The fix require the use of a function onLayoutCompleted() that did not exists
                // on Qt 6.4
                // So it has been necessary to maintain a separate verion that works with
                // Banana version 10.8 that use Qt 6.4
                // We have used for qt6-4 the realease tagged R230725
                // It does not contains the ItemType (Total)
                // So total are not backwards compatible.
                return 'ui/qt6-4/DlgInvoice.qml';
            }else {
                console.log("QT5")
                return 'ui/qt5/DlgInvoice.qml';
            }
        }
    }

    // API JsBanAction

    /**
     * This method is used to create a new invoice or estimate.
     * It returns the json of the created invoice or estimate.
     */
    create(tabPos, id) {
        return JSON.stringify(invoiceCreateNew(tabPos, id));
    }

    /**
     * This method is used to update the row after the object is changed.
     * It return a json patch document to be applied, null if no changes, or an Error object.
     */
    updateRow(tabPos) {
        var row = null;
        var table = Banana.document.table(tabPos.tableName);
        if (tabPos.rowNr < table.rowCount) {
            row = table.row(tabPos.rowNr);
        }

        var invoiceObj = null;
        var changedRowFields = null;
        var docChange = null;
        if (tabPos.tableName === "Invoices" || tabPos.tableName === "Estimates") {
            if (tabPos.columnName === "RowId") {
                changedRowFields = {};
                var rowId = row.value("RowId");
                invoiceObj = invoiceObjGet(tabPos);

                if (tabPos.changeSource === "edit_paste" && !invoiceObj) {

                    // If InvoiceData is empty and another invoice with the same number exists
                    // copy the InvoiceData too.
                    var rowIdIs = function (rowObj, rowNr, table) {
                        return rowObj.value('RowId') === rowId && rowObj.rowNr !== tabPos.rowNr;
                    }
                    var rows = table.findRows(rowIdIs);
                    if (rows.length > 0) {
                        let isEstimate = tabPos.tableName === "Estimates" || tabPos.parentTableName === "Estimates";
                        var newRowId = invoiceGetNextNumber(isEstimate);
                        try {
                            var invoiceFieldObj = JSON.parse(rows[0].value("InvoiceData"));
                            invoiceObj = JSON.parse(invoiceFieldObj.invoice_json);
                            invoiceObj.document_info.number = newRowId;
                            changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                            changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                        }
                        catch (e) {
                            // Continue
                        }

                        if (!invoiceObj) {
                            invoiceObj = invoiceCreateNew(tabPos);
                            invoiceObj.document_info.number = newRowId;
                            changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                            changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                        }
                    }

                } else {
                    // Update invoice
                    invoiceObj = invoiceObjGet(tabPos);
                    if (!invoiceObj) {
                        invoiceObj = invoiceCreateNew(tabPos, rowId);
                    } else {
                        invoiceObj.document_info.number = rowId;
                    }
                    changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);

                }

                // Create docChange
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceDate") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);

                // Adjust expiration date (keep days differences between invoice date and due date)
                invoiceSetDate(invoiceObj, row.value("InvoiceDate"));

                // Create docChange
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceDateExpiration") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.payment_info.due_date = row.value("InvoiceDateExpiration");

                // Create docChange
                changedRowFields = {};
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "ContactsId") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);

                var customer_id = table.value(tabPos.rowNr, "ContactsId");
                invoiceObj.customer_info = contactAddressGet(customer_id);
                invoiceObj.document_info.locale = contactLocaleGet(customer_id);
                invoiceObj.document_info.currency = contactCurrencyGet(customer_id)
                invoiceObj.payment_info.due_date = dateAdd(invoiceObj.document_info.date, contactPaymentTermInDaysGet(customer_id))

                // Create docChange
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "Description") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.document_info.description = row.value("Description");

                // Create docChange
                changedRowFields = {};
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "Notes") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.note = [{
                                       'date': null,
                                       'description': row.value("Notes")
                                   }];

                // Create docChange
                changedRowFields = {};
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceDiscountPercentage") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.billing_info.discount = {
                    'amount': null,
                    'percent': row.value("InvoiceDiscountPercentage")
                }

                // Recalculate invoice
                invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));

                // Create docChange
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceDiscountAmount") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.billing_info.discount = {
                    'amount': row.value("InvoiceDiscountAmount"),
                    'percent': null
                }

                // Create docChange
                invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceData") {
                // Read invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);

                // Create docChange
                invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "InvoiceDatePayment") {
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.payment_info.payment_date = row.value("InvoiceDatePayment");

                // Create docChange
                changedRowFields = {};
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "_CompleteRowData") {
                // Read invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj)
                return null;

                // Create docChange
                invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();

            } else if (tabPos.columnName === "_AllRowDataChanged") {
                // Read invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj) {
                    let number = row ? row.value("RowId") : ""
                    invoiceObj = invoiceCreateNew(tabPos, number);
                }

                // Create docChange
                invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                changedRowFields = invoiceChangedFieldsGet(invoiceObj, row);
                docChange = new DocumentChange();
                /*
                    Check if rowId and InvoiceData are not empty to avoid creating empty invoices when deleting one.
                    We check both because when we import invoices with the extensions the field is "RowId" is
                    empty, for that reason we check also if some data are present in "InvoiceData".
                */
                if (row.value("RowId") === "" && row.value("InvoiceData") === "") {
                    // Cannot return null because the readOnly field does not reset the VatAmount
                    changedRowFields = invoiceChangedFieldsGetEmpty();
                    docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                    docChange.setDocumentForCurrentRow();
                    return docChange.getDocChange();
                } else {
                    docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                    docChange.setDocumentForCurrentRow();
                    return docChange.getDocChange();
                }

            } else if (tabPos.columnName === "Currency") {
                let defaultCurrency = getSettings().new_documents.currency
                // Update invoice
                invoiceObj = invoiceObjGet(tabPos);
                if (!invoiceObj)
                invoiceObj = invoiceCreateNew(tabPos);
                invoiceObj.document_info.currency = row.value("Currency") ? row.value("Currency") : defaultCurrency;

                // Create docChange
                changedRowFields = {};
                changedRowFields["InvoiceData"] = invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj);
                docChange = new DocumentChange();
                docChange.addOperationRowModify(tabPos.tableName, tabPos.rowNr, changedRowFields);
                docChange.setDocumentForCurrentRow();
                return docChange.getDocChange();
            }
        }

        return null;
    }

    /**
     * Edits the invoice, return a json patch document to be applied or null if the user discard the changes.
     */
    edit(tabPos, isModified) {
        var isNewDocument = false
        var invoiceObj = invoiceObjGet(tabPos);
        if (!invoiceObj) {
            invoiceObj = invoiceCreateNew(tabPos);
            isNewDocument = true;
        }

        var rowObj = null;
        var table = Banana.document.table(tabPos.tableName);
        if (tabPos.rowNr >= 0 && tabPos.rowNr < table.rowCount) {
            rowObj = table.row(tabPos.rowNr);
        }

        var docChange = new DocumentChange();

        var editor = Banana.Ui.createQml(this.getUiFileName());
        editor.qmlObject.setInvoice(invoiceObj);
        editor.qmlObject.setPosition(tabPos);
        editor.qmlObject.setDocumentChange(docChange);
        if (isModified) {
            editor.qmlObject.setIsModified(true);
        }
        if (isNewDocument) {
            editor.qmlObject.setIsModified(true);
            editor.qmlObject.setIsNew(true);
        }
        if (tabPos.tableName === "Estimates" || tabPos.parentTableName === "Estimates") {
            editor.qmlObject.setIsEstimate(true);
        }

        // Open dialog
        editor.exec();

        // The editor return a no empty DocumentChange object if some
        // changes have to be applied
        if (docChange.isEmpty()) {
            return null;
        }

        return docChange.getDocChange();
    }

    /**
     * Execute the given command and return true if succesfull or an Error object.
     *  [{id: "export", descr: "Export"}, ...]
     */
    executeCommand(commandId, fromTabPos, toTabPos) {  // TODO: Array di tabpos
        if (commandId === "createFromEstimate") {
            return this.createFromEstimate(fromTabPos);

        } else if (commandId === "duplicate") {
            return this.duplicate(fromTabPos);

        } else if (commandId === "print") {
            var invoiceObj = invoiceObjGet(fromTabPos);
            var tableName = fromTabPos.tableName;
            if (invoiceObj && tableName) {
                invoicePrint(invoiceObj, tableName);
            }
            return null;

        } else if (commandId === "print_delivery_note") {
            var invoiceObj = invoiceObjGet(fromTabPos);
            if (invoiceObj) {
                invoicePrintDeliveryNote(invoiceObj);
            }
            return null;

        } else if (commandId === "print_reminder") {
            var invoiceObj = invoiceObjGet(fromTabPos);
            if (invoiceObj) {
                invoicePrintReminder(invoiceObj);
            }
            return null;

        }

        return null;
    }

    /**
     * Returns a list of commands that can be executed and inserted in the menu as an array.
     *  [{id: "export", descr: "Export"}, ...]
     */
    getCommands() {
        return [
            {
                id: "print",
                descr: qsTr("Print invoice"),
                enabled: true,
                menu: true,
            },
            {
                id: "print_delivery_note",
                descr: qsTr("Print delivery note"),
                enabled: true,
                menu: true,
            },
            {
                id: "print_reminder",
                descr: qsTr("Print payment reminder"),
                enabled: true,
                menu: true,
            }
        ];
    }

    /**
     * Return the info to show in the info panel as object (see class InfoMessage):
     *
     * {
     *   level = 'info'|'warning'|'error';
     *   dataType = 'amount'|''; // see enum TipoValoreCampo
     *   value;
     *   text;
     *   msgId;
     *   amount1;
     *   amount2;
     *   currency;
     *   amount3;
     *   amount4;
     * }
     */
    getInfo(tabPos) {
        var invoiceObj = invoiceObjGet(tabPos);
        if (!invoiceObj) {
            return null;
        }

        var infoObj = [];
        invoiceInfoSummaryGet(invoiceObj, infoObj);
        return infoObj;
    }

    /**
     * Edits the options of the application, return true if the user accepted the changes, otherwise false.
     */
    settings() {
    }

    /**
     * Show the invoice in read only mode.
     */
    show(tabPos) {
        var invoiceObj = invoiceObjGet(tabPos);
        if (!invoiceObj) {
            return;
        }

        var rowObj = null;
        var table = Banana.document.table(tabPos.tableName);
        if (tabPos.rowNr >= 0 && tabPos.rowNr < table.rowCount) {
            rowObj = table.row(tabPos.rowNr);
        }

        var docChange = new DocumentChange();

        var editor = Banana.Ui.createQml(this.getUiFileName());
        editor.qmlObject.setInvoice(invoiceObj);
        editor.qmlObject.setPosition(tabPos);
        editor.qmlObject.setDocumentChange(docChange);
        editor.qmlObject.setIsReadOnly(true);
        if (tabPos.tableName === "Estimates" || tabPos.parentTableName === "Estimates") {
            editor.qmlObject.setIsEstimate(true);
        }

        // Open dialog
        editor.exec();

        // The editor could return a DocumentChange object in some cases
        // even if the object is read only, for example if a copy of the
        // document have to be created
        if (docChange.isEmpty()) {
            return null;
        }

        return docChange.getDocChange();
    }

    // API JsInvoicesAction

    /**
     * This method is used to create an invoice from an estimate.
     */
    createFromEstimate(tabPos) {
        var invoiceObj = invoiceCreateFromEstimate(tabPos);

        tabPos.tableName = "Invoices"
        // Set rowNr to a new row
        tabPos.rowNr = Banana.document.table("Invoices").rowCount

        var docChange = new DocumentChange();

        var editor = Banana.Ui.createQml("Invoice", this.getUiFileName());
        editor.qmlObject.setInvoice(invoiceObj);
        editor.qmlObject.setPosition(tabPos);
        editor.qmlObject.setDocumentChange(docChange);
        editor.qmlObject.setIsModified(true);
        editor.qmlObject.setIsNew(true);

        // Open dialog
        editor.exec();

        // The editor return a no empty DocumentChange object if some
        // changes have to be applied
        if (docChange.isEmpty()) {
            return null;
        }

        //Banana.Ui.showText(JSON.stringify(docChange.getDocChange(), null, "   "));

        return docChange.getDocChange();
    }

    /**
     * This method is used to duplicate an invoice or an estimate.
     */
    duplicate(tabPos) {
        var duplicatedObj = invoiceDuplicate(tabPos);
        if (!duplicatedObj)
            return null;

        // Set rowNr to a new row
        tabPos.rowNr = Banana.document.table(tabPos.tableName).rowCount

        var docChange = new DocumentChange();

        var editor = Banana.Ui.createQml("Invoice", this.getUiFileName());
        editor.qmlObject.setInvoice(duplicatedObj);
        editor.qmlObject.setPosition(tabPos);
        editor.qmlObject.setDocumentChange(docChange);
        editor.qmlObject.setIsModified(true);
        editor.qmlObject.setIsNew(true);
        if (tabPos.tableName === "Estimates" || tabPos.parentTableName === "Estimates") {
            editor.qmlObject.setIsEstimate(true);
        }

        // Open dialog
        editor.exec();

        // The editor return a no empty DocumentChange object if some
        // changes have to be applied
        if (docChange.isEmpty()) {
            return null;
        }

        //Banana.Ui.showText(JSON.stringify(docChange.getDocChange(), null, "   "));

        return docChange.getDocChange();
    }

}

Date.prototype.addDays = function (d) {
    return new Date(this.valueOf() + 24 * 60 * 60 * 1000 * d);
};

Date.prototype.diff = function (d) {
    const diffTime = Math.abs(d - this);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
};

