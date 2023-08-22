# Changelog

## 2023-07-25

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

Changes availables only with BananaPlus version 10.1.9 or newer.

* [Enhancement] Let print two or more invoices together
* [Enhancement] Add new items with Ctrl + Enter

## 2023-07-21

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

Changes availables only with BananaPlus version 10.1.7 or newer.

* [Fix] Fix discount percentage is not showed in the printed invoice

## 2023-07-18

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

Changes availables only with BananaPlus version 10.1.7 or newer.

* [Fix] Fix vat is calculated even when vat mode set to no vat
* [Fix] Fix after setting decimals to 4 digits totals remain with 2 digits
* [Fix] Fix in settings tab the option's switchs are not visibles when the dialog is resized
* [Fix] Fix in invoice dialog the move item down button is not active
* [Fix] Fix moving up / down an item create an invalid item object
* [Fix] Fix creating an invoice from an estimate doesn't update the due date (payment term)
* [Fix] Fix the due date can't be left empty
* [Fix] Fix in settings tab the vertical scrollbar has to be always visible
* [Fix] Fix wrong dialog title for estimates
* [Fix] Fix wrong translation for Dutch language in invoice dialog

## 2023-04-17

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

* [Fix] Fix with BananaPlus RC (Qt 6.5) it is not possible to enter in edit in text fields over the table header.

## 2023-04-05

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

* [Fix] Fix the invoice discount entered as percentage is set vat inclusive even if the invoice is vat exclusive.

## 2023-04-03

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

Changes availables only with the latest BananaPlus Insider version (10.0.13.340 or newer).

* [Fix] Fix error opening dialog with Qt6.6
* [Fix] Fix vat total not showed in the invoice dialog

## 2022-12-14

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

* Fix crash when closing invoice dialog (this error occured only with the latest BananaPlus Insider version 10.0.13.340 or newer).

## 2022-12-06

* [RELEASE STABLE] Released as Stable
* [RELEASE DEV] Released as Dev

Common changes:

* [Fix] Fix changing from incl vat to excl vat or vice versa should not change the unit price.
 This could be correct from a develop point of view to update the unit price, 
 but from a user point of view this is not logical and a cause of errors.
* [Fix] Fix entering the customer does't visualize the corresponding customer entry
* [Fix] Apply changes to new documents settings to the current document
 User expect that changes in the settins tab also update the settings of the currente invoice.
* [Fix] Other small fixes and enhancements.
* [Enhancement] New setting default, the default vat code is set to per default to all new invoice items.
* [Enhancement] Adapt to Qt6

Changes availables only with the latest BananaPlus Insider version (10.0.13.340 or newer).

* [Fix] Fix progressive estimates and invoices number with alpha-numeric formats like "INV034" or "2022-034"
* [Enhancement] Simplify and reorganize views for new files
  * Only the views Base and Full are visible per default
  * The available views are called Base, Custom 1, Custom 2 and Full
  * The field Begin text is visible per default
  * The address fields Prefix, Extra and PO and visible per default
  * The items columns Quantitiy and Unit price are visible per default
  * The field deposit is visible per default
  * For existing files those settings remain unchanged
* [Enhancement] Remove field Customer reference (custom fields are used instead)
* [Enhancement] Separate fields Phone/Email and Vat-/Fiscal-Number
* [Enhancement] Let open protected invoices and estimates in read only mode
 
## 2022-09-21

* [Fix] Fix invoice number is not udpated when changed in the invoice / estimates table

## 2022-09-19

* [Fix] Fix error opening invoice editor when new invoice title is empty

## 2022-06-30

* [RELEASE DEV] Released as Dev
* [Fix] Fix number input in locale format does not validate

## 2022-05-11

* [RELEASE DEV] Released as Dev
* [Fix] Fix percentages without decimals include a dot '.' in the print (ex.: 30.%)

## 2022-03-31

* [RELEASE STABLE] Released as Stable
* [Fix] Fix the language of the invoice title is not that of the document
* [Fix] Fix the language of the invoice title is not updated when changing the language
* [Fix] Fix the language of the invoice title is not updated when changing the customer
* [Enhancement] Show extension's version in the notification bar message
* [Enhancement] Add fields for business units names (advanced plan)

## 2022-03-08

* [Fix] Update chinese translations

## 2022-02-10

* [RELEASE STABLE] Released as Stable
* [FIX] Fix article search is case sensitive
* [FIX] Fix highlight in the combo box, the item that match completely of partially the entered text is not highlighted
* [FIX] Fix can not clear the item quantity, the user can not enter an item as description (quantity and price empty)
* [FIX] Fix quantity for articles without price is set to 1, the user can not use predefined articles as description (quantity and price empty)

## 2022-02-08

* [RELEASE STABLE] Released as Stable
* [FIX] Fix button create invoice does not create any invoice
* [FIX] Fix button duplicate invoice does not create any invoice

## 2022-02-07

* [RELEASE STABLE] Released as Stable
* [FIX] Fix save button not working due to a property missing in the invoice document
* [FIX] Fix text fields doesn't automatically scroll horizontally, edited text beyond the field's with is not visible
* [TODO] Fix overwrapping article's descriptions that span over more lines

## 2022-02-01

* [RELEASE STABLE] Released as Stable
* [FIX] Add payment date to invoice json to determine if an invoice is paid

## 2022-01-31

* [RELEASE BETA] Released as Beta
* [FIX] Fix language, currency and contacts combobox were empty and did not show the current values
* [FIX] Fix text in contacts combobox was deleted while entering text
* [FIX] Changes in custom fields text was not immediately take over


## 2022-01-27

* [FIX] Fix some italian translations

## 2022-01-27

* [RELEASE BETA] Released as Beta
* [ENHANCEMENT] Show a notification to the user when an updated extension is installed

## 2022-01-25

* [BUG] Fix vat code V0 in invoice's items table is not pre-selected in the combo box
* [ENHANCEMENT] Show in invoice dialog the total for the vat rate 0%
* [ENHANCEMENT] Show in translations dialog at least the mains languages german, italian, french and english

## 2022-01-17

* [BUG] Fix some translations

## 2022-01-12

* [BUG] Fix changes to application's setting vat mode are not saved
* [BUG] Fix first item of news invoices has the item number set as the invoice number
* [BUG] Fix changes to invoice items vat rates are not saved
* [BUG] Fix vat number and fiscal number are not resumed from the contact table
* [BUG] Fix invoice (or estimate) progessive number doesn't consider archived documents

## 2021-12-23

* [BUG] Fix article's unit price is resumed resumed in the invoice dialog with 4 decimals instead of 2 decimals

## 2021-12-22

* [BUG] Fix invoice number in the description of new invoices
* [BUG] Fix invoice language was not correctly resumed from the contact table
* [BUG] Fix invoice without a valid language is not printed

## 2021-12-09

* [BUG] Fix F6 (Cmd-6) on Invoice Id column skip a number
* [Enhancement] For new item rows the inserted default quantity is "1" instead of "1.00"
* [BUG] Fix invoice language is not updated when a contact is selected from the combo box
* [Enhancement] Add a dialog to show the display properties and the applied pixel ratio (Ctrl+Alt+9, Cmd+ALt+9 on macOS)
* [BUG] Fix custom fields descriptions are not updated while printing
* [BUG] Fix empties custom fields remain in the printing
* [BUG] Fix key F9 create new invoices on empty rows
* [BUG] Fix supplier info are not updated in the invoice and in the print out

## 2021-11-23

* [Enhancement] Let search items by description
* [Enhancement] Let search customers by name, address, email or fiscal number
* [Enhancement] Add customer fields to the invoice
* [Enhancement] Check entered dates and notify the user if the date is not valid
* [Bug] Fix the entered item date is not saved
* [Bug] Fix tab key on field item quantity does not save the edited text
* [Bug] Fix textes and translations

## 2021-10-13

* First beta release

### Main changes

* [Enhancement] Add in the items the discount column (require advanced plan)
* [Enhancement] Add in the items the date column (require advanced plan)
* [Enhancement] Let insert items quantity and unit price with 4 or more decimals
* [Enhancement] Let insert multi line text in the item's description
* [Enhancement] Let insert multi line text in the invoice's begin text
* [Enhancement] Let choose which invoice's fields are visibles
* [Enhancement] Let choose which item's columns are visibles
* [Enhancement] Let insert bold text in item's description, invoice's begin text and invoice's end text
* [Enhancement] Let set the title for new invoices and estimates
* [Enhancement] Add views to the dialog
* [Bug] Resolves an issue where text changes sometimes were not applied if the enter key was not pressed
* [Bug] Resolves an issue related to clipped text fields on hdpi monitors under window

### Other changes

* [Enhancement] Add address fields Postbox and Extra
* [Enhancement] Add address fields Postbox and Extra
* [Enhancement] Add smart fill to the customer language column
* [Enhancement] Add in the edit invoice dialog the languages spanish, portuguese, russia, dutch and chinese
* [Enhancement] Add in the edit invoice dialog all the languages present in the customer table (user defined languages)
* [Enhancement] Add help button to dialogs;
* [Enhancement] In the edit invoice dialog the width of invoice details fields grows with the widht of the dialog;
* [Enhancement] In the edit invoice dialog the height of invoice articles a grows with the height of the dialog;
* [Enhancement] The dimension of the invoice dialog is saved and restored at the next opening (require the last version of Banana Accounting);
* [Enhancement] Support dynamic switch to dark mode
* [Enhancement] Add the invoice / estimate total to the dialog's top right corner
* [Bug] Fix textes and translations

### To do

* [Enhancement] Simplify the search of customers and articles
* [Enhancement] Allow to add customer fields to the invoice
* [Enhancement] Allow to print remainders
* [Enhancement] Allow to print delivery note
* [Enhancement] Add status to the invoice (draft, sent, remainder1, canceled, ...)
* [Enhancement] Allow to to insert totals and subtotals of items


## 2021-08-24

* [Bug] Fix under macOs dark mode item's texts are not visible;

## 2021-03-16

* [Bug] Prints amounts for items without price (0.00) but with quantity

## 2021-02-03

* [Enhancement] Doesn't prints amounts for items used as notes (items without price)

## 2021-01-18

* [Bug] Fix error invoiceObj is not defined in command duplicate;

## 2021-01-13

* [Bug] Fix translations errors;

## 2020-12-01

* [Enhancement] Add fields for deposit's amount and deposit's description;

## 2020-11-26

* [Bug] Fix changing invoice's notes in the dialog will not update the Note's field in the invoice's table;
* [Bug] Fix creating a new invoice doesn't set the expiring date;

## 2020-11-18

* [Bug] Fix when adding an item to the invoice, the item's price is set to amount_vat_exclusive or amount_vat_inclusive depending on invoice's settings;

## 2020-10-27

* [Enhancement] Add copy and paste of invoice's rows;

