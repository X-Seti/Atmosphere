// Belongs in ..contents/ui/config/ConfigDiary.qml
/*
 * X-Seti - Jan 25 2025 - Addons for Weather Widget Plus (Credit - Martin Kotelnik)
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.5 as Kirigami

Item {
    property alias cfg_diaryLoggingEnabled: diaryLoggingCheckBox.checked
    property alias cfg_diaryAutoPopupEnabled: autoPopupCheckBox.checked
    property alias cfg_diaryAutoPopupHour: autoPopupHourSpinBox.value
    property alias cfg_diaryLayoutType: layoutTypeComboBox.currentIndex
    property alias cfg_diaryEditorType: editorComboBox.currentIndex
    property alias cfg_diaryCustomEditor: customEditorField.text

    Kirigami.FormLayout {

        CheckBox {
            id: diaryLoggingCheckBox
            text: "Enable diary logging"
            Kirigami.FormData.label: "Diary:"
        }

        ComboBox {
            id: layoutTypeComboBox
            model: ["Compact", "Detailed", "Markdown"]
            Kirigami.FormData.label: "Layout:"
            enabled: diaryLoggingCheckBox.checked
        }

        ComboBox {
            id: editorComboBox
            model: ["Kate", "Pluma", "Other"]
            Kirigami.FormData.label: "Editor:"
        }

        TextField {
            id: customEditorField
            placeholderText: "Custom editor command"
            visible: editorComboBox.currentIndex === 2
            Kirigami.FormData.label: "Custom editor:"
        }

        CheckBox {
            id: autoPopupCheckBox
            text: "Enable automatic daily popup"
            Kirigami.FormData.label: "Popup:"
        }

        SpinBox {
            id: autoPopupHourSpinBox
            from: 0
            to: 23
            Kirigami.FormData.label: "Popup hour:"
            enabled: autoPopupCheckBox.checked
        }

        Label {
            text: "Popup appears once per day at the selected hour (24-hour clock)."
            wrapMode: Text.Wrap
            opacity: 0.7
            Kirigami.FormData.isSection: true
        }
    }
}
