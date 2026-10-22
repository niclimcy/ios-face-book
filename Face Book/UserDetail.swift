//
//  UserDetail.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

struct UserDetail: Decodable {  // Decode only!
    let age: Int
    let gender: String
    let email: String
    let phone: String
    let birthDate: String
    let university: String
    let company: Company
    let address: Address

    struct Company: Decodable {
        let name: String
        let title: String
    }

    struct Address: Decodable {
        let address: String
        let city: String
        let state: String
        let postalCode: String
        let country: String
    }
}
