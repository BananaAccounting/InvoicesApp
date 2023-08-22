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

// @includejs = utils.js
// @includejs = settings.js

/**
 * The object InvoiceTools define common methods used by the JsAction.
 */

function invoiceCreateNew(tabPos, id) {
    let settings = getSettings()
    let settingsNewDocs = settings.new_documents;
    let isEstimate = tabPos.tableName === "Estimates" ? true : false;
    let docNumber = id ? id : invoiceGetNextNumber(isEstimate);

    var currentDate = new Date().toISOString().substring(0, 10);

    var invoice = {
        'document_info': {
            'number': docNumber,
            'locale': Banana.document.locale.substring(0, 2),
            'currency': settingsNewDocs.currency,
            'date': currentDate,
            'description': invoiceGetTitle(isEstimate, docNumber),
            'decimals_amounts': settingsNewDocs.decimals_amounts,
            'rounding_total': settingsNewDocs.rounding_total,
            'vat_mode': settingsNewDocs.vat_mode,
            'doc_type': isEstimate ? "17" : "10",
            'custom_fields': [
                {
                    'id': 'custom_field_1',
                    'title': 'Custom field 1',
                    'value': ''
                },
                {
                    'id': 'custom_field_2',
                    'title': 'Custom field 2',
                    'value': ''
                }

            ]
        },
        'billing_info': {
            'total_vat_rates': ''
        },
        'payment_info': {
            'due_date': ''
        },
        'customer_info': {
            'number': "",
            'business_name': '',
            'first_name': '',
            'last_name': '',
            'address1': '',
            'address2': '',
            'address3': '',
            'postal_code': '',
            'city': '',
            'country_code': '',
            'country': '',
            'phone': '',
            'email': '',
            'web': '',
            'iban': ''
        },
        'supplier_info': invoiceSupplierInfoGet(),
        'items': [
            {
                "description": "",
                "item_type": "",
                "mesure_unit": "",
                "number": "",
                "quantity": "",
                "total": "",
                "total_amount_vat_exclusive": "",
                "total_amount_vat_inclusive": "",
                "total_vat_amount": "",
                "unit_price": {
                    "amount_vat_exclusive": null,
                    "amount_vat_inclusive": null,
                    "vat_code": "",
                    "vat_rate": ""
                }
            }
        ],
        'note': []
    };

    // Update date and expiring date
    invoiceSetDate(invoice, currentDate);
    invoiceUpdateCreatorInfo(invoice);

    invoice = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoice)));

    return invoice;
}

function invoiceCreateFromEstimate(tabPos) {
    var estimateObj = invoiceObjGet(tabPos);
    if (!estimateObj)
        return null;
    invoiceUpdateCreatorInfo(estimateObj);
    invoiceUpdateSupplierInfo(estimateObj);
    return invoiceCreateFromEstimateObj(estimateObj);
}

function invoiceCreateFromEstimateObj(estimateObj) {
    if (!estimateObj)
        return null;

    estimateObj.document_info.number = invoiceGetNextNumber(false);
    estimateObj.document_info.doc_type = "10";
    invoiceSetDate(estimateObj, new Date().toISOString().substring(0, 10));
    invoiceUpdateCreatorInfo(estimateObj);
    invoiceUpdateSupplierInfo(estimateObj);
    return estimateObj;
}

function invoiceGetNextNumber(isEstimate) {
    let table = Banana.document.table(isEstimate ? "Estimates" : "Invoices");
    if (table) {
        console.log(Banana.application.apiVersion);
        if (Banana.application.apiVersion &&
            (Banana.compareVersion(Banana.application.apiVersion, "1.2.2") >= 0)) {
            return table.progressiveNumber('RowId', true);
        } else {
            let nextNumber = 0;
            for (let i = 0; i < table.rowCount; ++i) {
                let rowId = Number(table.value(i, 'RowId'))
                if (rowId > nextNumber)
                    nextNumber = rowId;
            }
            let archiveTable = table.list('Archive')
            if (archiveTable) {
                for (let i = 0; i < archiveTable.rowCount; ++i) {
                    let rowId = Number(archiveTable.value(i, 'RowId'))
                    if (rowId > nextNumber)
                        nextNumber = rowId;
                }
            }
            return (nextNumber + 1).toString();
        }
    }
    return "1";
}

function invoiceGetTitle(isEstimate, nr, lang) {
    let settings = getSettings()

    // Invoice description
    let trId = isEstimate ? "new_estimate_title" : "new_invoice_title";
    let descrNewInvoice = "";
    if (lang) {
        if (translationExists(settings, trId, lang)) {
            descrNewInvoice = getTranslatedText(settings, trId, lang)
        }
    }
    if (!descrNewInvoice) {
        if (Banana.document) {
            let trLang = Banana.document.locale.substring(0, 2);
            if (translationExists(settings, trId, trLang)) {
                descrNewInvoice = getTranslatedText(settings, trId, trLang)
            }
        }
        if (!descrNewInvoice) {
            let trLang = Banana.document.locale.substring(0, 2);
            if (translationExists(settings, trId, trLang)) {
                descrNewInvoice = getTranslatedText(settings, trId, trLang)
            }
            if (!descrNewInvoice) {
                descrNewInvoice = qsTr("Document %1");
            }
        }
    }
    descrNewInvoice = descrNewInvoice.replace('%1', nr);
    return descrNewInvoice;
}

function invoiceUpdateCreatorInfo(invoiceObj) {
    if (invoiceObj) {
        if (!invoiceObj.creator_info)
            invoiceObj.creator_info = {};
        if (Banana.script && Banana.script.getParamValue) {
            invoiceObj.creator_info.name = Banana.script.getParamValue('id');
            invoiceObj.creator_info.version = "";
            invoiceObj.creator_info.pubdate = Banana.script.getParamValue('pubdate');
            invoiceObj.creator_info.publisher = Banana.script.getParamValue('publisher');
        }
    }
}

function invoiceUpdateSupplierInfo(invoiceObj) {
    if (invoiceObj) {
        invoiceObj.supplier_info = invoiceSupplierInfoGet();
    }
}

function invoiceDuplicate(tabPos) {
    var documentObj = invoiceObjGet(tabPos);
    if (!documentObj)
        return null;

    return invoiceDuplicateObj(documentObj, tabPos);
}

function invoiceDuplicateObj(invoiceObj, tabPos) {
    if (!invoiceObj)
        return null;

    let tableName = tabPos.tableName;
    if (tabPos.tableName === "Archive" || tabPos.tableName === "Templates" ||
        tabPos.tableName === "Extract") {
        tableName = tabPos.parentTableName;
    }
    var settingsNewDocs = getSettings().new_documents;
    let isEstimate = invoiceIsEstimate(invoiceObj);
    invoiceObj.document_info.number = invoiceGetNextNumber(isEstimate);
    invoiceObj.document_info.date = new Date().toISOString().substring(0, 10);
    var due_date_days = isEstimate ?
        Number(settingsNewDocs.estimate_validity_days) :
        Number(settingsNewDocs.payment_term_days);
    invoiceObj.payment_info.due_date = dateAdd(invoiceObj.document_info.date, due_date_days);

    invoiceUpdateCreatorInfo(invoiceObj);
    invoiceUpdateSupplierInfo(invoiceObj);

    return invoiceObj;
}

function invoiceIsEstimate(invoiceObj) {
    if (invoiceObj && invoiceObj.document_info.doc_type === "17")
        return true;
    return false;
}

/** Set the date and update the due date */
function invoiceSetDate(invoiceObj, date) {
    if (!invoiceObj)
        return;

    var settingsNewDocs = getSettings().new_documents;

    var due_date_days = 0
    let invoiceDate = invoiceObj.document_info.date
    let invoiceDueDate = invoiceObj.payment_info.due_date
    if (invoiceDate && invoiceDueDate) {
        due_date_days = dateDiff(invoiceDate, invoiceDueDate)
    }
    // Added check to add invoice validity days
    if (due_date_days <= 0 || invoiceObj.document_info.doc_type === "10") {
        due_date_days = invoiceIsEstimate(invoiceObj) ?
            Number(settingsNewDocs.estimate_validity_days) :
            Number(settingsNewDocs.payment_term_days);
    }
    invoiceObj.document_info.date = date;
    invoiceObj.payment_info.due_date = dateAdd(invoiceObj.document_info.date, due_date_days)
}

function invoiceObjGet(tabPos) {
    var row = invoiceRowGet(tabPos);
    if (row) {
        try {
            var invoiceFieldObj = JSON.parse(row.value("InvoiceData"));
            return JSON.parse(invoiceFieldObj.invoice_json);
        }
        catch (e) {
            return null;
        }
    }
    return null;
}

function invoiceRowGet(tabPos) {
    if (!tabPos || !tabPos.tableName || tabPos.rowNr < 0) {
        return null;
    }
    var table = Banana.document.table(tabPos.tableName);
    if (table && tabPos.listName !== "Base") {
        table = table.list(tabPos.listName);
    }
    if (table && tabPos.rowNr >= 0 && tabPos.rowNr < table.rowCount) {
        return table.row(tabPos.rowNr);
    }
    return null;
}

function invoiceUpdatedInvoiceDataFieldGet(tabPos, invoiceObj) {
    var invoiceFieldObj = {};
    if (tabPos) {
        var row = invoiceRowGet(tabPos);
        if (row) {
            try {
                invoiceFieldObj = JSON.parse(row.value("InvoiceData"));
            } catch (e) {

            }
        }
    }
    // Save as string, because getMapValue can't handle json data
    invoiceFieldObj.invoice_json = JSON.stringify(invoiceObj);
    return invoiceFieldObj;
}

/**
 * Return the brief description of the customer address.
 */
function invoiceCustomerAddressBriefDescriptionGet(invoiceObj) {
    var addressFields = [];
    var address = invoiceObj.customer_info;
    if (address.business_name)
        addressFields.push(address.business_name);

    var customerName = [];
    if (address.first_name)
        customerName.push(address.first_name);
    if (address.last_name)
        customerName.push(address.last_name);
    if (customerName.length > 0)
        addressFields.push(customerName.join(' '));

    if (address.city)
        addressFields.push(address.city);

    if (address.country_code)
        addressFields.push(address.country_code);

    var customerDescr = addressFields.join(', ');
    customerDescr.replace('\n', ", ");
    return customerDescr;
}

function invoiceSupplierInfoGet() {
    var supplier_info = {}

    supplier_info.courtesy = Banana.document.info('AccountingDataBase', 'Courtesy');
    supplier_info.business_name = Banana.document.info('AccountingDataBase', 'Company');
    supplier_info.first_name = Banana.document.info('AccountingDataBase', 'Name');
    supplier_info.last_name = Banana.document.info('AccountingDataBase', 'FamilyName');
    supplier_info.address1 = Banana.document.info('AccountingDataBase', 'Address1');
    supplier_info.address2 = Banana.document.info('AccountingDataBase', 'Address2');
    supplier_info.address3 = "";
    supplier_info.postal_code = Banana.document.info('AccountingDataBase', 'Zip');
    supplier_info.city = Banana.document.info('AccountingDataBase', 'City');
    supplier_info.country = Banana.document.info('AccountingDataBase', 'Country');
    supplier_info.country_code = Banana.document.info('AccountingDataBase', 'CountryCode');
    supplier_info.web = Banana.document.info('AccountingDataBase', 'Web');
    supplier_info.email = Banana.document.info('AccountingDataBase', 'Email');
    supplier_info.phone = Banana.document.info('AccountingDataBase', 'Phone');
    supplier_info.mobile = Banana.document.info('AccountingDataBase', 'Mobile');
    supplier_info.fax = Banana.document.info('AccountingDataBase', 'Fax');
    supplier_info.fiscal_number = Banana.document.info('AccountingDataBase', 'FiscalNumber');
    supplier_info.vat_number = Banana.document.info('AccountingDataBase', 'VatNumber');
    supplier_info.iban_number = Banana.document.info('AccountingDataBase', 'IBAN');

    return supplier_info;
}

function invoiceChangedFieldsGet(invoiceObj, row) {
    var changedRowFields = {};

    if (invoiceObj) {
        changedRowFields["RowId"] = invoiceObj.document_info.number;
        changedRowFields["InvoiceDate"] = invoiceObj.document_info.date.substring(0, 10);
        changedRowFields["Description"] = invoiceObj.document_info.description;
        changedRowFields["ContactsId"] = invoiceObj.customer_info.number;
        changedRowFields["InvoiceAddress"] = invoiceCustomerAddressBriefDescriptionGet(invoiceObj);
        changedRowFields["InvoiceDiscountAmount"] = invoiceObj.billing_info.total_discount_vat_inclusive
        if (invoiceObj.billing_info.discount && invoiceObj.billing_info.discount.percent)
            changedRowFields["InvoiceDiscountPercentage"] = invoiceObj.billing_info.total_discount_percent;
        else
            changedRowFields["InvoiceDiscountPercentage"] = "";
        changedRowFields["InvoiceTotalAmount"] = invoiceObj.billing_info.total_to_pay;
        changedRowFields["InvoiceTotalVat"] = invoiceObj.billing_info.total_vat_amount;
        changedRowFields["EmailWork"] = invoiceObj.customer_info.email;
        changedRowFields["PhoneWork"] = invoiceObj.customer_info.phone;
        changedRowFields["InvoiceDateExpiration"] = invoiceObj.payment_info.due_date

        if (invoiceObj.note && invoiceObj.note.length > 0) {
            changedRowFields["Notes"] = invoiceObj.note[0].description ? invoiceObj.note[0].description : "";
        }

        // Remove unchanged values
        for (var propertyName in changedRowFields) {
            var rowValue = row ? row.value(propertyName) : "";
            if (rowValue === changedRowFields[propertyName]) {
                delete changedRowFields[propertyName];
            } else if (propertyName === "InvoiceDate") {
                if (changedRowFields["InvoiceDate"]) {
                    // Bug in DocumentChange.apply, dates have to be in the format yyyymmdd
                    changedRowFields["InvoiceDate"] = changedRowFields["InvoiceDate"].replace(/-/g, "");
                }
            } else if (propertyName === "InvoiceDateExpiration") {
                if (changedRowFields["InvoiceDateExpiration"]) {
                    // Bug in DocumentChange.apply, dates have to be in the format yyyymmdd
                    changedRowFields["InvoiceDateExpiration"] = changedRowFields["InvoiceDateExpiration"].replace(/-/g, "");
                }
            }
        }
    }

    return changedRowFields;
}

function invoiceInfoSummaryGet(invoiceObj, infoObj) {
    if (!invoiceObj || !infoObj)
        return;

    var infoMsg = null;

    infoMsg = {
        'text': qsTr("Invoice"),
        'amount1': invoiceObj.document_info.description
    };
    infoObj.push(infoMsg);

    infoMsg = {
        'text': qsTr("Address"),
        'amount1': invoiceCustomerAddressBriefDescriptionGet(invoiceObj)
    };
    infoObj.push(infoMsg);

    for (var i = 0; i < invoiceObj.items.length; ++i) {
        var item = invoiceObj.items[i];
        infoMsg = {};
        if (i === 0)
            infoMsg.text = qsTr("Products:")
        else
            infoMsg.text = " "
        infoMsg.amount1 = item.description;
        infoMsg.amount2 = item.quantity;
        if (item.unit_price.amount_vat_exclusive)
            infoMsg.amount3 = item.total_amount_vat_exclusive
        else
            infoMsg.amount3 = item.total_amount_vat_inclusive
        infoMsg.amount4 = item.unit_price.vat_code ? item.unit_price.vat_code : item.unit_price.vat_rate
        infoObj.push(infoMsg);
    }
}

function invoiceCustomFieldGet(invoiceObj, fieldId) {
    if (invoiceObj && invoiceObj.document_info && invoiceObj.document_info.custom_fields) {
        let custom_fields = invoiceObj.document_info.custom_fields;
        for (let i = 0; i < custom_fields.length; ++i) {
            if (custom_fields[i].id === fieldId) {
                return custom_fields[i].value;
            }
        }
    }
    return "";
}

function invoicePrint(invoiceObj, tableName) {
    if (invoiceObj) {
        let printedJsonObj = JSON.parse(JSON.stringify(invoiceObj));
        invoicePrepareForPrinting(printedJsonObj);
        Banana.document.printInvoice(JSON.stringify(printedJsonObj), tableName ? tableName : "");
    }
}

function invoicePrintDeliveryNote(invoiceObj) {
    if (invoiceObj) {
        let printedJsonObj = JSON.parse(JSON.stringify(invoiceObj));
        invoicePrepareForPrinting(printedJsonObj);
        printedJsonObj.document_info.status = "delivery_note"
        Banana.document.printInvoice(JSON.stringify(printedJsonObj));
    }
}

function invoicePrintReminder(invoiceObj) {
    if (invoiceObj) {
        let printedJsonObj = JSON.parse(JSON.stringify(invoiceObj));
        invoicePrepareForPrinting(printedJsonObj);
        printedJsonObj.document_info.status = "reminder_1"
        Banana.document.printInvoice(JSON.stringify(printedJsonObj));
    }
}

/**
 * Adapt for printing via invoice templates
 */
function invoicePrepareForPrinting(invoiceObj) {
    // Document title
    invoiceObj.document_info.title = invoiceObj.document_info.description;

    // Items
    for (let i = 0; i < invoiceObj.items.length; ++i) {
        let item = invoiceObj.items[i];

        // Document type
        if (!item.item_type || item.item_type === "" || item.item_type === "note" || item.item_type === "item") {
            // Don't let change "total" types
            if (item.total_amount_vat_exclusive || item.total_amount_vat_inclusive || item.quantity) {
                item.item_type = "item";
            } else {
                item.item_type = "note";
            }
        }

        // Item number
        item.item = item.number
    }

    // Insert discount percentage
    // JsonInvoice.calculate need to fix rounding differences to know it the percentage is calculated on the
    // inclusive or exclusive vat amount. But the layout look at the percent property to show the percentage
    // on the invoice, cz fo that copy the percent_vat_inclusive or percent_vat_exclusive to the percent property.
    // Maybe wouldbe in the JsonInvoice add a property to say if the invoice is without vat, with vat inclusive,
    // or vat exclusive.
    if (invoiceObj.billing_info.discount) {
        if (invoiceObj.billing_info.discount.percent_vat_inclusive) {
            invoiceObj.billing_info.discount.percent = invoiceObj.billing_info.discount.percent_vat_inclusive;
        } else if (invoiceObj.billing_info.discount.percent_vat_exclusive) {
            invoiceObj.billing_info.discount.percent = invoiceObj.billing_info.discount.percent_vat_exclusive;
        }
    }

    // Update custom fields descriptions
    if (invoiceObj.document_info.custom_fields) {
        let settings = getSettings();
        for (let i = 0; i < invoiceObj.document_info.custom_fields.length; ++i) {
            let field = invoiceObj.document_info.custom_fields[i];
            let fieldTrId = "invoice_" + field.id
            if (translationExists(settings, fieldTrId, invoiceObj.document_info.locale)) {
                field.title = getTranslatedText(settings, fieldTrId, invoiceObj.document_info.locale);
            }
        }
    }

    // Update supplier info
    invoiceUpdateSupplierInfo(invoiceObj);

    // Update creator info
    invoiceUpdateCreatorInfo(invoiceObj);
}
