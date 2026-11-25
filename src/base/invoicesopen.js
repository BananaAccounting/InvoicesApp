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

// @includejs = invoices.js

/**
 * Whether an invoice has been paid, and how its due date stands against today.
 *
 * An invoice counts as paid when the column InvoiceDatePayment of its row holds a date.
 * Everything needed is on the row, so the list that goes to a document can show the state
 * of several hundred invoices without opening a single one of them.
 *
 * What this is and is not: something to follow up on, not a customer balance. A missing
 * payment date knows nothing about instalments, part payments, or payments recorded only
 * in the accounting.
 *
 * A report that listed the open invoices across the whole table was written here and then
 * taken out: it was registered as a command of the extension, and nobody could find where
 * Banana shows those. It is in the history if it is ever wanted again, together with the
 * Banana.Report code that laid it out.
 */

var INVOICES_PAYMENT_DATE_COLUMN = "InvoiceDatePayment";

/**
 * True when the Invoices table of this file has the payment date column at all. Most of the
 * columns of that table are optional, and without this one every invoice would be reported
 * as open - which looks broken rather than empty.
 */
function invoicesPaymentDateColumnExists() {
    var table = invoicesTableGet();
    if (!table) {
        return false;
    }
    var names = table.columnNames;
    if (!names || typeof names.indexOf !== "function") {
        // The list of columns cannot be read on this version: go on and let the rows say.
        return true;
    }
    return names.indexOf(INVOICES_PAYMENT_DATE_COLUMN) >= 0;
}

/** Today, in the format the date columns are stored in. */
function invoicesOpenToday() {
    return new Date().toISOString().substring(0, 10);
}

/**
 * Whole days from one date to the other, negative when the second one is earlier.
 *
 * Not dateDiff() from utils.js: that one returns the distance as a positive number and adds
 * a day to it, because it is used to count the days a payment term lasts. Here the sign is
 * the whole point - it is what tells late from still to come - and a day too many would
 * report an invoice as overdue on the very day it falls due.
 */
function invoicesOpenDaysBetween(fromDate, toDate) {
    if (!fromDate || !toDate) {
        return 0;
    }
    var from = Banana.Converter.toDate(fromDate.substring(0, 10));
    var to = Banana.Converter.toDate(toDate.substring(0, 10));
    if (!from || !to) {
        return 0;
    }
    return Math.round((to - from) / (1000 * 60 * 60 * 24));
}

/** How an open invoice stands, in words: late by so many days, or due in so many. */
function invoicesOpenStateText(invoice) {
    if (!invoice.dueDate) {
        return qsTr("No due date");
    }
    if (invoice.daysLate > 0) {
        return qsTr("%1 days overdue").arg(invoice.daysLate);
    }
    var days = invoicesOpenDaysBetween(invoicesOpenToday(), invoice.dueDate);
    if (days === 0) {
        return qsTr("Due today");
    }
    return qsTr("Due in %1 days").arg(days);
}
