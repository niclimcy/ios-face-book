//
//  SimplifiedUser.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

import Foundation

struct SimplifiedUser: Decodable {  // Decode only!
    let id: Int
    let fullName: String  // Computed from firstName + lastName
    let profileImage: String  // Renamed from "image" in JSON
    let city: String  // Extracted from nested address
    let state: String  // Extracted from nested address

    // This enum maps JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case id  // When case name = raw value, you can omit the string
        case firstName  // We need these to compute fullName
        case lastName
        case profileImage = "image"  // Maps JSON "image" to Swift "profileImage"
        case address  // We need this to extract city and state
    }

    // For nested objects, we need another CodingKeys enum
    enum AddressCodingKeys: String, CodingKey {
        case city
        case state
    }

    // Custom initializer to handle the decoding
    init(from decoder: Decoder) throws {
        // Get the main container using our CodingKeys
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode simple properties
        self.id = try container.decode(Int.self, forKey: .id)

        // Decode and combine firstName + lastName into fullName
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        self.fullName = "\(firstName) \(lastName)"

        // Decode with renamed key
        self.profileImage = try container.decode(
            String.self,
            forKey: .profileImage
        )

        // Decode nested address object
        let addressContainer = try container.nestedContainer(
            keyedBy: AddressCodingKeys.self,
            forKey: .address
        )
        self.city = try addressContainer.decode(String.self, forKey: .city)
        self.state = try addressContainer.decode(String.self, forKey: .state)
    }

    // folder "0/<id / 1000>", file "<id zero-padded to 6 digits>.jpg"
    var faceImageURL: URL? {
        let fileName = String(format: "%06d", id)
        let folder = id / 1000

        return URL(
            string:
                "https://raw.githubusercontent.com/ozgrozer/100k-faces/refs/heads/master/docs/0/\(folder)/\(fileName).jpg"
        )
    }
}
