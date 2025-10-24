//
//  Constants.swift
//  Positiv
//
//  Created by DnD-Luk on 24/10/2025.
//

import Foundation

struct AppConfig {
    static let appGroup = "group.com.positivbundle.shared"

    struct Keys {
        static let countdownTitle = "countdown.title"
        static let countdownDate  = "countdown.date"
        static let countdownStart = "countdown.start"
        static let affirmations   = "affirmations"
    }

    struct WidgetKind {
        static let countdown     = "EventCountdownWidget"
        static let affirmations  = "AffirmationsWidget"
    }
}
