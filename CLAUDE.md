# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepAlign is a civic engagement platform consisting of:
- **Backend**: NestJS REST API with TypeORM (PostgreSQL/SQLite)
- **Frontend**: Native iOS app built with SwiftUI and SwiftData

The platform enables citizens to connect with legislators, track congressional activity, participate in civic events, create petitions, and engage through a social feed.

## Development Commands

### Backend (NestJS)

```bash
cd backend

# Development
npm run start:dev          # Start with hot-reload
npm run start:debug        # Start with debugging
npm run build              # Build for production
npm run start:prod         # Run production build

# Testing
npm run test               # Run unit tests
npm run test:watch         # Run tests in watch mode
npm run test:cov           # Run tests with coverage
npm run test:e2e           # Run end-to-end tests

# Code Quality
npm run lint               # Lint and fix TypeScript files
npm run format             # Format code with Prettier

# Database
npm run migration:generate -- src/migrations/MigrationName  # Generate migration
npm run migration:run      # Run pending migrations
npm run migration:revert   # Revert last migration

# CLI & Seeding
npm run cli -- seed:legislators    # Seed legislators from Congress API
npm run cli -- seed:social         # Seed social features (posts, follows)
npm run cli -- seed:simple         # Simple seed for basic data
```

### Frontend (iOS/SwiftUI)

The frontend is an Xcode project. Open `frontend/RepAlign.xcodeproj` in Xcode.

- Build: Cmd+B
- Run: Cmd+R
- Clean: Shift+Cmd+K

## Architecture

### Backend Architecture

**Module Structure:**
- **AuthModule**: JWT-based authentication with Passport strategies (local, JWT). Global JWT guard applied via APP_GUARD.
- **UsersModule**: User management with dual profile system (CitizenProfile, LegislatorProfile).
- **PostsModule**: Social features (posts, comments, likes, follows, media attachments).
- **CongressModule**: Integration with Congress.gov API for bills, votes, legislators, campaign contributors.
- **FeedModule**: Aggregated feed combining posts, events, and petitions.
- **GamificationModule**: User activity tracking and points system.

**Database Configuration:**
- Supports both PostgreSQL (production) and SQLite (development)
- Database type controlled by `DATABASE_TYPE` env var
- TypeORM with explicit entity registration in `app.module.ts`
- Migrations stored in `src/database/migrations/`

**Key Patterns:**
- All entities are explicitly imported and registered in `app.module.ts` (lines 48-66)
- Global validation pipe with `transform`, `whitelist`, and `forbidNonWhitelisted`
- Rate limiting via ThrottlerModule
- Swagger documentation auto-generated in non-production environments at `/docs`
- API prefix: `api/v1` (configurable via `API_PREFIX` env var)

**CLI System:**
The backend includes a CLI system (`src/cli.ts`) using nest-commander:
- `SeedLegislatorsCommand`: Fetches and seeds legislators from Congress.gov API
- `SeedSocialFeaturesCommand`: Seeds posts, follows, and social data
- `SimpleSeedCommand`: Basic seed data
- CLI uses separate module (`cli.module.ts`) with its own TypeORM configuration

### Frontend Architecture

**Data Layer:**
- **SwiftData**: Local persistence using ModelContainer with schema defined in `RepAlignApp.swift`
- **DataSources**: Protocol-based data sources (LegislatorDataSource, FeedDataSource) with caching
- **Repositories**: Repository pattern abstracts data source selection
- **Services**: API services for backend communication (AuthService, UserService, PostsApiService, EventService, CongressAPIService)

**Data Source Strategy:**
The app uses a configurable data source (`AppConfig.dataSource`):
- `.congressAPI`: Direct Congress.gov API integration
- `.customBackend`: RepAlign backend API (default)
- `.mockData`: Local mock data for testing

**Key Components:**
- **AuthService**: Singleton managing authentication state, used by `RepAlignApp` to control root view
- **LegislatorCache**: Time-based caching with configurable refresh interval
- **MockDataProvider**: Generates mock data if database is empty on first launch
- **LegislatorMapper**: Maps between Congress API models and app models

**Views:**
- MainTabView: Tab-based navigation (Feed, Take Action, Profile)
- Auth: LoginView, RegisterView
- Feed: FeedView, FeedCard, PostDetailView
- Congress: CongressDataTestView, CongressSyncView
- Events: CreateEventView, EventDetailView, UpcomingEventsView
- Profile: ProfileView, MyProfileView, SettingsView

### Entity Relationships

**Users:**
- User (base entity) → CitizenProfile OR LegislatorProfile (discriminator pattern)
- Follow: User → User relationships
- Post → User (author)
- Comment → User (author)
- Like → User
- EventParticipant → User
- PetitionSignature → User

**Congress Data:**
- Legislator (separate from User.LegislatorProfile)
- Bill → Legislator (sponsor)
- Vote → Legislator + Bill
- CampaignContributor → Legislator

**Social & Civic:**
- Post → Media[] (attachments)
- Post → Comment[]
- Post → Like[]
- Event → EventParticipant[]
- Petition → PetitionSignature[]

## Configuration

### Backend Environment Variables

Required environment variables (see `backend/.env.example`):

**Database:**
- `DATABASE_TYPE`: "postgres" or "sqlite"
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME` (for PostgreSQL)

**Authentication:**
- `JWT_SECRET`: Secret for access tokens
- `JWT_REFRESH_SECRET`: Secret for refresh tokens
- `JWT_EXPIRATION_TIME`: Default "15m"
- `JWT_REFRESH_EXPIRATION_TIME`: Default "7d"

**Congress API:**
- `CONGRESS_API_KEY`: API key for Congress.gov
- `CONGRESS_API_BASE_URL`: Default "https://api.congress.gov/v3"

**Application:**
- `NODE_ENV`: "development" or "production"
- `PORT`: Default 3000
- `API_PREFIX`: Default "api/v1"
- `FRONTEND_URL`: For CORS configuration

### Frontend Configuration

Configuration in `frontend/RepAlign/Config/AppConfig.swift`:
- `dataSource`: Switch between congressAPI, customBackend, mockData
- `backendBaseURL`: Backend API endpoint (default: http://localhost:3000/api/v1)
- `congressAPIKey`: Congress.gov API key
- `cacheRefreshInterval`: 24 hours default
- `maxCacheAge`: 7 days default

## Testing Notes

- Backend tests use Jest with ts-jest transformer
- Test files: `**/*.spec.ts`
- No e2e tests currently configured (`test/jest-e2e.json` missing)
- Controllers have `.spec.ts` files (e.g., `congress.controller.spec.ts`, `users.controller.spec.ts`)

## Important Development Notes

1. **Entity Registration**: When adding new entities, explicitly register them in BOTH:
   - `app.module.ts` (entities array in TypeOrmModule.forRootAsync)
   - `cli.module.ts` (if CLI commands need access)

2. **Authentication**: JWT guard is globally applied via APP_GUARD in AuthModule. Use `@Public()` decorator (if implemented) for public endpoints.

3. **Database Migrations**: Always generate migrations for schema changes in production. Don't rely on `synchronize: true`.

4. **Congress API Integration**: The backend includes CongressApiService for fetching legislator data. Use CLI commands for bulk data import.

5. **iOS App Data**: The iOS app uses SwiftData for local persistence and can switch between backend API and mock data via AppConfig.

6. **CORS**: Backend CORS is configured to allow iOS app schemes (`capacitor://localhost`, `ionic://localhost`) for native app integration.
