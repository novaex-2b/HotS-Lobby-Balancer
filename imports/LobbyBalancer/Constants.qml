pragma Singleton
import QtQuick

// Design tokens for the whole project. Every color in the scene comes from here.
QtObject {
    id: constants

    // 0 = follow the system theme, 1 = always dark, 2 = always light.
    // Change it here to preview either theme in Design Studio.
    property int themeMode: 0
    readonly property bool dark: themeMode === 0
                                 ? Qt.styleHints.colorScheme !== Qt.ColorScheme.Light
                                 : themeMode === 1

    // Everforest, medium contrast (https://github.com/sainnhe/everforest).
    //                                     dark        light
    readonly property color page:       dark ? "#232a2e" : "#efebd4"   // bg_dim
    readonly property color surface:    dark ? "#2d353b" : "#fdf6e3"   // bg0
    readonly property color raised:     dark ? "#343f44" : "#f4f0d9"   // bg1
    readonly property color hover:      dark ? "#3d484d" : "#efebd4"   // bg2
    readonly property color line:       dark ? "#475258" : "#e6e2cc"   // bg3
    readonly property color lineStrong: dark ? "#4f585e" : "#bdc3af"   // bg4 (dark) / bg5 (light)

    readonly property color text:       dark ? "#d3c6aa" : "#5c6a72"   // fg
    readonly property color muted:      dark ? "#7a8478" : "#a6b0a0"   // grey0
    // Secondary text. Dark uses grey2. Light grey2 (#829181) is too faint to read at
    // small sizes, so light uses a darker blend of fg and grey2 instead.
    readonly property color subtle:     dark ? "#9da9a0" : "#667476"

    readonly property color red:        dark ? "#e67e80" : "#f85552"
    // Red as text (warnings). Light red is too bright for text, so it is darkened.
    readonly property color redText:    dark ? "#e67e80" : "#b15e60"
    readonly property color orange:     dark ? "#e69875" : "#f57d26"
    readonly property color yellow:     dark ? "#dbbc7f" : "#dfa000"
    readonly property color green:      dark ? "#a7c080" : "#8da101"
    readonly property color aqua:       dark ? "#83c092" : "#35a77c"
    readonly property color blue:       dark ? "#7fbbb3" : "#3a94c5"
    readonly property color purple:     dark ? "#d699b6" : "#df69ba"

    // Roles
    readonly property color accent:     green
    // Hover and pressed shades of the accent (a lighter and a darker step of green)
    readonly property color accentHover: dark ? "#b8d38d" : "#9bb101"
    readonly property color accentDown:  dark ? "#91a76f" : "#7b8c01"
    readonly property color accentInk:   "#232a2e"   // dark text on green, readable in both themes
    readonly property color blueTeam:   blue
    readonly property color redTeam:    red

    // Type and shape
    readonly property int fontTitle:    20
    readonly property int fontBody:     15
    readonly property int fontTable:    14
    readonly property int fontSmall:    13
    readonly property int fontCaption:  12
    readonly property int radiusCard:   10
    readonly property int radiusControl: 7
}
