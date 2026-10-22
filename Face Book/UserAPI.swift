//
//  UserAPI.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

import Foundation

class UserAPI {
    struct UsersPage {
        let users: [SimplifiedUser]
        let total: Int
    }

    enum UserAPIError: Error {
        case invalidURL
        case httpStatus(Int)
    }

    private struct Response: Decodable {
        let users: [SimplifiedUser]
        let total: Int
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    enum Gender: String, CaseIterable {
        case male
        case female

        var title: String { rawValue.capitalized }
    }

    func fetchUsers(
        query: String? = nil,
        gender: Gender? = nil,
        skip: Int? = nil
    ) async throws -> UsersPage {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dummyjson.com"
        components.queryItems = [URLQueryItem(name: "limit", value: "10")]
        if let query {
            components.path = "/users/search"
            components.queryItems?.append(URLQueryItem(name: "q", value: query))
        } else if let gender {
            components.path = "/users/filter"
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "key", value: "gender"),
                URLQueryItem(name: "value", value: gender.rawValue),
            ])
        } else {
            components.path = "/users"
        }

        if let skip {
            components.queryItems?.append(
                URLQueryItem(name: "skip", value: String(skip))
            )
        }

        guard let url = components.url else { throw UserAPIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
            !(200...299).contains(httpResponse.statusCode)
        {
            throw UserAPIError.httpStatus(httpResponse.statusCode)
        }

        let res = try JSONDecoder().decode(Response.self, from: data)
        return UsersPage(users: res.users, total: res.total)
    }
}
