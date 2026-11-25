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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "."
import "./components"

import "../base/invoice.js" as InvoiceJs
import "../base/invoicesopen.js" as InvoicesOpenJs

/*
   The window of one estimate or invoice.

   It is built as a single page with a bar above it and a bar below it:

   - the bar above says which document is open, how far along the table it is, and what it
     totals, and holds the arrows that walk through the documents of the table plus the menu
     of the commands that are not Save and Close;
   - the page itself is the form, WdgInvoice, which is the only page the user normally sees.
     Settings, and the pages that exist only in the internal build, are reached from that
     menu and replace the form until they are left again;
   - the bar below holds Save and Close, and nothing else: the two things one always wants
     to find in the same place.
*/
Item {
    id: window

    // Never larger than the screen: a fixed 1000x600 pushed the button bar out of reach on
    // a small display, and both axes go full screen together or a phone ends up full width
    // but not full height. Mobile is asked of the platform, not of the size: there is no
    // window manager there, and an iPad in landscape passed the size test by coincidence.
    readonly property bool isSmallScreen: Qt.platform.os === "ios" || Qt.platform.os === "android" ||
                                          (Screen.width > 0 && Screen.height > 0 &&
                                           (Screen.width < 1000 * Stylesheet.pixelScaleRatio ||
                                            Screen.height < 600 * Stylesheet.pixelScaleRatio))

    width: Screen.width > 0 ? (isSmallScreen ? Screen.width : 1000 * Stylesheet.pixelScaleRatio)
                             : 1000 * Stylesheet.pixelScaleRatio
    height: Screen.height > 0 ? (isSmallScreen ? Screen.height : 600 * Stylesheet.pixelScaleRatio)
                              : 600 * Stylesheet.pixelScaleRatio

    focus: true

    // Placehoder for setTitle function, it is set by c++
    property var setTitle: null

    property int result: 0;

    // Pages

    readonly property int page_invoice: 0
    readonly property int page_settings: 1
    readonly property int page_source: 2
    readonly property int page_development: 3
    readonly property int page_changelog: 4

    property int currentPage: page_invoice

    readonly property string currentPageTitle: {
        switch (currentPage) {
        case page_settings: return qsTr("Settings")
        case page_source: return qsTr("Source")
        case page_development: return qsTr("Development")
        case page_changelog: return qsTr("Changelog")
        }
        return documentTitle
    }

    /* The document being edited, "Invoice 123" or "Estimate 123". signalInvoiceChanged is
       read so the binding follows a change of number: the json itself notifies nothing. */
    readonly property string documentTitle: invoice.signalInvoiceChanged && invoice.json &&
                                            invoice.json.document_info ?
                                                getDocumentName().trim() : qsTr("Document")

    /* The line under the title: what state the document is in, and where it sits in the
       table. Both are easy to miss in a window title, and there is no window title at all
       on a phone.

       The state is a word on a coloured ground rather than more grey text: a document with
       changes that are not saved is the one thing in this window worth catching the eye,
       and it read as just another line of the same grey as everything around it. */
    readonly property string documentState: {
        if (invoice.isReadOnly)
            return qsTr("Read only")
        if (invoice.signalInvoiceChanged && invoice.isModified)
            return qsTr("Not saved")
        return ""
    }

    // Amber while there is something to save, plain grey for a document that is only shown.
    readonly property bool documentStateIsWarning: !invoice.isReadOnly

    // The total belongs beside the title on a wide window and on its own line on a narrow
    // one, where the row cannot hold both.
    readonly property bool compactHeader: wdgInvoice.compactLayout

    Keys.onEscapePressed: function(event) {
        focus = true
        if (invoice.isModified) {
            cancelConfirmDialog.open()
            event.accepted = true
        } else {
            closeDialog()
            event.accepted = true
        }
    }

    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_9) &&
                            (event.modifiers & Qt.AltModifier) &&
                            (event.modifiers & Qt.ControlModifier)) {
                            // Ctrl + Alt + 9
                            pixelMetricsDialog.visible = true
                            event.accepted = true
                        } else if (currentPage === page_invoice &&
                                   (event.key === Qt.Key_F) &&
                                   (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier))) {
                            // Ctrl + F, or Cmd + F
                            openGoToDocument()
                            event.accepted = true
                        } else if (currentPage === page_invoice &&
                                   (event.modifiers & Qt.AltModifier) &&
                                   (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp)) {
                            // Alt + Left: the previous document of the table
                            goToPreviousDocument()
                            event.accepted = true
                        } else if (currentPage === page_invoice &&
                                   (event.modifiers & Qt.AltModifier) &&
                                   (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown)) {
                            // Alt + Right: the next document of the table
                            goToNextDocument()
                            event.accepted = true
                        }
                    }

    Keys.onReleased: (event) => {
                         if (event.key === Qt.Key_Help || event.key === Qt.Key_F1) {
                             showHelp()
                             event.accepted = true
                         }
                     }

    Component.onCompleted: {
        appSettings.loadSettings()
        // Check for changing dialog title
        if (Banana.document.cursor.tableName === "Invoices")
            setIsEstimate(false)
        else
            setIsEstimate(true)
    }

    // Interface

    function getInvoice(invoice) {
        return invoice.json
    }

    function getTitle() {
        let title = getDocumentName()
        if (invoice.isReadOnly) {
            title += " [" + qsTr("Read only") + "]"
        } else if (invoice.isModified) {
            title += " *"
        }
        return title
    }

    // The document being edited, "Invoice 123" or "Estimate 123": the title without the
    // read only or modified markers. Also shown at the top of the window - see documentTitle.
    function getDocumentName() {
        let title = qsTr("Document")
        if (invoice.json.document_info.number) {
            if (invoice.isEstimate()) {
                title = qsTr("Estimate %1").arg(invoice.json.document_info.number)
            } else  {
                title = qsTr("Invoice %1").arg(invoice.json.document_info.number)
            }
        } else {
            if (invoice.isEstimate()) {
                title = qsTr("New estimate %1").arg(invoice.json.document_info.number)
            } else  {
                title = qsTr("New invoice %1").arg(invoice.json.document_info.number)
            }
        }
        return title
    }

    function setIsNew(newDocument) {
        invoice.setIsNew(newDocument)
    }

    function setIsModified(modified) {
        invoice.setIsModified(modified)
    }

    function setIsEstimate(estimate) {
        invoice.setIsEstimate(estimate)
    }

    function setIsReadOnly(readOnly) {
        invoice.isReadOnly = readOnly
        updateTitle()
    }

    function setInvoice(json) {
        invoice.setInvoice(json)
        wdgInvoice.updateView()
        updateTitle()
    }

    function setPosition(tabPos) {
        invoice.setPosition(tabPos)
        signalPositionChanged++
    }

    function setDocumentChange(docChange) {
        invoice.setDocumentChange(docChange)
    }

    function showHelp() {
        if (currentPage === page_settings) {
            Banana.Ui.showHelp("dlginvoiceedit::settings");
        } else {
            Banana.Ui.showHelp("dlginvoiceedit");
        }
    }

    function updateTitle() {
        let title = getTitle()
        if (setTitle) {
            window.setTitle(title)
        }
    }

    function closeDialog() {
        appSettings.saveSettings()
        Qt.quit()
    }

    // Navigation through the documents of the table
    //
    // The arrows move the window from one row of the Invoices or Estimates table to the next,
    // so that going from one document to another does not mean closing the window and opening
    // it again. Nothing else changes: the row is read exactly as the extension reads it when
    // the window is opened on it, and a document that is saved on the way out adds its own
    // operation to the same DocumentChange, which Banana applies once the window is closed.

    /* The documents saved while this window was open, by the row they belong to. The table
       itself is only written once the window closes, so a row that has already been saved
       still holds its previous content: coming back to it would show the old figures and
       quietly undo the editing. What was saved is kept here and shown instead. */
    property var savedDocuments: ({})

    /* The rows marked for deletion while this window was open, by row. They are still rows
       of the table until Banana applies the DocumentChange, so the arrows have to be told
       to walk past them, and nothing may open one of them again. */
    property var deletedRows: ({})

    /* Bumped when a row is marked for deletion, so that what the arrows can reach is worked
       out again: deletedRows is a plain object and notifies nothing on its own. */
    property int signalDeletedRowsChanged: 1

    /* Bumped whenever the row the window stands on changes. The position is handed over
       after the document is, and a tabPos notifies nothing when one of its own fields is
       written, so without this counter the arrows would be reading the position the window
       was opened with - or none at all. */
    property int signalPositionChanged: 1

    readonly property int navRowCount: signalPositionChanged && invoice.signalInvoiceChanged ?
                                           getNavTableRowCount() : 0
    readonly property int navRowNr: signalPositionChanged && invoice.signalInvoiceChanged &&
                                    invoice.tabPos ? invoice.tabPos.rowNr : -1

    /* A document that is not a row of the table yet - a new one, a copy, an invoice just
       created from an estimate - has nowhere to walk from, so the arrows stay off until it
       has been saved and the window reopened on it. */
    readonly property bool canNavigate: navRowCount > 0 && navRowNr >= 0 && navRowNr < navRowCount
    readonly property bool canGoPrevious: signalDeletedRowsChanged ? findLiveRow(navRowNr, -1) >= 0 : false
    readonly property bool canGoNext: signalDeletedRowsChanged ? findLiveRow(navRowNr, 1) >= 0 : false

    /* A document is a row of the table and can be deleted, as opposed to one that has not
       been saved yet - a new one, a copy, an invoice created from an estimate - which has
       nothing in the table to remove. */
    readonly property bool canDelete: !invoice.isReadOnly && canNavigate

    readonly property string navPositionText: canNavigate ?
                                                  qsTr("%1 of %2").arg(navRowNr + 1).arg(navRowCount) : ""

    // What to do once the question about unsaved changes has been answered.
    property string pendingAction: ""
    property int pendingNavRowNr: -1

    /** The table, or the row list of the table, the open document belongs to. */
    function getNavTable() {
        if (!invoice.tabPos || !invoice.tabPos.tableName)
            return null
        let table = Banana.document.table(invoice.tabPos.tableName)
        // As invoiceRowGet() reads it: outside the base list the rows come from the list.
        if (table && invoice.tabPos.listName && invoice.tabPos.listName !== "Base")
            table = table.list(invoice.tabPos.listName)
        return table
    }

    function getNavTableRowCount() {
        let table = getNavTable()
        return table ? table.rowCount : 0
    }

    /** The first row from navRowNr in the given direction that is not marked for deletion,
        or -1 when there is none left that way. */
    function findLiveRow(fromRowNr, step) {
        if (fromRowNr < 0 || navRowCount <= 0)
            return -1
        for (let rowNr = fromRowNr + step; rowNr >= 0 && rowNr < navRowCount; rowNr += step) {
            if (!isRowDeleted(rowNr))
                return rowNr
        }
        return -1
    }

    function goToPreviousDocument() {
        let rowNr = findLiveRow(navRowNr, -1)
        if (rowNr >= 0)
            goToDocument(rowNr)
    }

    function goToNextDocument() {
        let rowNr = findLiveRow(navRowNr, 1)
        if (rowNr >= 0)
            goToDocument(rowNr)
    }

    function goToDocument(rowNr) {
        if (rowNr < 0 || rowNr >= navRowCount || isRowDeleted(rowNr))
            return

        // Acquire focus, if a text field is in edit mode it will commit changes
        focus = true

        if (invoice.isModified && !invoice.isReadOnly) {
            pendingAction = "goto"
            pendingNavRowNr = rowNr
            navConfirmDialog.open()
            return
        }

        loadDocument(rowNr)
    }

    /** Opens a brand new document at the end of the same table, as the Invoices table does
        when a document is created on an empty row. It is a row of the table only once it
        has been saved, so the arrows and Delete stay off until then. */
    function newDocument() {
        // Acquire focus, if a text field is in edit mode it will commit changes
        focus = true

        if (invoice.isReadOnly)
            return

        if (invoice.isModified) {
            pendingAction = "new"
            navConfirmDialog.open()
            return
        }

        loadNewDocument()
    }

    function loadNewDocument() {
        let tabPos = invoice.tabPos
        if (!tabPos)
            return

        // At the end of the table, which is where a saved new document is added.
        tabPos.rowNr = getNavTableRowCount()

        invoice.beginNewDocument()

        let invoiceObj = InvoiceJs.invoiceCreateNew(tabPos)

        invoice.setPosition(tabPos)
        invoice.setIsNew(true)
        invoice.setInvoice(invoiceObj)
        invoice.setIsModified(true)
        signalPositionChanged++

        wdgInvoice.updateView()
        updateTitle()

        wdgInvoice.notify(invoice.isEstimate() ? qsTr("New estimate") : qsTr("New invoice"))
    }

    /** Marks the open document for deletion and moves on to the one beside it. The row
        leaves the table when Banana applies the DocumentChange, once this window is
        closed - see Invoice.deleteDocument. */
    function deleteDocument() {
        // Acquire focus, if a text field is in edit mode it will commit changes
        focus = true

        if (!canDelete)
            return

        // Where to go afterwards, worked out while this row still counts as alive.
        let nextRowNr = findLiveRow(navRowNr, 1)
        if (nextRowNr < 0)
            nextRowNr = findLiveRow(navRowNr, -1)

        let deletedRowNr = navRowNr

        if (!invoice.deleteDocument())
            return

        deletedRows[rowKey(deletedRowNr)] = true
        // Whatever was saved for it is no longer worth showing: the row is going.
        delete savedDocuments[rowKey(deletedRowNr)]
        signalDeletedRowsChanged++

        if (nextRowNr < 0) {
            // Nothing left in the table to show. The deletion is in the DocumentChange and
            // is applied as the window closes.
            closeDialog()
            return
        }

        loadDocument(nextRowNr)
        wdgInvoice.notify(invoice.isEstimate() ? qsTr("Estimate deleted") : qsTr("Invoice deleted"))
    }

    /* The documents of the table, for the list that goes straight to one of them.
       Built from the columns of the row - RowId, InvoiceDate, InvoiceAddress,
       InvoiceTotalAmount - and not from the document each row carries: those columns are
       written on every save (see invoiceChangedFieldsGet) and hold exactly what the list
       shows, so a table of several hundred rows is read without opening a single one of
       them. Read once, when the list is opened: the table does not change while this
       window is open, since the operations are applied as it closes.

       Two corrections, the same two the arrows need: a row marked for deletion is left out,
       and a row saved in this session is read from what was saved rather than from the
       column, which still holds what was there before. */
    function collectDocuments() {
        let table = getNavTable()
        if (!table)
            return []

        let documents = []
        for (let rowNr = 0; rowNr < table.rowCount; ++rowNr) {
            if (isRowDeleted(rowNr))
                continue

            let saved = savedDocuments[rowKey(rowNr)]
            let entry

            if (saved) {
                entry = {
                    'rowNr': rowNr,
                    'dueDate': saved.payment_info && saved.payment_info.due_date ?
                                   saved.payment_info.due_date : "",
                    // Only the row knows: the payment date is a column of the table, it is
                    // not part of the document.
                    'paymentDate': table.value(rowNr, "InvoiceDatePayment"),
                    'number': saved.document_info.number ? saved.document_info.number : "",
                    'date': saved.document_info.date ? saved.document_info.date : "",
                    'customer': InvoiceJs.invoiceCustomerAddressBriefDescriptionGet(saved),
                    'description': saved.document_info.description ? saved.document_info.description : "",
                    'amount': saved.billing_info.total_to_pay ? saved.billing_info.total_to_pay : "",
                    'currency': saved.document_info.currency ? saved.document_info.currency : ""
                }
            } else {
                entry = {
                    'rowNr': rowNr,
                    'dueDate': table.value(rowNr, "InvoiceDateExpiration"),
                    'paymentDate': table.value(rowNr, "InvoiceDatePayment"),
                    'number': table.value(rowNr, "RowId"),
                    'date': table.value(rowNr, "InvoiceDate"),
                    'customer': table.value(rowNr, "InvoiceAddress"),
                    'description': table.value(rowNr, "Description"),
                    'amount': table.value(rowNr, "InvoiceTotalAmount"),
                    'currency': table.value(rowNr, "Currency")
                }
            }

            // A row with nothing on it is a row of the table all the same, but there is
            // nothing to show for it and nothing to search it by.
            if (!entry.number && !entry.customer && !entry.description)
                continue

            documents.push(prepareDocumentEntry(entry))
        }

        return documents
    }

    /** Puts the dates and the amounts of one entry the way they are read, and builds the
        one string the search is matched against. */
    function prepareDocumentEntry(entry) {
        let date = entry.date ? entry.date.split("T")[0] : ""
        let localeDate = date ? Banana.Converter.toLocaleDateFormat(date) : ""
        let localeAmount = entry.amount ? Banana.Converter.toLocaleNumberFormat(entry.amount) : ""

        // How the invoice stands, for the list and for the filter. Only invoices: an
        // estimate is never paid, and a file whose table has no payment date column cannot
        // say - in both cases the state is left empty and the filter is not offered.
        let paid = Boolean(entry.paymentDate)
        /* Never called "state": a delegate of the list is an Item, and every Item already
           has a property of that name - the one its state machine uses. A model role called
           "state" is quietly ignored, the delegate reads Item.state instead, and the cell
           stays empty for ever without a word of warning. */
        let paymentState = ""
        if (canTellPaidState && !paid) {
            let dueDate = entry.dueDate ? entry.dueDate.split("T")[0] : ""
            paymentState = dueDate ? InvoicesOpenJs.invoicesOpenStateText({
                                  'dueDate': dueDate,
                                  'daysLate': Math.max(0, InvoicesOpenJs.invoicesOpenDaysBetween(
                                                  dueDate, InvoicesOpenJs.invoicesOpenToday()))
                                     })
                                   : ""
        }

        return {
            'rowNr': entry.rowNr,
            'number': entry.number ? entry.number : "",
            'date': localeDate,
            'customer': entry.customer ? entry.customer : "",
            'amount': entry.currency ? (entry.currency.toUpperCase() + " " + localeAmount)
                                     : localeAmount,
            'paid': paid,
            'paymentState': paymentState,
            'isLate': paymentState.length > 0 && entry.dueDate &&
                      InvoicesOpenJs.invoicesOpenDaysBetween(
                          entry.dueDate.split("T")[0], InvoicesOpenJs.invoicesOpenToday()) > 0,
            'isCurrent': entry.rowNr === navRowNr,
            // What the typing is matched against: everything the entry shows, plus the
            // object of the document, which is worth finding by even though the list has
            // no room to show it.
            'search': [entry.number, localeDate, entry.customer, entry.description,
                       localeAmount].join(" ")
        }
    }

    /* True when this table can say what has been paid: the Invoices table, in a file whose
       Invoices table has the payment date column. Estimates are never paid. */
    readonly property bool canTellPaidState: {
        if (!invoice.tabPos || invoice.tabPos.tableName !== "Invoices")
            return false
        return InvoicesOpenJs.invoicesPaymentDateColumnExists()
    }

    function openGoToDocument() {
        // Acquire focus, if a text field is in edit mode it will commit changes
        focus = true
        goToDocumentDialog.openWith(collectDocuments(), navRowNr, canTellPaidState)
    }

    /** The key under which a row is remembered - see savedDocuments and deletedRows. */
    function rowKey(rowNr) {
        let tabPos = invoice.tabPos
        if (!tabPos || !tabPos.tableName)
            return ""
        return tabPos.tableName + "|" + (tabPos.listName ? tabPos.listName : "") + "|" + rowNr
    }

    /** Carries out what the question about unsaved changes was asked for. */
    function runPendingAction() {
        let action = pendingAction
        let rowNr = pendingNavRowNr
        pendingAction = ""
        pendingNavRowNr = -1

        if (action === "new") {
            loadNewDocument()
        } else if (action === "goto" && rowNr >= 0) {
            loadDocument(rowNr)
        }
    }

    function isRowDeleted(rowNr) {
        let key = rowKey(rowNr)
        return key.length > 0 && deletedRows[key] === true
    }

    function rememberSavedDocument() {
        let tabPos = invoice.tabPos
        let key = tabPos ? rowKey(tabPos.rowNr) : ""
        if (key.length > 0 && invoice.json) {
            // A copy, not the object itself: the form goes on editing the one it holds.
            savedDocuments[key] = JSON.parse(JSON.stringify(invoice.json))
        }
    }

    /** Opens the document of the given row of the same table, as if the window had been
        opened on it. Any unsaved change has already been dealt with by goToDocument(). */
    function loadDocument(rowNr) {
        let tabPos = invoice.tabPos
        tabPos.rowNr = rowNr

        let invoiceObj = null
        let isNewDocument = false

        let saved = savedDocuments[rowKey(rowNr)]
        if (saved) {
            invoiceObj = JSON.parse(JSON.stringify(saved))
        } else {
            // Read as the extension reads it when the window is opened: a row that carries no
            // document yet gets a new one, which is then waiting to be saved.
            invoiceObj = InvoiceJs.invoiceObjGet(tabPos)
            if (!invoiceObj) {
                invoiceObj = InvoiceJs.invoiceCreateNew(tabPos)
                isNewDocument = true
            }
        }

        invoice.setPosition(tabPos)
        invoice.setIsNew(isNewDocument)
        invoice.setInvoice(invoiceObj)
        // A row that carried no document yet now holds a new one, waiting to be saved -
        // unless the window is only showing documents, where nothing is ever saved.
        invoice.setIsModified(isNewDocument && !invoice.isReadOnly)
        signalPositionChanged++

        wdgInvoice.updateView()
        updateTitle()
    }

    // Data objects

    DevSettings {
        id: devSettings
    }

    AppSettings {
        id: appSettings
        devSettings: devSettings
    }

    Invoice {
        id: invoice
        onInvoiceChanged: {
            updateTitle()
        }
        onInvoiceSaved: {
            // The row of the table is now out of date - see savedDocuments.
            rememberSavedDocument()
        }
    }

    // Room the system keeps for itself on a phone: notch, status bar, gesture bar. The bars
    // and the pages move inside these margins, the backgrounds still reach the edges. Zero
    // on the desktop. Read from the root, which the host positions: an item positioned from
    // its own SafeArea would be a binding loop.
    //
    // SafeArea needs Qt 6.9 and Banana Plus carries 6.8.6, where the name is unknown and
    // reading it raised a ReferenceError per margin. typeof is the one way to ask about a
    // name that may not exist: anything else raises the error again.
    readonly property bool hasSafeArea: typeof SafeArea !== "undefined"
    readonly property real safeAreaTop: hasSafeArea ? SafeArea.margins.top : 0
    readonly property real safeAreaBottom: hasSafeArea ? SafeArea.margins.bottom : 0
    readonly property real safeAreaLeft: hasSafeArea ? SafeArea.margins.left : 0
    readonly property real safeAreaRight: hasSafeArea ? SafeArea.margins.right : 0

    // Visual content

    Rectangle {
        // Window background
        anchors.fill: parent
        color: Stylesheet.baseColor
    }

    Rectangle { // The bar above the page
        id: headerBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: headerLayout.implicitHeight + 2 * Stylesheet.defaultMargin + safeAreaTop
        height: implicitHeight
        color: Stylesheet.barColor

        Rectangle { // Divides the bar from the page below it
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Stylesheet.borderColor
        }

        ColumnLayout {
            id: headerLayout

            anchors.fill: parent
            anchors.margins: Stylesheet.defaultMargin
            anchors.topMargin: Stylesheet.defaultMargin + safeAreaTop
            anchors.leftMargin: Stylesheet.defaultMargin + safeAreaLeft
            anchors.rightMargin: Stylesheet.defaultMargin + safeAreaRight
            spacing: Stylesheet.spacingTight

            RowLayout {
                Layout.fillWidth: true
                spacing: Stylesheet.spacingBase

                StyledButton {
                    // Back off a secondary page. It takes the place of the arrows, which
                    // have nothing to walk through while Settings is open.
                    visible: window.currentPage !== window.page_invoice
                    text: "‹  " + qsTr("Back")
                    onClicked: window.currentPage = window.page_invoice
                }

                StyledButton {
                    id: previousButton
                    visible: window.currentPage === window.page_invoice
                    enabled: window.canGoPrevious
                    text: "‹"
                    Layout.minimumWidth: 40 * Stylesheet.pixelScaleRatio
                    Accessible.name: qsTr("Previous document")
                    onClicked: window.goToPreviousDocument()
                }

                StyledButton {
                    id: nextButton
                    visible: window.currentPage === window.page_invoice
                    enabled: window.canGoNext
                    text: "›"
                    Layout.minimumWidth: 40 * Stylesheet.pixelScaleRatio
                    Accessible.name: qsTr("Next document")
                    onClicked: window.goToNextDocument()
                }

                StyledButton {
                    // Straight to one document instead of walking to it: the arrows step,
                    // this jumps. Beside them, because it is the same business.
                    id: goToButton
                    visible: window.currentPage === window.page_invoice
                    enabled: window.navRowCount > 0
                    Layout.minimumWidth: 40 * Stylesheet.pixelScaleRatio
                    Accessible.name: qsTr("Go to document")
                    contentItem: StyledIcon {
                        name: "search"
                        color: goToButton.enabled ? Stylesheet.textColor
                                                  : Stylesheet.mutedTextColor
                    }
                    onClicked: window.openGoToDocument()
                }

                ColumnLayout { // Which document, and what state it is in
                    Layout.fillWidth: true
                    spacing: 0

                    StyledLabel {
                        Layout.fillWidth: true
                        // The name of the open document: the title of the window, so full
                        // strength and the largest thing in the bar after the total.
                        color: Stylesheet.textColor
                        font: Stylesheet.documentTitleFont
                        elide: Text.ElideRight
                        text: window.currentPageTitle
                    }

                    RowLayout { // How the document stands, and where it sits in the table
                        Layout.fillWidth: true
                        visible: window.currentPage === window.page_invoice
                        spacing: Stylesheet.spacingBase

                        Rectangle { // The state, on a ground of its own
                            visible: window.documentState.length > 0
                            implicitWidth: stateLabel.implicitWidth + 2 * Stylesheet.spacingBase
                            implicitHeight: stateLabel.implicitHeight + Stylesheet.spacingTight
                            radius: height / 2
                            color: window.documentStateIsWarning ? Stylesheet.warningSurfaceColor
                                                                 : Stylesheet.hoverColor

                            StyledLabel {
                                id: stateLabel
                                anchors.centerIn: parent
                                text: window.documentState
                                color: window.documentStateIsWarning ? Stylesheet.warningColor
                                                                     : Stylesheet.mutedTextColor
                            }
                        }

                        StyledLabel {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            elide: Text.ElideRight
                            text: window.navPositionText
                        }
                    }
                }

                StyledLabel {
                    // What the document comes to. Never shortened: when the row is too
                    // narrow the total moves to the line below instead.
                    visible: window.currentPage === window.page_invoice && !window.compactHeader
                    Layout.minimumWidth: implicitWidth
                    font: Stylesheet.totalFont
                    color: Stylesheet.accentColor
                    text: wdgInvoice.invoiceTotalText
                }

                StyledButton {
                    /* What the bars do not hold. On a narrow screen that is every command,
                       since there is no toolbar there; on the desktop only the pages of the
                       internal build, so for everyone else the button is not there at all. */
                    id: menuButton
                    visible: window.compactHeader || appSettings.isInternalVersion()
                    text: "⋮"
                    Layout.minimumWidth: 40 * Stylesheet.pixelScaleRatio
                    Accessible.name: qsTr("More commands")
                    onClicked: commandsMenu.popup(menuButton, 0, menuButton.height)
                }
            }

            StyledLabel {
                // The total on its own line, where the row above cannot hold it as well.
                visible: window.currentPage === window.page_invoice && window.compactHeader
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                font: Stylesheet.totalFont
                color: Stylesheet.accentColor
                text: wdgInvoice.invoiceTotalText
            }

            RowLayout { // The toolbar
                /* The commands of the document, out in the open where they can be seen,
                   instead of behind the ⋮ menu that held all of them. Only where there is
                   room for them: on a narrow screen the menu is still the whole of it, and
                   a row of buttons would have pushed the form off the bottom of the screen.

                   What is left in the menu is what does not earn a place here: the help,
                   and the pages that only the internal build shows. */
                id: toolBar

                visible: window.currentPage === window.page_invoice && !window.compactHeader
                Layout.fillWidth: true
                Layout.topMargin: Stylesheet.spacingTight
                spacing: 0

                /* True when the names of the commands no longer fit beside their icons and
                   the icons have to stand on their own. Measured on the room the bar has,
                   not guessed from the width of the window.

                   The threshold is what the seven names come to in a long language, which
                   is what has to fit: it cannot be measured, because the width the bar asks
                   for is itself decided by this - the labels would then turn each other on
                   and off for ever. */
                readonly property bool iconsOnly: width > 0 && width < 860 * Stylesheet.pixelScaleRatio

                StyledToolButton {
                    iconName: "new"
                    text: invoice.isEstimate() ? qsTr("New estimate") : qsTr("New invoice")
                    showLabel: !toolBar.iconsOnly
                    enabled: !invoice.isReadOnly
                    Accessible.name: text
                    onClicked: window.newDocument()
                }

                StyledToolButton {
                    iconName: "copy"
                    text: qsTr("Copy")
                    showLabel: !toolBar.iconsOnly
                    enabled: !invoice.isNewDocument
                    Accessible.name: text
                    onClicked: wdgInvoice.duplicateInvoice()
                }

                StyledToolButton {
                    iconName: "delete"
                    text: invoice.isEstimate() ? qsTr("Delete estimate") : qsTr("Delete invoice")
                    showLabel: !toolBar.iconsOnly
                    enabled: window.canDelete
                    Accessible.name: text
                    onClicked: deleteConfirmDialog.visible = true
                }

                ToolBarSeparator {}

                StyledToolButton {
                    iconName: "print"
                    text: qsTr("Print")
                    showLabel: !toolBar.iconsOnly
                    Accessible.name: text
                    onClicked: wdgInvoice.printInvoice()
                }

                StyledToolButton {
                    // Only an estimate becomes an invoice, so on an invoice this command
                    // gives up its room rather than sitting there greyed out.
                    iconName: "convert"
                    text: qsTr("Create invoice")
                    showLabel: !toolBar.iconsOnly
                    visible: invoice.isEstimate() && !invoice.isNewDocument
                    Accessible.name: text
                    onClicked: wdgInvoice.createInvoiceFromEstimate()
                }

                ToolBarSeparator {}

                StyledToolButton {
                    iconName: "settings"
                    text: qsTr("Settings")
                    showLabel: !toolBar.iconsOnly
                    Accessible.name: text
                    onClicked: window.currentPage = window.page_settings
                }

                Item {
                    // Holds the commands to the leading edge, whatever width the window
                    // has, and pushes the help to the far end.
                    Layout.fillWidth: true
                }

                StyledToolButton {
                    // On its own at the trailing end: it is about the dialog, not about the
                    // document the other commands act on.
                    iconName: "help"
                    text: qsTr("Help")
                    showLabel: !toolBar.iconsOnly
                    Accessible.name: text
                    onClicked: showHelp()
                }
            }
        }
    }

    StackLayout {
        id: pageStackLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerBar.bottom
        anchors.bottom: buttonBar.top
        anchors.leftMargin: safeAreaLeft
        anchors.rightMargin: safeAreaRight

        currentIndex: window.currentPage

        WdgInvoice {
            id: wdgInvoice
            invoice: invoice
            appSettings: appSettings
        }

        WdgSettings {
            id: wdgAppSettings
            invoice: invoice
            appSettings: appSettings
            wdgInvoice: wdgInvoice
        }

        WdgSource {
            id: wdgSource
            format: "json"
            isReadOnly: invoice.isReadOnly

            onRevertRequested: {
                wdgSource.clearError()
                text = JSON.stringify(invoice.json, null, "    ")
                isModified = false
            }

            onVisibleChanged: {
                if (visible) {
                    if (!error) {
                        text = JSON.stringify(invoice.json, null, "    ")
                    }

                } else {
                    if (isModified) {
                        try {
                            let invoiceObj = JSON.parse(text)
                            invoiceObj = JSON.parse(Banana.document.calculateInvoice(JSON.stringify(invoiceObj)));
                            invoice.json = invoiceObj
                            invoice.setIsModified(true)
                            wdgInvoice.updateView()

                        } catch (err) {
                            setError(err.message, err.lineNumber)
                            jsonErrorMessageDialog.text = err.toString()
                            jsonErrorMessageDialog.visible = true
                            error = true

                        }
                    }
                }
            }
        }

        WdgDevelopment {
            id: wdgMessages
            appSettings: appSettings
            devSettings: devSettings
            invoice: invoice
            onGoToHome: {
                window.currentPage = window.page_invoice
            }
        }

        WdgChangelog {
            text: getText()
            textFormat: TextEdit.MarkdownText
            function getText() {
                let file = Banana.IO.getLocalFile("file:script/changelog.md")
                return file.read()
            }
        }

    }

    Rectangle {
        // The bar below the page, mirroring the one above it.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: buttonBar.top
        anchors.topMargin: -Stylesheet.defaultMargin
        anchors.bottom: parent.bottom
        color: Stylesheet.barColor

        Rectangle { // Divides the bar from the page above it
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Stylesheet.borderColor
        }
    }

    RowLayout { // Save and Close, and nothing else
        id: buttonBar

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Stylesheet.defaultMargin
        anchors.bottomMargin: Stylesheet.defaultMargin + safeAreaBottom
        anchors.leftMargin: Stylesheet.defaultMargin + safeAreaLeft
        anchors.rightMargin: Stylesheet.defaultMargin + safeAreaRight

        spacing: Stylesheet.defaultMargin

        Item {
            // Pushes the two buttons to the trailing edge, where they stay whatever the
            // width of the window.
            Layout.fillWidth: true
        }

        StyledButton {
            // Allowed to shrink below its label: a cell too narrow for a long translation
            // would otherwise push the last column off the edge. The label elides instead.
            Layout.minimumWidth: 0
            text: qsTr("Save")
            primary: true
            visible: !invoice.isReadOnly
            enabled: invoice.isModified
            onClicked: {
                /* Saves and stays open. It used to close the window as well, which made
                   sense while the window served one document: now that the arrows walk
                   through the table, saving one document and going on to the next is the
                   ordinary thing to do, and closing got in the way of it.

                   Nothing reaches the file yet either way - the operations are applied by
                   Banana when the window is finally closed. */
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                if (!invoice.isReadOnly && invoice.isModified) {
                    invoice.save()
                    result = 1
                    // Saving leaves nothing on screen that says it happened: the button
                    // simply goes quiet, which is easy to miss.
                    wdgInvoice.notifySaved()
                }
            }
        }

        StyledButton {
            // Allowed to shrink below its label - see the button above.
            Layout.minimumWidth: 0
            text: invoice.isModified && !invoice.isReadOnly ? qsTr("Cancel") : qsTr("Close")
            onClicked: {
                // Acquire focus, if a text field is in edit mode it will commit changes
                focus = true
                if (invoice.isModified && !invoice.isReadOnly) {
                    cancelConfirmDialog.open()
                } else {
                    closeDialog()
                }
            }
        }
    }


    /* Divides the toolbar into the groups a command belongs to: what makes or unmakes a
       document, what sends it out, and the settings. */
    component ToolBarSeparator: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 18 * Stylesheet.pixelScaleRatio
        Layout.leftMargin: Stylesheet.spacingBase
        Layout.rightMargin: Stylesheet.spacingBase
        Layout.alignment: Qt.AlignVCenter
        color: Stylesheet.separatorColor
    }

    /* An entry of this dialog's menus, drawn in the dialog's colours: the iOS style paints
       menu backgrounds from images chosen by the application's colour scheme, which came out
       dark grey with black text in light mode, and each desktop style reads its own palette
       roles. The background needs an implicit size, or the menu appears not to open. */
    component StyledMenuEntry: MenuItem {
        id: entry

        palette.text: entry.down || entry.highlighted ? Stylesheet.accentTextColor : Stylesheet.textColor
        palette.windowText: entry.palette.text

        // An invisible menu item still reserves its row, so it has to give up its height
        // as well to disappear.
        height: visible ? implicitHeight : 0

        // The text is drawn here too, for the same reason as the background: the Material
        // style, which Android uses, takes the colour of an entry from its own theme rather
        // than from the palette, and that theme stayed light - black text on a dark menu.
        contentItem: Text {
            text: entry.text
            font: entry.font
            color: entry.down || entry.highlighted ? Stylesheet.accentTextColor :
                       entry.enabled ? Stylesheet.textColor : Stylesheet.mutedTextColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 200 * Stylesheet.pixelScaleRatio
            implicitHeight: 34 * Stylesheet.pixelScaleRatio
            color: entry.down || entry.highlighted ? Stylesheet.accentColor : "transparent"
            radius: Stylesheet.cornerRadiusSmall
        }
    }

    Menu {
        // Everything the bars do not hold. Opening the menu takes the active focus, which
        // commits whatever field was being edited.
        id: commandsMenu

        // A lighter shade in dark mode so the menu stands out from the dialog, the system
        // colours in the light theme: see Stylesheet.menuWindowColor. The palette is still
        // handed to the style for the parts it draws itself, such as a scroll indicator.
        palette.window: Stylesheet.menuWindowColor
        palette.windowText: Stylesheet.systemPalette.windowText
        palette.base: Stylesheet.menuBaseColor
        palette.text: Stylesheet.textColor
        palette.highlight: Stylesheet.accentColor
        palette.highlightedText: Stylesheet.accentTextColor

        background: Rectangle {
            implicitWidth: 220 * Stylesheet.pixelScaleRatio
            implicitHeight: 40 * Stylesheet.pixelScaleRatio
            color: Stylesheet.menuWindowColor
            border.color: Stylesheet.borderColor
            radius: Stylesheet.cornerRadius
        }

        /* The commands of the toolbar, for the narrow screen that has no toolbar. On the
           desktop they are out in the open and would be in the menu twice. */

        StyledMenuEntry {
            text: invoice.isEstimate() ? qsTr("New estimate") : qsTr("New invoice")
            visible: window.compactHeader && !invoice.isReadOnly
            onTriggered: window.newDocument()
        }

        StyledMenuEntry {
            text: invoice.isEstimate() ? qsTr("Delete estimate") : qsTr("Delete invoice")
            visible: window.compactHeader && window.canDelete
            onTriggered: deleteConfirmDialog.visible = true
        }

        StyledMenuEntry {
            text: qsTr("Print")
            visible: window.compactHeader
            onTriggered: wdgInvoice.printInvoice()
        }

        StyledMenuEntry {
            text: qsTr("Create invoice")
            visible: window.compactHeader && invoice.isEstimate() && !invoice.isNewDocument
            onTriggered: wdgInvoice.createInvoiceFromEstimate()
        }

        StyledMenuEntry {
            text: qsTr("Copy")
            visible: window.compactHeader && !invoice.isNewDocument
            onTriggered: wdgInvoice.duplicateInvoice()
        }

        StyledMenuEntry {
            text: qsTr("Settings")
            visible: window.compactHeader
            onTriggered: window.currentPage = window.page_settings
        }

        StyledMenuEntry {
            text: qsTr("Help")
            visible: window.compactHeader
            onTriggered: showHelp()
        }

        StyledMenuEntry {
            text: qsTr("Source")
            visible: appSettings.isInternalVersion()
            onTriggered: window.currentPage = window.page_source
        }

        StyledMenuEntry {
            text: qsTr("Development")
            visible: appSettings.isInternalVersion()
            onTriggered: window.currentPage = window.page_development
        }

        StyledMenuEntry {
            text: qsTr("Changelog")
            visible: appSettings.isInternalVersion()
            onTriggered: window.currentPage = window.page_changelog
        }
    }

    SimpleMessageDialog { // Error message dialog
        id: errorMessageDialog
        visible: false
        // Under the bar above on a wide window, centred on a narrow one where the top of the
        // screen belongs to the notch.
        topY: pageStackLayout.y
        centered: wdgInvoice.compactLayout
    }

    SimpleMessageDialog { // Error message dialog
        id: jsonErrorMessageDialog
        visible: false
        topY: pageStackLayout.y
        centered: wdgInvoice.compactLayout
        standardButtons: Dialog.Ok
        onAccepted: {
            window.currentPage = window.page_source
        }
    }

    SimpleMessageDialog { // Confirm discard edit dialog
        id: cancelConfirmDialog
        centered: wdgInvoice.compactLayout
        // Capped like the component's own default: this one asks for less room, but not
        // more than the window has.
        width: Math.min(300 * Stylesheet.pixelScaleRatio,
                        parent.width - 2 * Stylesheet.defaultMargin)
        height: Math.min(120 * Stylesheet.pixelScaleRatio,
                         parent.height - 2 * Stylesheet.defaultMargin)
        text: qsTr("Discard changes?")
        standardButtons: Dialog.Discard | Dialog.Cancel
        visible: false;
        onRejected: {
            cancelConfirmDialog.close()
        }
        onDiscarded: {
            closeDialog()
        }
    }

    SimpleMessageDialog { // Unsaved changes, on the way to another document
        /* Walking to another document would leave the editing of this one behind, so it is
           never decided here: saving writes an operation into the DocumentChange, and that
           is the user's to ask for. */
        id: navConfirmDialog
        centered: wdgInvoice.compactLayout
        width: Math.min(340 * Stylesheet.pixelScaleRatio,
                        parent.width - 2 * Stylesheet.defaultMargin)
        height: Math.min(140 * Stylesheet.pixelScaleRatio,
                         parent.height - 2 * Stylesheet.defaultMargin)
        text: qsTr("Save the changes before opening another document?")
        standardButtons: Dialog.Save | Dialog.Discard | Dialog.Cancel
        visible: false
        onAccepted: {
            invoice.save()
            window.runPendingAction()
        }
        onDiscarded: {
            // Nothing is written: the document is read again from its row, which is what
            // it looked like before it was edited.
            invoice.setIsModified(false)
            window.runPendingAction()
        }
        onRejected: {
            window.pendingAction = ""
            window.pendingNavRowNr = -1
            navConfirmDialog.close()
        }
    }

    SimpleMessageDialog { // Confirm the deletion of the open document
        id: deleteConfirmDialog
        centered: wdgInvoice.compactLayout
        width: Math.min(340 * Stylesheet.pixelScaleRatio,
                        parent.width - 2 * Stylesheet.defaultMargin)
        height: Math.min(150 * Stylesheet.pixelScaleRatio,
                         parent.height - 2 * Stylesheet.defaultMargin)
        text: invoice.isEstimate() ?
                  qsTr("Delete this estimate? It is removed from the table when the dialog is closed.") :
                  qsTr("Delete this invoice? It is removed from the table when the dialog is closed.")
        standardButtons: Dialog.Yes | Dialog.No
        visible: false
        onAccepted: {
            window.deleteDocument()
        }
        onRejected: {
            deleteConfirmDialog.close()
        }
    }

    DlgGoToDocument {
        id: goToDocumentDialog
        visible: false
        centered: wdgInvoice.compactLayout
        topY: pageStackLayout.y

        onDocumentChosen: function(rowNr) {
            // Through the same door the arrows use, so that unsaved changes are asked
            // about here exactly as they are there.
            window.goToDocument(rowNr)
        }
    }

    DlgPixelMetrics {
        id: pixelMetricsDialog
    }
}
