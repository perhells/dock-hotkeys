import CoreGraphics

// MARK: - Key Code Table (CGKeyCode hardware scan codes, QWERTY layout)

let keyNameToCode: [String: UInt16] = [
    // Letters
    "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7,
    "C": 8, "V": 9, "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15,
    "Y": 16, "T": 17, "O": 31, "U": 32, "I": 34, "P": 35, "L": 37,
    "J": 38, "K": 40, "N": 45, "M": 46,

    // Numbers
    "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26,
    "8": 28, "9": 25, "0": 29,

    // Special keys
    "RETURN": 36, "TAB": 48, "SPACE": 49, "DELETE": 51, "ESCAPE": 53,
    "FORWARDDELETE": 117,

    // Arrow keys
    "LEFT": 123, "RIGHT": 124, "DOWN": 125, "UP": 126,

    // Function keys
    "F1": 122, "F2": 120, "F3": 99, "F4": 118, "F5": 96, "F6": 97,
    "F7": 98, "F8": 100, "F9": 101, "F10": 109, "F11": 103, "F12": 111,
    "F13": 105, "F14": 107, "F15": 113, "F16": 106, "F17": 64,
    "F18": 79, "F19": 80, "F20": 90,

    // Punctuation / symbols
    "MINUS": 27, "EQUAL": 24, "LEFTBRACKET": 33, "RIGHTBRACKET": 30,
    "SEMICOLON": 41, "QUOTE": 39, "COMMA": 43, "PERIOD": 47,
    "SLASH": 44, "BACKSLASH": 42, "GRAVE": 50,
]

// MARK: - Modifier Mapping

let modifierNameToFlag: [String: CGEventFlags] = [
    "command": .maskCommand,
    "cmd": .maskCommand,
    "shift": .maskShift,
    "option": .maskAlternate,
    "alt": .maskAlternate,
    "control": .maskControl,
    "ctrl": .maskControl,
    "fn": .maskSecondaryFn,
]
