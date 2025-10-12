import Foundation

// MARK: - Congress API Service
class CongressAPIService {
    private let baseURL = AppConfig.shared.congressAPIBaseURL
    private let apiKey = AppConfig.shared.congressAPIKey
    private let currentCongress = AppConfig.shared.currentCongress

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public Methods

    func fetchHouseMembers() async throws -> [CongressMember] {
        let endpoint = "/member/congress/\(currentCongress)"
        let queryItems = [
            URLQueryItem(name: "currentMember", value: "true"),
            URLQueryItem(name: "chamber", value: "house"),
            URLQueryItem(name: "limit", value: "250")
        ]

        return try await fetchMembers(endpoint: endpoint, queryItems: queryItems)
    }

    func fetchSenateMembers() async throws -> [CongressMember] {
        let endpoint = "/member/congress/\(currentCongress)"
        let queryItems = [
            URLQueryItem(name: "currentMember", value: "true"),
            URLQueryItem(name: "chamber", value: "senate"),
            URLQueryItem(name: "limit", value: "250")
        ]

        return try await fetchMembers(endpoint: endpoint, queryItems: queryItems)
    }

    func fetchMember(bioguideId: String) async throws -> CongressMember {
        let endpoint = "/member/\(bioguideId)"

        let response: CongressMemberDetailResponse = try await performRequest(
            endpoint: endpoint,
            queryItems: []
        )

        return response.member
    }

    func fetchMembersByState(state: String) async throws -> [CongressMember] {
        let endpoint = "/member/congress/\(currentCongress)/\(state)"
        let queryItems = [
            URLQueryItem(name: "currentMember", value: "true"),
            URLQueryItem(name: "limit", value: "250")
        ]

        return try await fetchMembers(endpoint: endpoint, queryItems: queryItems)
    }

    // MARK: - Private Methods

    private func fetchMembers(endpoint: String, queryItems: [URLQueryItem]) async throws -> [CongressMember] {
        let response: CongressMembersResponse = try await performRequest(
            endpoint: endpoint,
            queryItems: queryItems
        )

        return response.members
    }

    private func performRequest<T: Codable>(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw CongressAPIError.invalidURL
        }

        // Add API key and query parameters
        var allQueryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        allQueryItems.append(contentsOf: queryItems)
        urlComponents.queryItems = allQueryItems

        guard let url = urlComponents.url else {
            throw CongressAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add delay to respect rate limits
        try await Task.sleep(nanoseconds: UInt64(AppConfig.shared.apiRequestDelay * 1_000_000_000))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CongressAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                // Debug: Print raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw API Response for \(endpoint):")
                    print(jsonString.prefix(500)) // First 500 chars to avoid spam
                }

                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("DEBUG: Decoding error for endpoint \(endpoint)")
                print("Error details: \(error)")

                // More detailed decoding error logging
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: Expected \(type), but found different type")
                        print("Coding path: \(context.codingPath)")
                        print("Context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: \(type)")
                        print("Coding path: \(context.codingPath)")
                        print("Context: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key)")
                        print("Coding path: \(context.codingPath)")
                        print("Context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted")
                        print("Coding path: \(context.codingPath)")
                        print("Context: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error: \(error)")
                    }
                }

                throw CongressAPIError.decodingError(error)
            }
        case 401:
            throw CongressAPIError.unauthorized
        case 429:
            throw CongressAPIError.rateLimitExceeded
        default:
            throw CongressAPIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Error Types
enum CongressAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .unauthorized:
            return "Unauthorized - check your API key"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Congress API Response Models
struct CongressMembersResponse: Codable {
    let members: [CongressMember]
}

struct CongressMemberDetailResponse: Codable {
    let member: CongressMember
}

struct CongressMember: Codable {
    let bioguideId: String
    let name: CongressName
    let party: String
    let state: String
    let district: String?
    let terms: [CongressTerm]
    let depiction: CongressDepiction?
    let currentMember: Bool?

    private enum CodingKeys: String, CodingKey {
        case bioguideId
        case name
        case party = "partyName"
        case state
        case district
        case terms
        case depiction
        case currentMember
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        bioguideId = try container.decode(String.self, forKey: .bioguideId)
        party = try container.decode(String.self, forKey: .party)
        state = try container.decode(String.self, forKey: .state)
        depiction = try container.decodeIfPresent(CongressDepiction.self, forKey: .depiction)
        currentMember = try container.decodeIfPresent(Bool.self, forKey: .currentMember)

        // Handle district field that can be string or number
        if let districtString = try? container.decodeIfPresent(String.self, forKey: .district) {
            district = districtString
        } else if let districtNumber = try? container.decodeIfPresent(Int.self, forKey: .district) {
            district = String(districtNumber)
        } else {
            district = nil
        }

        // Handle name field that can be either string or object
        if let nameString = try? container.decode(String.self, forKey: .name) {
            // API returned name as string - parse it
            name = CongressName.fromString(nameString)
        } else {
            // API returned name as object - decode normally
            name = try container.decode(CongressName.self, forKey: .name)
        }

        // Handle terms structure - could be array or nested object with item array
        if let termsArray = try? container.decode([CongressTerm].self, forKey: .terms) {
            terms = termsArray
        } else if let termsObject = try? container.decode(CongressTermsContainer.self, forKey: .terms) {
            terms = termsObject.item
        } else {
            terms = []
        }
    }
}

struct CongressName: Codable {
    let first: String
    let last: String
    let middle: String?
    let suffix: String?

    var fullName: String {
        var components = [first]
        if let middle = middle {
            components.append(middle)
        }
        components.append(last)
        if let suffix = suffix {
            components.append(suffix)
        }
        return components.joined(separator: " ")
    }

    // Parse a full name string into components
    static func fromString(_ nameString: String) -> CongressName {
        let components = nameString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")

        guard components.count >= 2 else {
            // Fallback for malformed names
            return CongressName(first: nameString, last: "", middle: nil, suffix: nil)
        }

        // Common suffixes to check for
        let suffixes = ["Jr.", "Sr.", "II", "III", "IV", "V"]

        var first = components[0]
        var last = components.last ?? ""
        var middle: String? = nil
        var suffix: String? = nil

        // Check if last component is a suffix
        if suffixes.contains(last) {
            suffix = last
            if components.count >= 3 {
                last = components[components.count - 2]
            }
        }

        // Extract middle names (everything between first and last)
        if components.count > 2 {
            let middleComponents = components[1..<(components.count - 1 - (suffix != nil ? 1 : 0))]
            if !middleComponents.isEmpty {
                middle = middleComponents.joined(separator: " ")
            }
        }

        return CongressName(first: first, last: last, middle: middle, suffix: suffix)
    }
}

struct CongressTermsContainer: Codable {
    let item: [CongressTerm]
}

struct CongressTerm: Codable {
    let chamber: String
    let startYear: Int
    let endYear: Int?

    private enum CodingKeys: String, CodingKey {
        case chamber
        case startYear
        case endYear
    }
}

struct CongressDepiction: Codable {
    let imageUrl: String?

    private enum CodingKeys: String, CodingKey {
        case imageUrl
    }
}