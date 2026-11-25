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

/**
 * The class DocumentChange define some methods to simplify the construction
 * of a DocumentChange document.
 */
var DocumentChange = class DocumentChange {

    constructor() {
        this.jsonDoc = {};
        this.jsonDoc.data = [];
        this.jsonDoc.creator = {};
        this.jsonDoc.creator.executionDate = this.getCurrentDate();
        this.jsonDoc.creator.executionTime = this.getCurrentTime();
        this.jsonDoc.creator.name = Banana.script.getParamValue('id');
        this.jsonDoc.creator.version = "1.0";
        this.jsonDoc.format = "documentchange";
        this.addDocument();
    }

    addDocument() {
        var doc = {};
        doc.document = {};
        doc.document.fileVersion = "1.0.0";
        doc.document.dataUnits = [];
        this.jsonDoc.data.push(doc);
    }

    setOperationCursorMove(tableName, rowNr, columnName) {
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.cursorPosition = {
            "operation": "move",
            "tableName": tableName,
            "rowNr": rowNr,
            "columnName": columnName
        }
    }

    addOperationRowModify(tableName, rowNr, fieldChanges) {
        var row = {};
        row.operation = {};
        row.operation.name = "modify";
        row.operation.sequence = rowNr.toString();
        row.fields = fieldChanges;

        //rows
        var rows = [];
        rows.push(row);

        //table
        var dataUnitTransactions = {};
        dataUnitTransactions.nameXml = tableName;
        dataUnitTransactions.data = {};
        dataUnitTransactions.data.rowLists = [];
        dataUnitTransactions.data.rowLists.push({"rows":rows});

        //document
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.dataUnits.push(dataUnitTransactions);
    }

    addOperationRowAdd(tableName, fieldChanges) {
        var row = {};
        row.operation = {};
        row.operation.name = "add";
        row.fields = fieldChanges;

        //rows
        var rows = [];
        rows.push(row);

        //table
        var dataUnitTransactions = {};
        dataUnitTransactions.nameXml = tableName;
        dataUnitTransactions.data = {};
        dataUnitTransactions.data.rowLists = [];
        dataUnitTransactions.data.rowLists.push({"rows":rows});

        //document
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.dataUnits.push(dataUnitTransactions);
    }

    /**
     * Marks a row of the table for deletion. The sequence is the row number the row has
     * before any of these changes is applied, counted from 0 - the same numbering
     * addOperationRowModify uses. Deleting does not renumber the rows that follow, so
     * several deletions in one document each keep the number of their own row.
     */
    addOperationRowDelete(tableName, rowNr) {
        var row = {};
        row.operation = {};
        row.operation.name = "delete";
        row.operation.sequence = rowNr.toString();

        //rows
        var rows = [];
        rows.push(row);

        //table
        var dataUnitTransactions = {};
        dataUnitTransactions.nameXml = tableName;
        dataUnitTransactions.data = {};
        dataUnitTransactions.data.rowLists = [];
        dataUnitTransactions.data.rowLists.push({"rows":rows});

        //document
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.dataUnits.push(dataUnitTransactions);
    }

    removeLastOperation() {
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.dataUnits.pop();
    }

    getDocChange() {
        return this.jsonDoc;
    }

    isEmpty() {
        for (var i = 0; i < this.jsonDoc.data.length; ++i) {
            if (this.jsonDoc.data[i].document.dataUnits.length > 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * Set this DocumentChange for the currentRow (necesssary for ChangeNotifyAfter)
     */
    setDocumentForCurrentRow() {
        var currentDoc = this.jsonDoc.data[this.jsonDoc.data.length-1].document;
        currentDoc.id = "currentRow";
    }

    /**
     * Internal method getCurrentDate
     */
    getCurrentDate() {
        var d = new Date();
        var datestring = d.getFullYear() + ("0" + (d.getMonth() + 1)).slice(-2) + ("0" + d.getDate()).slice(-2);
        return Banana.Converter.toInternalDateFormat(datestring, "yyyymmdd");
    }

    /**
     * Internal method getCurrentTime
     */
    getCurrentTime() {
        var d = new Date();
        var timestring = ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
        return Banana.Converter.toInternalTimeFormat(timestring);
    }

}
