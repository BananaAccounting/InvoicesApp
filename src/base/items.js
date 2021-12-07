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

function itemGet(id, vatExclusive) {
    if (id) {
        var tableProducts = itemTableGet();
        if (tableProducts) {
            var productRow = tableProducts.findRowByValue("RowId", id);
            if (productRow) {
                var product = {
                    "description": "",
                    "item_type": "",
                    "mesure_unit": "",
                    "number": id,
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
                    },
                };

                product.description = productRow.value('Description');
                product.mesure_unit = productRow.value('Unit');
                product.number = productRow.value('RowId');
                product.quantity = '1'; // Most users use '1' and not '1.00'
                if (vatExclusive) {
                    product.unit_price.amount_vat_exclusive = productRow.value('UnitPrice');
                } else  {
                    product.unit_price.amount_vat_inclusive = productRow.value('UnitPrice');
                }
                product.unit_price.vat_code = productRow.value('VatCode');
                product.unit_price.vat_rate = productRow.value('VatPercentage');
                return product;
            }
        }
    }

    return null;
}

function itemsGet() {
    var table = itemTableGet()
    var items = [];
    var rowCount = table.rowCount
    for (var i = 0; i < table.rowCount; ++i) {
        var id = table.value(i, "RowId")
        if (id) {
            items.push(
                        {
                            'key': table.value(i, "RowId"),
                            'descr': table.value(i, "Description")
                        })
        }
    }
    return items;
}

function itemTableGet() {
    var table = Banana.document.table("Products");
    if (table)
        return table;
    return Banana.document.table("Items");
}



