let Genode = ./Genode.dhall

let Prelude = Genode.Prelude

let XML = Prelude.XML

let Key = < Ascii : Natural | Char : Text | Code : Natural > : Type

let Map =
      { Type =
          { keys : Prelude.Map.Type Text Key
          , mod1 : Bool
          , mod2 : Bool
          , mod3 : Bool
          , mod4 : Bool
          }
      , default = { mod1 = False, mod2 = False, mod3 = False, mod4 = False }
      }

let boolToAttr = λ(_ : Bool) → if _ then "yes" else "no"

let keyToXML =
        λ(x : Prelude.Map.Entry Text Key)
      → XML.leaf
          { name = "key"
          , attributes =
            [ merge
                { Ascii =
                      λ(_ : Natural)
                    → { mapKey = "ascii", mapValue = Prelude.Natural.show _ }
                , Char = λ(_ : Text) → { mapKey = "char", mapValue = _ }
                , Code =
                      λ(_ : Natural)
                    → { mapKey = "code", mapValue = Prelude.Natural.show _ }
                }
                x.mapValue
            , { mapKey = "name", mapValue = x.mapKey }
            ]
          }

let mapToXML =
        λ(map : Map.Type)
      → XML.element
          { name = "map"
          , attributes = toMap
              { mod1 = boolToAttr map.mod1
              , mod2 = boolToAttr map.mod2
              , mod3 = boolToAttr map.mod3
              , mod4 = boolToAttr map.mod4
              }
          , content =
              Prelude.List.map
                (Prelude.Map.Entry Text Key)
                XML.Type
                keyToXML
                map.keys
          }

let workman =
      [ Map::{
        , keys = toMap
            { KEY_ESC = Key.Ascii 27
            , KEY_1 = Key.Char "1"
            , KEY_2 = Key.Char "2"
            , KEY_3 = Key.Char "3"
            , KEY_4 = Key.Char "4"
            , KEY_5 = Key.Char "5"
            , KEY_6 = Key.Char "6"
            , KEY_7 = Key.Char "7"
            , KEY_8 = Key.Char "8"
            , KEY_9 = Key.Char "9"
            , KEY_0 = Key.Char "0"
            , KEY_MINUS = Key.Char "-"
            , KEY_EQUAL = Key.Char "="
            , KEY_BACKSPACE = Key.Ascii 8
            , KEY_TAB = Key.Ascii 9
            , KEY_Q = Key.Char "q"
            , KEY_W = Key.Char "d"
            , KEY_E = Key.Char "r"
            , KEY_R = Key.Char "w"
            , KEY_T = Key.Char "b"
            , KEY_Y = Key.Char "j"
            , KEY_U = Key.Char "f"
            , KEY_I = Key.Char "u"
            , KEY_O = Key.Char "p"
            , KEY_P = Key.Char ";"
            , KEY_LEFTBRACE = Key.Char "["
            , KEY_RIGHTBRACE = Key.Char "]"
            , KEY_ENTER = Key.Ascii 10
            , KEY_A = Key.Char "a"
            , KEY_S = Key.Char "s"
            , KEY_D = Key.Char "h"
            , KEY_F = Key.Char "t"
            , KEY_G = Key.Char "g"
            , KEY_H = Key.Char "y"
            , KEY_J = Key.Char "n"
            , KEY_K = Key.Char "e"
            , KEY_L = Key.Char "o"
            , KEY_SEMICOLON = Key.Char "i"
            , KEY_APOSTROPHE = Key.Char "'"
            , KEY_GRAVE = Key.Char "`"
            , KEY_BACKSLASH = Key.Ascii 92
            , KEY_Z = Key.Char "z"
            , KEY_X = Key.Char "x"
            , KEY_C = Key.Char "m"
            , KEY_V = Key.Char "c"
            , KEY_B = Key.Char "v"
            , KEY_N = Key.Char "k"
            , KEY_M = Key.Char "l"
            , KEY_COMMA = Key.Char ","
            , KEY_DOT = Key.Char "."
            , KEY_SLASH = Key.Char "/"
            , KEY_SPACE = Key.Char " "
            , KEY_KP7 = Key.Char "7"
            , KEY_KP8 = Key.Char "8"
            , KEY_KP9 = Key.Char "9"
            , KEY_KPMINUS = Key.Char "-"
            , KEY_KP4 = Key.Char "4"
            , KEY_KP5 = Key.Char "5"
            , KEY_KP6 = Key.Char "6"
            , KEY_KPPLUS = Key.Char "+"
            , KEY_KP1 = Key.Char "1"
            , KEY_KP2 = Key.Char "2"
            , KEY_KP3 = Key.Char "3"
            , KEY_KP0 = Key.Char "0"
            , KEY_KPDOT = Key.Char "."
            , KEY_KPENTER = Key.Ascii 10
            , KEY_KPSLASH = Key.Char "/"
            }
        }
      , Map::{
        , mod1 = True
        , keys = toMap
            { KEY_1 = Key.Char "!"
            , KEY_2 = Key.Char "@"
            , KEY_3 = Key.Char "#"
            , KEY_4 = Key.Char "\$"
            , KEY_5 = Key.Char "%"
            , KEY_6 = Key.Char "^"
            , KEY_7 = Key.Ascii 38
            , KEY_8 = Key.Char "*"
            , KEY_9 = Key.Char "("
            , KEY_0 = Key.Char ")"
            , KEY_MINUS = Key.Char "_"
            , KEY_EQUAL = Key.Char "+"
            , KEY_Q = Key.Char "Q"
            , KEY_W = Key.Char "D"
            , KEY_E = Key.Char "R"
            , KEY_R = Key.Char "W"
            , KEY_T = Key.Char "B"
            , KEY_Y = Key.Char "J"
            , KEY_U = Key.Char "F"
            , KEY_I = Key.Char "U"
            , KEY_O = Key.Char "P"
            , KEY_P = Key.Char ":"
            , KEY_LEFTBRACE = Key.Char "{"
            , KEY_RIGHTBRACE = Key.Char "}"
            , KEY_A = Key.Char "A"
            , KEY_S = Key.Char "S"
            , KEY_D = Key.Char "H"
            , KEY_F = Key.Char "T"
            , KEY_G = Key.Char "G"
            , KEY_H = Key.Char "Y"
            , KEY_J = Key.Char "N"
            , KEY_K = Key.Char "E"
            , KEY_L = Key.Char "O"
            , KEY_SEMICOLON = Key.Char "I"
            , KEY_APOSTROPHE = Key.Ascii 34
            , KEY_GRAVE = Key.Char "~"
            , KEY_BACKSLASH = Key.Char "|"
            , KEY_Z = Key.Char "Z"
            , KEY_X = Key.Char "X"
            , KEY_C = Key.Char "M"
            , KEY_V = Key.Char "C"
            , KEY_B = Key.Char "V"
            , KEY_N = Key.Char "K"
            , KEY_M = Key.Char "L"
            , KEY_COMMA = Key.Ascii 60
            , KEY_DOT = Key.Ascii 62
            , KEY_SLASH = Key.Char "?"
            }
        }
      , Map::{
        , mod2 = True
        , keys = toMap
            { KEY_A = Key.Ascii 1
            , KEY_B = Key.Ascii 22
            , KEY_C = Key.Ascii 13
            , KEY_D = Key.Ascii 8
            , KEY_E = Key.Ascii 18
            , KEY_F = Key.Ascii 20
            , KEY_G = Key.Ascii 7
            , KEY_H = Key.Ascii 25
            , KEY_I = Key.Ascii 21
            , KEY_J = Key.Ascii 14
            , KEY_K = Key.Ascii 5
            , KEY_L = Key.Ascii 15
            , KEY_M = Key.Ascii 12
            , KEY_N = Key.Ascii 11
            , KEY_O = Key.Ascii 16
            , KEY_P = Key.Ascii 9
            , KEY_Q = Key.Ascii 17
            , KEY_R = Key.Ascii 23
            , KEY_S = Key.Ascii 19
            , KEY_T = Key.Ascii 2
            , KEY_U = Key.Ascii 6
            , KEY_V = Key.Ascii 3
            , KEY_W = Key.Ascii 4
            , KEY_X = Key.Ascii 24
            , KEY_Y = Key.Ascii 10
            , KEY_Z = Key.Ascii 26
            }
        }
      , Map::{
        , mod3 = True
        , keys = toMap
            { KEY_4 = Key.Code 8364
            , KEY_A = Key.Code 228
            , KEY_S = Key.Code 223
            , KEY_I = Key.Code 252
            , KEY_DOT = Key.Code 8230
            , KEY_K = Key.Code 235
            , KEY_C = Key.Code 181
            , KEY_L = Key.Code 246
            }
        }
      , Map::{
        , mod1 = True
        , mod3 = True
        , keys = toMap
            { KEY_0 = Key.Code 8320
            , KEY_1 = Key.Code 8321
            , KEY_2 = Key.Code 8322
            , KEY_3 = Key.Code 8323
            , KEY_4 = Key.Code 8324
            , KEY_5 = Key.Code 8325
            , KEY_6 = Key.Code 8326
            , KEY_7 = Key.Code 8327
            , KEY_8 = Key.Code 8328
            , KEY_9 = Key.Code 8329
            }
        }
      ]

in  Prelude.List.map Map.Type XML.Type mapToXML workman
