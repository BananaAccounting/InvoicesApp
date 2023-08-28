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

const _settings_id = "invoices";
const _settings_version = "1.0.3";

function saveSettings(settings) {
    settings.creator = getCreatorInfo();
    Banana.document.setScriptSettings(_settings_id, JSON.stringify(settings));
}

function getSettings() {
    let settings = null;
    try {
        settings = JSON.parse(Banana.document.getScriptSettings(_settings_id));
        settings = upgradeSettings(settings);
    } catch (err) {
        settings = getDefaultSettings();
        Banana.console.log("error reading settings: invalid json")
    }
    return settings;
}

function upgradeSettings(settings) {
    if (!settings.version) {
        // we don't want overwrite settings from previous versions
        let defaultSettings = getDefaultSettings();

        settings.version = defaultSettings.version
        settings.new_documents = defaultSettings.new_documents
        settings.interface = defaultSettings.interface
        settings.translations = defaultSettings.translations

        // Resume legacy settings for new documents
        if (settings.currency)
            settings.new_documents.currency = settings.currency
        if (settings.rounding_total)
            settings.new_documents.rounding_total = settings.rounding_total
        if (settings.decimals_amounts)
            settings.new_documents.decimals_amounts = settings.decimals_amounts
        if (settings.payment_term_days)
            settings.new_documents.payment_term_days = settings.payment_term_days
        if (settings.estimate_validity_days)
            settings.new_documents.estimate_validity_days = settings.estimate_validity_days
        if (settings.vat_mode)
            settings.new_documents.vat_mode = settings.vat_mode
    }

    if (Banana.compareVersion(settings.version, _settings_version) < 0) {
        // Setting have an older previous version compated to the current versione

        let defaultSettings = getDefaultSettings();

        if (Banana.compareVersion(settings.version, '1.0.1') < 0) {
            if (!settings.new_documents)
                settings.new_documents = defaultSettings.new_documents;
            if (!settings.interface)
                settings.interface = defaultSettings.interface;
            if (!settings.translations)
                settings.translations = defaultSettings.translations;
        }

        if (Banana.compareVersion(settings.version, '1.0.2') < 0) {

            // Insert show property for address business unit fields
            let invoiceViews = settings.interface.invoice.views;
            for (const viewName in invoiceViews) {
                invoiceViews[viewName].appearance.show_invoice_address_business_unit = false;
                invoiceViews[viewName].appearance.show_invoice_address_business_unit_2 = false;
                invoiceViews[viewName].appearance.show_invoice_address_business_unit_3 = false;
                invoiceViews[viewName].appearance.show_invoice_address_business_unit_4 = false;
            }
        }

        if (Banana.compareVersion(settings.version, '1.0.3') < 0) {
            // Views 'Short' and 'Long' where renamed to 'Custom 1' and 'Custom 2'
            // Set title for existings settings so that it seem they are not renamed
            let invoiceViews = settings.interface.invoice.views;
            if (invoiceViews['short'] && !invoiceViews['short'].title) {
                invoiceViews['short'].title = qsTr("Short")
            }
            if (invoiceViews['long'] && !invoiceViews['long'].title) {
                invoiceViews['long'].title = qsTr("Long")
            }

            // Adress fields phone/email and vat number/fiscal number where separated
            // copy the settings from the old property to the news properties
            for (const viewName in invoiceViews) {
                let appearance = invoiceViews[viewName].appearance
                appearance.show_invoice_address_phone = appearance.show_invoice_address_phone_and_email;
                appearance.show_invoice_address_email = appearance.show_invoice_address_phone_and_email;
                // Don't delete, if not the those felds are not showed under qt5 version
                // delete appearance.show_invoice_address_phone_and_email;
                appearance.show_invoice_address_vat_number = appearance.show_invoice_address_vat_and_fiscal_number;
                appearance.show_invoice_address_fiscal_number = appearance.show_invoice_address_vat_and_fiscal_number;
                // Don't delete, if not the those felds are not showed under qt5 version
                // delete appearance.show_invoice_address_vat_and_fiscal_number;
            }
        }

        // TODO: in a future version rename the view 'short' to 'custom1' and 'long' to custom2
        // It is not done now because the settings have to be compatible with previous versions
        // of the Estimate and Invoice versions
        /*
        if (Banana.compareVersion(settings.version, '1.0.3' !!!) < 0) {

            // Insert show property for address business unit fields
            let invoiceViews = settings.interface.invoice.views;
            if ('short' in invoiceViews) {
                invoiceViews['custom1'] = invoiceViews['short'];
                delete invoiceViews['short'];
            }
            if ('long' in invoiceViews) {
                invoiceViews['custom2'] = invoiceViews['long'];
                delete invoiceViews['long'];
            }
       }
       */

        settings.version = _settings_version;
    }

    if (!settings.creator) {
        // We don't have to update the creator and pubdate when we read the settings,
        // we will update them when saved, so we could determine the version that created them
        // settings.creator = getCreatorInfo()
    }

    return settings
}

function getCreatorInfo() {
    return {
        'name': Banana.script.getParamValue('id'),
        'version': "",
        'pubdate': Banana.script.getParamValue('pubdate'),
        'publisher': Banana.script.getParamValue('publisher'),
    }
}

function getDefaultSettings() {
    return {
        'version': _settings_version,

        'new_documents': {
            'currency': "CHF",
            'rounding_total': "0.05",
            'decimals_amounts': 2,
            'payment_term_days': "30",
            'estimate_validity_days': "60",
            'vat_mode': "vat_none", // vat_none|vat_incl|vat_excl
            'invoice_title': qsTr("Invoice %1"),
            'estimate_title': qsTr("Estimate %1"),
        },

        'interface': {
            'invoice': {
                'current_view': "base",
                'views': {
                    'base': {
                        'title': null,
                        'visible': true,
                        'appearance': {
                            'invoce_max_visible_items_without_scrolling': 0,
                            'show_invoice_fields_if_not_empty': true,

                            'show_invoice_number': true,
                            'show_invoice_decimals': false,
                            'show_invoice_rounding_totals': false,
                            'show_invoice_language': true,
                            'show_invoice_currency': true,
                            'show_invoice_vat_mode': true,
                            'show_invoice_date': true,
                            'show_invoice_due_date': false,
                            'show_invoice_order_number': false,
                            'show_invoice_order_date': false,
                            'show_invoice_title': true,
                            'show_invoice_begin_text': true,
                            'show_invoice_end_text': true,
                            'show_invoice_internal_notes': true,
                            'show_invoice_summary': true,

                            'show_invoice_custom_field_1': false,
                            'show_invoice_custom_field_2': false,
                            'show_invoice_custom_field_3': false,
                            'show_invoice_custom_field_4': false,
                            'show_invoice_custom_field_5': false,
                            'show_invoice_custom_field_6': false,
                            'show_invoice_custom_field_7': false,
                            'show_invoice_custom_field_8': false,

                            'show_invoice_customer_selector': true,
                            'show_invoice_address_business': true,
                            'show_invoice_address_business_unit': false,
                            'show_invoice_address_business_unit_2': false,
                            'show_invoice_address_business_unit_3': false,
                            'show_invoice_address_business_unit_4': false,
                            'show_invoice_address_courtesy': true,
                            'show_invoice_address_first_and_last_name': true,
                            'show_invoice_address_street': true,
                            'show_invoice_address_extra': true,
                            'show_invoice_address_postbox': true,
                            'show_invoice_address_country_and_locality': true,
                            'show_invoice_address_phone': false,
                            'show_invoice_address_email': false,
                            'show_invoice_address_phone_and_email': false, // deprecated
                            'show_invoice_address_vat_number': false,
                            'show_invoice_address_fiscal_number': false,
                            'show_invoice_address_vat_and_fiscal_number': false, // deprecated

                            'show_invoice_item_column_row_number': true,
                            'show_invoice_item_column_type': false,
                            'show_invoice_item_column_number': true,
                            'show_invoice_item_column_date': false,
                            'show_invoice_item_column_quantity': true,
                            'show_invoice_item_column_unit': false,
                            'show_invoice_item_column_discount': false,

                            'width_invoice_item_column_row_number': -1,
                            'width_invoice_item_column_type': -1,
                            'width_invoice_item_column_number': -1,
                            'width_invoice_item_column_date': -1,
                            'width_invoice_item_column_quantity': -1,
                            'width_invoice_item_column_unit': -1,
                            'width_invoice_item_column_price': -1,
                            'width_invoice_item_column_discount': -1,
                            'width_invoice_item_column_total': -1,
                            'width_invoice_item_column_vat': -1,

                            'show_invoice_discount': true,
                            'show_invoice_vat': false,
                            'show_invoice_rounding': false,
                            'show_invoice_deposit': true,
                            'show_invoice_summary': false
                        }
                    },
                    'short': {
                        'title': null,
                        'visible': false,
                        'appearance': {
                            'invoce_max_visible_items_without_scrolling': 0,
                            'show_invoice_fields_if_not_empty': false,

                            'show_invoice_number': true,
                            'show_invoice_decimals': false,
                            'show_invoice_rounding_totals': false,
                            'show_invoice_language': false,
                            'show_invoice_currency': false,
                            'show_invoice_vat_mode': false,
                            'show_invoice_date': true,
                            'show_invoice_due_date': false,
                            'show_invoice_order_number': false,
                            'show_invoice_order_date': false,
                            'show_invoice_title': true,
                            'show_invoice_begin_text': false,
                            'show_invoice_end_text': false,
                            'show_invoice_internal_notes': false,
                            'show_invoice_summary': false,

                            'show_invoice_custom_field_1': false,
                            'show_invoice_custom_field_2': false,
                            'show_invoice_custom_field_3': false,
                            'show_invoice_custom_field_4': false,
                            'show_invoice_custom_field_5': false,
                            'show_invoice_custom_field_6': false,
                            'show_invoice_custom_field_7': false,
                            'show_invoice_custom_field_8': false,

                            'show_invoice_customer_selector': true,
                            'show_invoice_address_business': true,
                            'show_invoice_address_business_unit': false,
                            'show_invoice_address_business_unit_2': false,
                            'show_invoice_address_business_unit_3': false,
                            'show_invoice_address_business_unit_4': false,
                            'show_invoice_address_courtesy': false,
                            'show_invoice_address_first_and_last_name': true,
                            'show_invoice_address_street': false,
                            'show_invoice_address_extra': false,
                            'show_invoice_address_postbox': false,
                            'show_invoice_address_country_and_locality': true,
                            'show_invoice_address_phone': false,
                            'show_invoice_address_email': false,
                            'show_invoice_address_phone_and_email': false, // deprecated
                            'show_invoice_address_vat_number': false,
                            'show_invoice_address_fiscal_number': false,
                            'show_invoice_address_vat_and_fiscal_number': false, // deprecated

                            'show_invoice_item_column_row_number': true,
                            'show_invoice_item_column_type': false,
                            'show_invoice_item_column_number': true,
                            'show_invoice_item_column_date': false,
                            'show_invoice_item_column_quantity': false,
                            'show_invoice_item_column_unit': false,
                            'show_invoice_item_column_discount': false,

                            'width_invoice_item_column_row_number': -1,
                            'width_invoice_item_column_type': -1,
                            'width_invoice_item_column_number': -1,
                            'width_invoice_item_column_date': -1,
                            'width_invoice_item_column_quantity': -1,
                            'width_invoice_item_column_unit': -1,
                            'width_invoice_item_column_price': -1,
                            'width_invoice_item_column_discount': -1,
                            'width_invoice_item_column_total': -1,
                            'width_invoice_item_column_vat': -1,

                            'show_invoice_discount': false,
                            'show_invoice_vat': false,
                            'show_invoice_rounding': false,
                            'show_invoice_deposit': false,
                            'show_invoice_summary': false
                        }
                    },
                    'long': {
                        'title': null,
                        'visible': false,
                        'appearance': {
                            'invoce_max_visible_items_without_scrolling': 0,
                            'show_invoice_fields_if_not_empty': false,

                            'show_invoice_number': true,
                            'show_invoice_decimals': false,
                            'show_invoice_rounding_totals': false,
                            'show_invoice_language': true,
                            'show_invoice_currency': true,
                            'show_invoice_vat_mode': true,
                            'show_invoice_date': true,
                            'show_invoice_due_date': true,
                            'show_invoice_order_number': true,
                            'show_invoice_order_date': true,
                            'show_invoice_title': true,
                            'show_invoice_begin_text': false,
                            'show_invoice_end_text': true,
                            'show_invoice_internal_notes': true,
                            'show_invoice_summary': true,

                            'show_invoice_custom_field_1': true,
                            'show_invoice_custom_field_2': true,
                            'show_invoice_custom_field_3': true,
                            'show_invoice_custom_field_4': false,
                            'show_invoice_custom_field_5': false,
                            'show_invoice_custom_field_6': false,
                            'show_invoice_custom_field_7': false,
                            'show_invoice_custom_field_8': false,

                            'show_invoice_customer_selector': true,
                            'show_invoice_address_business': true,
                            'show_invoice_address_business_unit': false,
                            'show_invoice_address_business_unit_2': false,
                            'show_invoice_address_business_unit_3': false,
                            'show_invoice_address_business_unit_4': false,
                            'show_invoice_address_courtesy': false,
                            'show_invoice_address_first_and_last_name': true,
                            'show_invoice_address_street': true,
                            'show_invoice_address_extra': true,
                            'show_invoice_address_postbox': true,
                            'show_invoice_address_country_and_locality': true,
                            'show_invoice_address_phone': false,
                            'show_invoice_address_email': false,
                            'show_invoice_address_phone_and_email': false, // deprecated
                            'show_invoice_address_vat_number': false,
                            'show_invoice_address_fiscal_number': false,
                            'show_invoice_address_vat_and_fiscal_number': false, // deprecated

                            'show_invoice_item_column_row_number': true,
                            'show_invoice_item_column_type': true,
                            'show_invoice_item_column_number': true,
                            'show_invoice_item_column_date': true,
                            'show_invoice_item_column_quantity': true,
                            'show_invoice_item_column_unit': true,
                            'show_invoice_item_column_discount': true,

                            'width_invoice_item_column_row_number': -1,
                            'width_invoice_item_column_type': -1,
                            'width_invoice_item_column_number': -1,
                            'width_invoice_item_column_date': -1,
                            'width_invoice_item_column_quantity': -1,
                            'width_invoice_item_column_unit': -1,
                            'width_invoice_item_column_price': -1,
                            'width_invoice_item_column_discount': -1,
                            'width_invoice_item_column_total': -1,
                            'width_invoice_item_column_vat': -1,

                            'show_invoice_discount': true,
                            'show_invoice_vat': false,
                            'show_invoice_rounding': false,
                            'show_invoice_deposit': true,
                            'show_invoice_summary': true
                        }
                    },
                    'full': {
                        'title': null,
                        'visible': true,
                        'appearance': {
                            'width_invoice_item_column_row_number': -1,
                            'width_invoice_item_column_number': -1,
                            'width_invoice_item_column_date': -1,
                            'width_invoice_item_column_quantity': -1,
                            'width_invoice_item_column_unit': -1,
                            'width_invoice_item_column_price': -1,
                            'width_invoice_item_column_discount': -1,
                            'width_invoice_item_column_total': -1,
                            'width_invoice_item_column_vat': -1,
                        }
                    }
                }
            },
            'notifications': {
                'show_updated_version_installed': false
            }
        },

        'translations': [
            {
                'id': 'new_invoice_title',
                'descr': qsTr("Title for new invoices."),
                'tr': {
                    'de': 'Rechnung %1',
                    'fr': 'Facture %1',
                    'en': 'Invoice %1',
                    'es': 'Factura %1',
                    'it': 'Fattura %1',
                    'nl': 'Factuur %1',
                    'pt': 'Fatura %1',
                    'zh': '发票 %1'
                }
            },
            {
                'id': 'new_estimate_title',
                'descr': qsTr("Title for new estimates."),
                'tr': {
                    'de': 'Offerte %1',
                    'fr': 'Offre %1',
                    'en': 'Estimate %1',
                    'es': 'Cuenta %1',
                    'it': 'Offerta %1',
                    'nl': 'Offerte %1',
                    'pt': 'Conta %1',
                    'zh': '预算 %1'
                }
            },
            {
                'id': 'invoice_custom_field_1',
                'tr': {
                    'de': 'Weiter Info. 1',
                    'fr': 'Info. additionnelle 1',
                    'en': 'Additional info 1',
                    'es': 'Info. adicional 1',
                    'it': 'Info. aggiuntive 1',
                    'nl': 'Extra info. 1',
                    'pt': 'Info. adicionais 1',
                    'zh': '附加信息 1'
                }
            },
            {
                'id': 'invoice_custom_field_2',
                'tr': {
                    'de': 'Weiter Info. 2',
                    'fr': 'Info. additionnelle 2',
                    'en': 'Additional info 2',
                    'es': 'Info. adicional 2',
                    'it': 'Info. aggiuntive 2',
                    'nl': 'Extra info. 2',
                    'pt': 'Info. adicionais 2',
                    'zh': '附加信息 2'
                }
            },
            {
                'id': 'invoice_custom_field_3',
                'tr': {
                    'de': 'Weiter Info. 3',
                    'fr': 'Info. additionnelle 3',
                    'en': 'Additional info 3',
                    'es': 'Info. adicional 3',
                    'it': 'Info. aggiuntive 3',
                    'nl': 'Extra info. 3',
                    'pt': 'Info. adicionais 3',
                    'zh': '附加信息 3'
                }
            },
            {
                'id': 'invoice_custom_field_4',
                'tr': {
                    'de': 'Weiter Info. 4',
                    'fr': 'Info. additionnelle 4',
                    'en': 'Additional info 4',
                    'es': 'Info. adicional 4',
                    'it': 'Info. aggiuntive 4',
                    'nl': 'Extra info. 4',
                    'pt': 'Info. adicionais 4',
                    'zh': '附加信息 4'
                }
            },
            {
                'id': 'invoice_custom_field_5',
                'tr': {
                    'de': 'Weiter Info. 5',
                    'fr': 'Info. additionnelle 5',
                    'en': 'Additional info 5',
                    'es': 'Info. adicional 5',
                    'it': 'Info. aggiuntive 5',
                    'nl': 'Extra info. 5',
                    'pt': 'Info. adicionais 5',
                    'zh': '附加信息 5'
                }
            },
            {
                'id': 'invoice_custom_field_6',
                'tr': {
                    'de': 'Weiter Info. 6',
                    'fr': 'Info. additionnelle 6',
                    'en': 'Additional info 6',
                    'es': 'Info. adicional 6',
                    'it': 'Info. aggiuntive 6',
                    'nl': 'Extra info. 6',
                    'pt': 'Info. adicionais 6',
                    'zh': '附加信息 6'
                }
            },
            {
                'id': 'invoice_custom_field_7',
                'tr': {
                    'de': 'Weiter Info. 7',
                    'fr': 'Info. additionnelle 7',
                    'en': 'Additional info 7',
                    'es': 'Info. adicional 7',
                    'it': 'Info. aggiuntive 7',
                    'nl': 'Extra info. 7',
                    'pt': 'Info. adicionais 7',
                    'zh': '附加信息 7'
                }
            },
            {
                'id': 'invoice_custom_field_8',
                'tr': {
                    'de': 'Weiter Info. 8',
                    'fr': 'Info. additionnelle 8',
                    'en': 'Additional info 8',
                    'es': 'Info. adicional 8',
                    'it': 'Info. aggiuntive 8',
                    'nl': 'Extra info. 8',
                    'pt': 'Info. adicionais 8',
                    'zh': '附加信息 8'
                }
            }
        ],

        'creator' : getCreatorInfo()
    };
}

function getSettingsRequiringAdvancedPlan() {
    return  fieldsRequiringAvancedPlan = {
        'appearance': [
            'show_invoice_custom_field_1',
            'show_invoice_custom_field_2',
            'show_invoice_custom_field_3',
            'show_invoice_custom_field_4',
            'show_invoice_custom_field_5',
            'show_invoice_custom_field_6',
            'show_invoice_custom_field_7',
            'show_invoice_custom_field_8',
            'show_invoice_address_business_unit',
            'show_invoice_address_business_unit_2',
            'show_invoice_address_business_unit_3',
            'show_invoice_address_business_unit_4',
            'show_invoice_item_column_type',
            'show_invoice_item_column_date',
            'show_invoice_item_column_discount'
        ]
    };
}

function translationExists(settings, id, lang) {
    if (settings.translations) {
        for (let i = 0; i < settings.translations.length; ++i) {
            let tr = settings.translations[i];
            if (tr.id === id && tr.tr[lang]) {
                return true;
            }
        }
    }
    return false;
}


function getTranslation(settings, id) {
    if (!settings)
        return null;
    if (settings.translations) {
        for (let i = 0; i < settings.translations.length; ++i) {
            let tr = settings.translations[i];
            if (tr.id === id) {
                return tr;
            }
        }
    }
    let defaultSettings = getDefaultSettings()
    for (let i = 0; i < defaultSettings.translations.length; ++i) {
        let tr = defaultSettings.translations[i];
        if (tr.id === id) {
            if (tr.id === id) {
                return tr;
            }
        }
    }
    return null;
}

function getTranslationDescription(settings, id) {
    let tr = getTranslation(settings, id);
    if (tr && tr.descr) {
        return tr.descr;
    }
    return qsTr("Text");
}

function getTranslatedText(settings, id, lang) {
    let translation = getTranslation(settings, id);
    if (translation) {
        let text = translation.tr[lang];
        if (text) return text;
        text = translation.tr[Banana.application.locale.substring(0,2)];
        if (text) return text;
        text = translation.tr['en'];
        if (text) return text;
     }
    return id;
}

function setTranslatedText(settings, id, lang, text) {
    if (!settings)
        return;

    let defaultSettings = null;
    if (!settings.translations) {
        defaultSettings = getDefaultSettings();
        settings.translations = defaultSettings.translations;
    }

    let translation = null
    for (let i = 0; i < settings.translations.length; ++i) {
        let tr = settings.translations[i];
        if (tr.id === id) {
            translation = tr;
            break;
        }
    }

    if (!translation) {
        if (!sdefaultSettings) {
            defaultSettings = getDefaultSettings();
        }
        for (let i = 0; i < defaultSettings.translations.length; ++i) {
            let tr = defaultSettings.translations[i];
            if (tr.id === id) {
                translation = tr;
                settings.translations.push(translation);
                break;
            }
        }
    }

    if (translation) {
        translation.tr[lang] = text;
    }
}
