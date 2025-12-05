import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable { case system, user, assistant }
    let id: UUID
    var role: Role
    var text: String
    var imageDataBase64: String? // optional inline image for vision prompts
    var isError: Bool // marks if this message represents an error

    init(id: UUID = UUID(), role: Role, text: String, imageDataBase64: String? = nil, isError: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.imageDataBase64 = imageDataBase64
        self.isError = isError
    }
}
