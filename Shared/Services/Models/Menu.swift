//
//  Menu.swift
//

import Foundation

public struct MenuOption: Identifiable {
    var title: String?
    var icon: String?
    var type: String?
    var url: String?
    var isVisible: Bool = false
    var order: Int?
    var value: String? = nil
    var configKey: String? = nil

    public var id: String {
        configKey ?? "\(title ?? "")-\(type ?? "")-\(value ?? url ?? "")"
    }

    var action: MenuAction {
        MenuAction(type: type, value: value ?? url)
    }
}

public enum MenuAction: Equatable {
    case startOver
    case openExternalWeb(String)
    case phoneCall(String)
    case none
    case unknown(type: String, value: String?)

    init(type: String?, value: String?) {
        switch (type ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "startover":
            self = .startOver
        case "trigger external web", "link", "":
            self = value.map(MenuAction.openExternalWeb) ?? .none
        case "trigger phone call":
            self = value.map(MenuAction.phoneCall) ?? .none
        case "none":
            self = .none
        default:
            self = .unknown(type: type ?? "", value: value)
        }
    }
}
