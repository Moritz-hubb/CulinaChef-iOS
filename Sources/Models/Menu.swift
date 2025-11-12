import Foundation

struct Menu: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let user_id: String
    let title: String
    let created_at: String?
}
