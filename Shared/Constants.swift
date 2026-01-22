//
//  Constants.swift
//  Prism
//
//  Created by DnD-Luk on 24/10/2025.
//

import Foundation

struct AppConfig {
    static let appGroup = "group.com.lsimonin.prism.shared"
    static let comBgArt = "com.prismbundle.artrefresh"

    struct Keys {
        static let countdownTitle = "countdown.title"
        static let countdownDate  = "countdown.date"
        static let countdownStart = "countdown.start"
        static let affirmations   = "affirmations"
        static let artCache = "artCache"
        static let artAppearance = "artAppearance"
        static let countdownEmoji = "countdown.emoji"
    }

    struct WidgetKind {
        static let countdown     = "EventCountdownWidget"
        static let affirmations  = "AffirmationsWidget"
        static let art    = "ArtRWidget"
    }
}
