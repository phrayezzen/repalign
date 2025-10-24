# RepAlign API Contract

This document defines the API contract between the frontend (SwiftUI iOS app) and the backend (NestJS API). All tests validate this contract.

## Base URL
- Development: `http://localhost:3000/api/v1`
- Production: TBD

## Authentication
Most endpoints require JWT authentication via the `Authorization: Bearer <token>` header.

## Legislators API

### GET /legislators
Get all legislators with filtering and pagination.

**Query Parameters:**
- `state` (optional): Two-letter state code
- `chamber` (optional): "house" or "senate"
- `party` (optional): Party name
- `search` (optional): Search query
- `limit` (optional, default: 50): Items per page
- `offset` (optional, default: 0): Pagination offset

**Response:**
```json
{
  "legislators": [
    {
      "id": "string (UUID)",
      "firstName": "string",
      "lastName": "string",
      "photoUrl": "string | null",
      "initials": "string | null",
      "chamber": "house | senate",
      "state": "string (2 letters)",
      "district": "string | null",
      "party": "string",
      "yearsInOffice": number,
      "followerCount": number,
      "bioguideId": "string",
      "userId": "string | null",
      "createdAt": "ISO8601 date string",
      "updatedAt": "ISO8601 date string",
      "isFollowing": boolean
    }
  ],
  "total": number,
  "limit": number,
  "offset": number,
  "hasMore": boolean
}
```

### GET /legislators/:id
Get a specific legislator by ID with related data.

**Response:**
```json
{
  "id": "string (UUID)",
  "firstName": "string",
  "lastName": "string",
  "photoUrl": "string | null",
  "chamber": "house | senate",
  "state": "string",
  "district": "string | null",
  "party": "string",
  "yearsInOffice": number,
  "followerCount": number,
  "bioguideId": "string",
  "phoneNumber": "string | null",
  "websiteUrl": "string | null",
  "officeAddress": "string | null",
  "bio": "string | null",
  "isFollowing": boolean,
  "committees": [
    {
      "id": "string (UUID)",
      "committeeName": "string",
      "role": "string"
    }
  ],
  "topDonors": [
    {
      "id": "string (UUID)",
      "name": "string",
      "type": "string",
      "amount": "string (decimal format: '10000.00')",
      "formattedAmount": "string (e.g., '$10,000')",
      "date": "ISO8601 date string"
    }
  ],
  "recentVotes": [
    {
      "id": "string (UUID)",
      "billId": "string (UUID)",
      "billTitle": "string",
      "billNumber": "string | null",
      "position": "Yes | No | Abstain | Absent",
      "timestamp": "ISO8601 date string",
      "aligned": boolean
    }
  ]
}
```

**Important:** The `amount` field in donors is a STRING, not a number, to preserve precision. Frontend Swift models expect `String`.

### GET /legislators/:id/donors
Get paginated donors for a legislator.

**Query Parameters:**
- `limit` (optional, default: 50)
- `offset` (optional, default: 0)
- `type` (optional): "individual", "pac", or "all"

**Response:**
```json
{
  "donors": [
    {
      "id": "string (UUID)",
      "name": "string",
      "type": "string",
      "amount": "string (decimal format: '10000.00')",
      "formattedAmount": "string",
      "date": "ISO8601 date string"
    }
  ],
  "total": number,
  "limit": number,
  "offset": number,
  "hasMore": boolean
}
```

### GET /legislators/:id/votes
Get paginated votes for a legislator.

**Query Parameters:**
- `limit` (optional, default: 50)
- `offset` (optional, default: 0)

**Response:**
```json
{
  "votes": [
    {
      "id": "string (UUID)",
      "billId": "string (UUID)",
      "billTitle": "string",
      "billNumber": "string | null",
      "position": "Yes | No | Abstain | Absent",
      "timestamp": "ISO8601 date string",
      "aligned": boolean
    }
  ],
  "total": number,
  "limit": number,
  "offset": number,
  "hasMore": boolean
}
```

### GET /legislators/:id/press
Get paginated press releases for a legislator.

**Query Parameters:**
- `limit` (optional, default: 50)
- `offset` (optional, default: 0)

**Response:**
```json
{
  "pressReleases": [
    {
      "id": "string (UUID)",
      "title": "string",
      "description": "string",
      "thumbnailUrl": "string | null",
      "publishedAt": "ISO8601 date string"
    }
  ],
  "total": number,
  "limit": number,
  "offset": number,
  "hasMore": boolean
}
```

### POST /legislators/:id/follow
Follow a legislator. Requires authentication.

**Response:**
```json
{
  "message": "Successfully followed legislator",
  "followerCount": number
}
```

**Error Responses:**
- 404: Legislator not found
- 409: Already following this legislator

### DELETE /legislators/:id/follow
Unfollow a legislator. Requires authentication.

**Response:**
```json
{
  "message": "Successfully unfollowed legislator",
  "followerCount": number
}
```

**Error Responses:**
- 404: Legislator or follow not found

### GET /legislators/stats
Get statistics about legislators.

**Response:**
```json
{
  "total": number,
  "senators": number,
  "representatives": number,
  "byParty": {
    "Democrat": number,
    "Republican": number,
    "Independent": number
  }
}
```

### GET /legislators/states/:state
Get all legislators from a specific state.

**Parameters:**
- `state`: Two-letter state code

**Response:**
```json
[
  {
    "id": "string (UUID)",
    "firstName": "string",
    "lastName": "string",
    "chamber": "house | senate",
    "state": "string",
    "district": "string | null",
    "party": "string",
    ...
  }
]
```

## Data Type Guidelines

### Critical Data Types
1. **Donor amounts**: MUST be strings in decimal format (e.g., "10000.00"), NOT numbers
2. **followerCount**: MUST be a number
3. **Dates**: MUST be ISO8601 formatted strings
4. **UUIDs**: All IDs are UUID strings
5. **Pagination fields**: total, limit, offset are numbers; hasMore is boolean

### Frontend (Swift) Models
The Swift models in `LegislatorService.swift` expect:
```swift
struct Donor {
    let amount: String  // NOT Double
}

struct FollowResponse {
    let followerCount: Int  // Number
}
```

## Testing

All API endpoints have comprehensive unit tests in:
- `/backend/src/congress/legislators.controller.spec.ts` - 20 passing tests

Run tests:
```bash
npm test -- legislators.controller.spec.ts
```

## Validation

All tests validate:
- Response structure matches documentation
- Data types are correct (especially donor amounts as strings)
- Pagination fields are present and correct types
- Error responses match expected status codes
- Frontend Swift models can decode the responses
