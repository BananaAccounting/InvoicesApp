// Copyright [2026] [Banana.ch SA - Lugano Switzerland]
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
//

// @id = ch.banana.application.invoice.test
// @api = 1.0
// @pubdate = 2026-10-06
// @publisher = Banana.ch SA
// @description = <TEST ch.banana.application.invoice.test>
// @task = app.command
// @doctype = *.*
// @docproperties =
// @outputformat = none
// @inputdataform = none
// @timeout = -1

/*

  Instructions to recalculate invoices data when modifying the dialog:
  ----------------------------------------------------------------------

  -Open the invoice_example_test.ac2 file
  -Open each invoice and re-select the same customer, than save the invoice

  When running the test, the only difference should be the "@pubdate" date.
  
*/

// Register test case to be executed
Test.registerTestCase(new TestInvoiceDocuments());

// Here we define the class, the name of the class is not important
function TestInvoiceDocuments() {

}

// This method will be called at the beginning of the test case
TestInvoiceDocuments.prototype.initTestCase = function () {

}

// This method will be called at the end of the test case
TestInvoiceDocuments.prototype.cleanupTestCase = function () {

}

// This method will be called before every test method is executed
TestInvoiceDocuments.prototype.init = function () {

}

// This method will be called after every test method is executed
TestInvoiceDocuments.prototype.cleanup = function () {

}

TestInvoiceDocuments.prototype.testInvoiceDocuments = function () {

   Test.logger.addComment("Estimates and invoices of the test document, as they are stored");

   var fileAC2 = "file:script/../test/testcases/invoice_example_test.ac2";
   var banDoc = Banana.application.openDocument(fileAC2);
   if (!banDoc) {
      Test.logger.addFatalError("ac2 file not valid: " + fileAC2);
      return;
   }

   var documents = getJsonInvoices(banDoc);

   for (var i = 0; i < documents.length; i++) {
      Test.logger.addSubSection(getDocumentName(documents[i]));
      addTotals(documents[i].invoiceObj);
      Test.logger.addJson("Document", JSON.stringify(sortedByKey(documents[i].invoiceObj)));
   }

   // Without this an empty document, or a column renamed in a future version of Banana,
   // would quietly pass as "nothing has changed".
   Test.assert(documents.length > 0);
}

/**
 * Every estimate and invoice of the file, in the order the tables hold them.
 */
function getJsonInvoices(banDoc) {

   var documents = [];
   var tableNames = getTableNames(banDoc);
   var examined = [];

   for (var t = 0; t < tableNames.length; t++) {

      var table = banDoc.table(tableNames[t]);
      if (!table)
         continue;

      examined.push(tableNames[t] + " (" + table.rowCount + ")");

      for (var rowNr = 0; rowNr < table.rowCount; rowNr++) {
         var invoiceObj = invoiceObjGet(table.row(rowNr));
         if (invoiceObj) {
            documents.push({
               tableName: tableNames[t],
               rowNr: rowNr,
               invoiceObj: invoiceObj
            });
         }
      }
   }

   if (!documents.length) {
      // Says where it looked, so the next run shows which table to read instead of failing
      // again with nothing to go on.
      Test.logger.addFatalError("no document found in the tables: " +
                                (examined.length ? examined.join(", ") : "none of " + tableNames.join(", ")));
   }

   return documents;
}

/**
 * The tables of the document, asked of Banana where it can answer. The list is the fallback
 * for a Banana that does not offer the names: these are the tables this extension stores
 * estimates and invoices in.
 */
function getTableNames(banDoc) {

   var tableNames = banDoc.tableNames;
   if (typeof tableNames === "function")
      tableNames = banDoc.tableNames();

   if (tableNames && tableNames.length)
      return tableNames;

   return ["Estimates", "Invoices", "Archive", "Templates", "Extract"];
}

/**
 * The document stored in a row, or null when the row holds none. Same two steps the
 * extension itself takes, see invoiceObjGet() in src/base/invoice.js: the column holds a
 * json object whose invoice_json field is itself json.
 */
function invoiceObjGet(row) {
   if (!row)
      return null;
   try {
      var invoiceFieldObj = JSON.parse(row.value("InvoiceData"));
      return JSON.parse(invoiceFieldObj.invoice_json);
   } catch (e) {
      return null;
   }
}

/**
 * Named after the table and the document number, not after the row: inserting a document
 * then does not move every result below it in the comparison.
 */
function getDocumentName(document) {

   var number = "";
   if (document.invoiceObj.document_info && document.invoiceObj.document_info.number)
      number = String(document.invoiceObj.document_info.number);

   return document.tableName + " " + (number.length ? number : "row_" + document.rowNr);
}

/**
 * The figures first, so that a difference in the amounts is visible without reading the
 * whole object below.
 */
function addTotals(invoiceObj) {

   if (!invoiceObj || !invoiceObj.billing_info)
      return;

   var keys = ["total_amount_vat_exclusive", "total_vat_amount", "total_amount_vat_inclusive",
               "total_discount_vat_inclusive", "total_rounding_difference", "total_to_pay"];

   for (var i = 0; i < keys.length; i++) {
      if (keys[i] in invoiceObj.billing_info)
         Test.logger.addKeyValue(keys[i], String(invoiceObj.billing_info[keys[i]]));
   }
}

/**
 * The same data with the keys of every object in alphabetical order.
 */
function sortedByKey(value) {

   if (Array.isArray(value)) {
      var array = [];
      for (var i = 0; i < value.length; i++)
         array.push(sortedByKey(value[i]));
      return array;
   }

   if (value && typeof value === "object") {
      var sorted = {};
      var keys = Object.keys(value).sort();
      for (var k = 0; k < keys.length; k++)
         sorted[keys[k]] = sortedByKey(value[keys[k]]);
      return sorted;
   }

   return value;
}
