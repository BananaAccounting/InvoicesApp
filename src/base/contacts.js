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
}

