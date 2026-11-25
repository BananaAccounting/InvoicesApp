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

import "../base/settings.js" as Settings

QtObject {
    // Constants
    readonly property string settings_id: "invoices"

    /* The dialog has one single form showing every field, so there is one view left. The
       name is still the one the settings use, because the widths of the columns of the
       items table are stored under it - see WdgInvoice.saveInvoiceItemColumnWidth. */
    readonly property string view_id_full: "full"

    // Current settings data

    property bool modified: false
    property bool loaded: false
    property var data: Settings.getDefaultSettings()

    // Signals
    // Some are made available as signal and as counter
    // Use one of them and not both, if not you well get a double notifications
    // N.B.: Counters are used as signals in qml binding

    /* Emitted when the settings are loaded or replaced wholesale. The form listens to it to
       lay the items table out again, since the widths of its columns are read from here. */
    signal fieldsVisibilityChanged

    property int signalItemsVisibilityChanged: 1
    property int signalTranslationsChanged: 1
    property int signalNotificationsChanged: 1

    // Other properties
    property DevSettings devSettings: null

    // Settings methods

    function saveSettings() {
        Settings.saveSettings(data)
        modified = false
    }

    function clearSettings() {
        data = Settings.getDefaultSettings()
        modified = true
        fieldsVisibilityChanged()
    }

    function loadSettings() {
        data = Settings.getSettings()
        modified = true
        loaded = true
        fieldsVisibilityChanged()
    }

    function resetSettings() {
        data = Settings.getDefaultSettings()
        modified = true
        fieldsVisibilityChanged()
    }

    function setSettings(newSettings) {
        if (newSettings) {
            data = newSettings
            data = Settings.upgradeSettings(data)
            modified = true
            fieldsVisibilityChanged()
        }
    }

    function meetInvoiceFieldLicenceRequirement(fieldId) {
        if (!fieldId) {
            console.warn("function meetInvoiceFieldLicenceRequirement, parameter 'fieldId' is empty")
        }

        let fieldsRequiringAvancedPlan = getSettingsRequiringAdvancedPlan().appearance;
        if (fieldsRequiringAvancedPlan.indexOf(fieldId) >= 0) {
            if (Banana.application.isInternal && devSettings &&
                    devSettings.disableAdvancedPlanLicense) {
                return false;
            }

            if (!Banana.application.license || Banana.application.license.licenseType !== "advanced") {
                return false
            }
        }
        return true
    }

    // Notifications

    function isNotificationVisible(notificationId) {
        if (signalNotificationsChanged) {
            if (data.interface.notifications && data.interface.notifications[notificationId]) {
                return true
            }
        }
        return false
    }

    function setNotificationVisible(notificationId, value) {
        if (!data.interface.notifications)
            data.interface.notifications = {}
        if (value) {
            data.interface.notifications[notificationId] = true
        } else {
            data.interface.notifications[notificationId] = false
        }
        modified = true
        signalNotificationsChanged++
    }

    // Other methods

    function isInternalVersion() {
        if (Banana.application.isInternal) {
            if (devSettings.disableIsInternalVersionFlag) {
                return false
            }
            return true
        }
        return false
    }


}
