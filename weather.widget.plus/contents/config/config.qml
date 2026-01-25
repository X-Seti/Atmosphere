import QtQuick 2.2
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18n("Location")
         icon: 'preferences-desktop-location'
         source: 'config/ConfigLocation.qml'
    }
    ConfigCategory {
         name: i18n("Appearance")
         icon: 'preferences-desktop-color'
         source: 'config/ConfigAppearance.qml'
    }
    ConfigCategory {
        name: i18n("Layout")
        icon: 'preferences-desktop-theme'
        source: 'config/ConfigLayout.qml'
    }
    ConfigCategory {
        name: i18n("Desktop Effects")
        icon: 'preferences-desktop-wallpaper'
        source: 'config/ConfigEffects.qml'
    }
    ConfigCategory {
        name: i18n("Meteogram")
        icon: 'applications-science'
        source: 'config/ConfigMeteogram.qml'
    }
    ConfigCategory {
         name: i18n("Units")
         icon: 'preferences-system-time'
         source: 'config/ConfigUnits.qml'
    }
    ConfigCategory {
        name: i18n("Logging")
        icon: 'document-edit'
        source: 'config/ConfigLogs.qml'
    }
}
