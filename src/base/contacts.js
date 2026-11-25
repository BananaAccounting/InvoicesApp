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

// @includejs = settings.js

function contactAddressGet(id) {

    var customer_info = {
        'number': id,
        'business_name': '',
        'business_unit': '',
        'business_unit2': '',
        'business_unit3': '',
        'business_unit4': '',
        'first_name': '',
        'last_name': '',
        'address1': '',
        'building_number': '',
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
    };

    var tableContacts = contactsTableGet();
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", id);
        if (contactRow) {
            customer_info.courtesy = contactRow.value('NamePrefix');
            customer_info.business_name = contactRow.value('OrganisationName');
            customer_info.business_unit = contactRow.value('OrganisationUnit');
            customer_info.business_unit2 = contactRow.value('OrganisationUnit2');
            customer_info.business_unit3 = contactRow.value('OrganisationUnit3');
            customer_info.business_unit4 = contactRow.value('OrganisationUnit4');
            customer_info.first_name = contactRow.value('FirstName');
            customer_info.last_name = contactRow.value('FamilyName');
            customer_info.address1 = contactRow.value('Street');
            customer_info.building_number = contactRow.value('BuildingNumber');
            customer_info.address2 = contactRow.value('AddressExtra');
            customer_info.address3 = contactRow.value('POBox');
            customer_info.postal_code = contactRow.value('PostalCode');
            customer_info.city = contactRow.value('Locality');
            customer_info.country = contactRow.value('Country');
            customer_info.country_code = contactRow.value('CountryCode');
            customer_info.web = contactRow.value('Website');
            customer_info.email = contactRow.value('EmailWork');
            customer_info.phone = contactRow.value('PhoneWork');
            customer_info.mobile = contactRow.value('PhoneMobile');
            customer_info.vat_number = contactRow.value('VatNumber');
            customer_info.fiscal_number = contactRow.value('FiscalNumber');
        }
    }

    return customer_info;
}

function contactsAddressesGet() {
    var cusomersAddresses = [];
    var table = contactsTableGet();
    var rowCount = table.rowCount
    for (var i = 0; i < table.rowCount; ++i) {
        let id = table.value(i, "RowId");
        let descr = contactsBriefDescriptionGetByRowNr(i);
        if (id || descr) {
            let search = contactsSupplementSearchText(i);
            cusomersAddresses.push(
                        {
                            'key': id,
                            'descr': descr,
                            'search': search
                        });
        }
    }
    return cusomersAddresses;
}

function contactsLocalesGet() {
    var customersLocales = {};
    var table = contactsTableGet();
    for (var i = 0; i < table.rowCount; ++i) {
        var langCode = table.value(i, "Language")
        if (langCode) {
            if (!customersLocales[langCode]) {
                var langNativeName = Qt.locale(langCode).nativeLanguageName
                if (langNativeName.length > 0) {
                    langNativeName = langNativeName.charAt(0).toUpperCase() + langNativeName.slice(1)
                } else {
                    langNativeName = langCode
                }
                customersLocales[langCode] = {
                    englishName: langCode,
                    nativeName: langNativeName
                }
            }
        }
    }
    return customersLocales;
}

function contactsCurrenciesGet() {
    var customersCurrencies = {};
    var table = contactsTableGet();
    for (var i = 0; i < table.rowCount; ++i) {
        var currency = table.value(i, "Currency")
        if (!customersCurrencies[currency]) {
            customersCurrencies[currency] = {
                descr: ""
            }
        }
    }
    return customersCurrencies;
}

function contactLocaleGet(id) {

    var tableContacts = contactsTableGet();
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", id);
        if (contactRow) {
            let lang = contactRow.value('Language');
            if (lang)
                return lang.substring(0,2);
            lang = contactRow.value('LanguageCode');
            if (lang)
                return lang.substring(0,2);
        }
    }

    return Banana.document.locale.substring(0,2);
}

function contactsTableGet() {
    return Banana.document.table("Contacts");
}

/**
 * Returns the id a new contact can take: the next free number of the RowId column.
 * Read the same way as the number of a new invoice - see invoiceGetNextNumber.
 * Contacts whose id is not a number are ignored, so a file that names its contacts
 * returns "1" and the id is then for the user to replace.
 */
function contactsGetNextId() {
    let table = contactsTableGet();
    if (!table) {
        return "";
    }
    if (Banana.application.apiVersion &&
        (Banana.compareVersion(Banana.application.apiVersion, "1.2.2") >= 0)) {
        return table.progressiveNumber('RowId', true);
    }
    let nextNumber = 0;
    for (let i = 0; i < table.rowCount; ++i) {
        let rowId = Number(table.value(i, 'RowId'));
        if (rowId > nextNumber) {
            nextNumber = rowId;
        }
    }
    return (nextNumber + 1).toString();
}

/**
 * Returns the fields of a row of the Contacts table, filled from the customer_info of a
 * document, ready to be handed to DocumentChange.addOperationRowAdd("Contacts", fields).
 *
 * The mapping is the one contactAddressGet() reads in the other direction, so a contact
 * created from a document and then chosen again fills the very same fields.
 *
 * Only the columns the table really has are listed. Most of the columns of Contacts are
 * optional - OrganisationUnit2 to 4, Language and others are not in a table left as Banana
 * creates it - and naming one that is missing makes the DocumentChange report
 * "Column <name> not found" when it is applied. Which columns exist is asked of the table
 * rather than assumed, so the same contact can be created in any file.
 *
 * Empty values are kept for the columns that do exist: this builds a new row, where there
 * is nothing yet that an empty value could overwrite.
 */
function contactRowFieldsGet(id, customerInfo, locale, currency) {
    if (!customerInfo) {
        customerInfo = {};
    }

    // The columns of this file's Contacts table. Null when the list cannot be read, and
    // then every mapped column is written, as it was before this check existed.
    var columnNames = null;
    var table = contactsTableGet();
    if (table) {
        var names = table.columnNames;
        // Only used when it really is the list of names: on a Banana that does not offer
        // the property, everything is written as it was before this check existed.
        if (names && typeof names.indexOf === "function") {
            columnNames = names;
        }
    }

    var fields = {};
    var setField = function (columnName, text) {
        if (columnNames && columnNames.indexOf(columnName) < 0) {
            return;
        }
        fields[columnName] = text ? text : "";
    }

    setField("RowId", id);
    setField("NamePrefix", customerInfo.courtesy);
    setField("OrganisationName", customerInfo.business_name);
    setField("OrganisationUnit", customerInfo.business_unit);
    setField("OrganisationUnit2", customerInfo.business_unit2);
    setField("OrganisationUnit3", customerInfo.business_unit3);
    setField("OrganisationUnit4", customerInfo.business_unit4);
    setField("FirstName", customerInfo.first_name);
    setField("FamilyName", customerInfo.last_name);
    setField("Street", customerInfo.address1);
    setField("BuildingNumber", customerInfo.building_number);
    setField("AddressExtra", customerInfo.address2);
    setField("POBox", customerInfo.address3);
    setField("PostalCode", customerInfo.postal_code);
    setField("Locality", customerInfo.city);
    setField("Country", customerInfo.country);
    setField("CountryCode", customerInfo.country_code);
    setField("Website", customerInfo.web);
    setField("EmailWork", customerInfo.email);
    setField("PhoneWork", customerInfo.phone);
    setField("PhoneMobile", customerInfo.mobile);
    setField("VatNumber", customerInfo.vat_number);
    setField("FiscalNumber", customerInfo.fiscal_number);

    // The language and the currency of the document, which is what the contact would have
    // been read for - see contactLocaleGet and contactCurrencyGet.
    setField("Language", locale);
    setField("Currency", currency);

    return fields;
}

/**
 * The description of a contact that is not in the Contacts table yet, built from the
 * customer_info of a document. Same shape as contactsBriefDescription above, so a contact
 * just created reads in the selector exactly like the ones already in the table.
 */
function contactBriefDescriptionFromCustomerInfo(id, customerInfo) {
    if (!customerInfo) {
        return id ? id : "";
    }

    var addressFields = [];
    if (customerInfo.business_name)
        addressFields.push(customerInfo.business_name);

    var customerName = [];
    if (customerInfo.first_name)
        customerName.push(customerInfo.first_name);
    if (customerInfo.last_name)
        customerName.push(customerInfo.last_name);
    if (customerName.length > 0)
        addressFields.push(customerName.join(' '));

    if (addressFields.length === 0) {
        addressFields.push(id ? id : "");
    }

    if (customerInfo.city)
        addressFields.push(customerInfo.city);
    if (customerInfo.country_code)
        addressFields.push(customerInfo.country_code);

    return addressFields.join(', ').replace('\n', ", ");
}

function contactsBriefDescriptionGetById(id) {
    var tableContacts = contactsTableGet()
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", id)
        return contactsBriefDescription(contactRow)
    }
    return null;
}

function contactsBriefDescriptionGetByRowNr(rowNr) {
    var tableContacts = contactsTableGet();
    if (tableContacts) {
        var contactRow = tableContacts.row(rowNr)
        return contactsBriefDescription(contactRow)
    }
    return null;
}

function contactsBriefDescription(contactRow) {
    if (contactRow) {
        var addressFields = [];
        if (contactRow.value('OrganisationName'))
            addressFields.push(contactRow.value('OrganisationName'));

        var customerName = [];
        if (contactRow.value('FirstName'))
            customerName.push(contactRow.value('FirstName'));
        if (contactRow.value('FamilyName'))
            customerName.push(contactRow.value('FamilyName'));
        if (customerName.length > 0)
            addressFields.push(customerName.join(' '));

        if (addressFields.length === 0) {
            let rowId = contactRow.value('RowId').trim();
            if (rowId) {
                addressFields.push(rowId)
            } else {
                return null;
            }
        }

        if (contactRow.value('Locality'))
            addressFields.push(contactRow.value('Locality'));

        if (contactRow.value('CountryCode'))
            addressFields.push(contactRow.value('CountryCode'));

        var customerDescr = addressFields.join(', ');
        customerDescr.replace('\n', ", ");
        return customerDescr;
    }
    return null;
}

function contactsSupplementSearchText(rowNr) {
    var tableContacts = contactsTableGet();
    if (tableContacts) {
        var contactRow = tableContacts.row(rowNr)
        if (contactRow) {
            var searchFields = [];

            if (contactRow.value('EmailHome'))
                searchFields.push(contactRow.value('EmailHome'))
            if (contactRow.value('EmailWork'))
                searchFields.push(contactRow.value('EmailWork'))
            if (contactRow.value('EmailOther'))
                searchFields.push(contactRow.value('EmailWork'))
            if (contactRow.value('FiscalNumber'))
                searchFields.push(contactRow.value('FiscalNumber'))
            if (contactRow.value('VatNumber'))
                searchFields.push(contactRow.value('VatNumber'))

            if (searchFields.length > 0) {
                var customerSearchText = searchFields.join(', ');
                customerSearchText.replace('\n', ", ");
                return customerSearchText;
            }
        }
    }
    return '';
}

function contactCurrencyGet(customer_id) {
    var tableContacts = contactsTableGet()
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", customer_id)
        if (contactRow) {
            let currency = contactRow.value("Currency")
            if (currency) {
                return currency
            }
        }
    }
    let defaultCurrency = getSettings().new_documents.currency
    return defaultCurrency
}

/**
 * The discount agreed with the customer, as a percentage. Empty when the contact has none:
 * there is no default to fall back on, unlike the currency and the payment term.
 */
function contactDiscountPercentageGet(customer_id) {
    var tableContacts = contactsTableGet()
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", customer_id)
        if (contactRow) {
            return contactRow.value("DiscountPercentage")
        }
    }
    return ""
}

function contactPaymentTermInDaysGet(customer_id) {
    let defaultPaymentTerm = getSettings().new_documents.payment_term_days
    var tableContacts = contactsTableGet()
    if (tableContacts) {
        var contactRow = tableContacts.findRowByValue("RowId", customer_id)
        if (contactRow) {
            let paymentTermInDays = contactRow.value("PaymentTermInDays")
            return paymentTermInDays ? paymentTermInDays : defaultPaymentTerm
        }
    }
}
