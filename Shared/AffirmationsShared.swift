//
//  AffirmationsShared.swift
//  Prism
//
//  Created by DnD-Luk on 24/10/2025.
//

import Foundation

public struct AffirmationItem: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var text: String
    public init(id: UUID = UUID(), text: String) {
        self.id = id; self.text = text
    }
}
