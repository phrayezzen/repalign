# RepAlign Backend

Node.js/TypeScript backend API for RepAlign - A civic engagement platform connecting citizens with legislators.

## Architecture

- **Framework**: NestJS with TypeScript
- **Database**: PostgreSQL (primary data)
- **Cache**: Redis (sessions, caching)
- **Authentication**: JWT with refresh tokens
- **API Style**: REST + GraphQL (planned)
- **Documentation**: Swagger/OpenAPI

## Features

- 🔐 JWT Authentication with refresh tokens
- 👥 User management (Citizens & Legislators)
- 📝 Social posts and interactions
- 🏛️ Congress data integration
- 🎮 Gamification (points, badges, levels)
- 📊 Real-time features (planned)

## Project Structure

```
src/
├── auth/              # Authentication (JWT, strategies, guards)
├── users/             # User management & profiles
├── posts/             # Social features (posts, comments, likes)
├── congress/          # Congress data, bills, votes
├── gamification/      # Points, badges, activities
├── common/            # Shared utilities
├── config/            # Configuration files
└── database/          # Migrations
```

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose
- PostgreSQL 15+ (or use Docker)
- Redis 7+ (or use Docker)

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Database Services

```bash
# Start PostgreSQL and Redis with Docker
docker-compose up -d postgres redis

# Or install and run locally:
# PostgreSQL: brew install postgresql
# Redis: brew install redis
```

### 3. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# Default values work with Docker setup
```

### 4. Run the Application

```bash
# Development mode with hot reload
npm run start:dev

# Production build
npm run build
npm run start:prod
```

### 5. Verify Setup

- API: http://localhost:3000/api/v1
- Health: http://localhost:3000/api/v1
- Swagger Docs: http://localhost:3000/docs

## Database Setup

The application uses TypeORM with automatic migrations in development.

### Manual Migration Commands

```bash
# Generate new migration
npm run migration:generate -- src/database/migrations/MigrationName

# Run migrations
npm run migration:run

# Revert migration
npm run migration:revert
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `POST /auth/refresh` - Refresh access token
- `GET /auth/profile` - Get current user profile

### Users
- `GET /users` - List users (paginated)
- `GET /users/search` - Search users
- `GET /users/legislators` - Get all legislators
- `GET /users/me` - Get current user
- `PATCH /users/me` - Update current user

### Features (Coming Soon)
- Posts & Social Interactions
- Congress Data Sync
- Gamification System
- Real-time WebSocket Events

## Development

### Code Style

```bash
# Lint code
npm run lint

# Format code
npm run format

# Type checking
npm run build
```

### Testing

```bash
# Unit tests
npm run test

# Test coverage
npm run test:cov

# E2E tests
npm run test:e2e
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_HOST` | PostgreSQL host | `localhost` |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `DATABASE_USERNAME` | Database username | `repalign` |
| `DATABASE_PASSWORD` | Database password | `repalign_dev_password` |
| `DATABASE_NAME` | Database name | `repalign_dev` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `JWT_SECRET` | JWT signing secret | **(required)** |
| `JWT_REFRESH_SECRET` | Refresh token secret | **(required)** |
| `CONGRESS_API_KEY` | Congress.gov API key | **(required)** |
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` |

## iOS App Integration

The backend is designed to work seamlessly with the iOS app using the repository pattern:

1. **Update iOS App Configuration**:
   ```swift
   // RepAlign/Config/AppConfig.swift
   static let dataSource: DataSourceType = .customBackend
   static let backendBaseURL = "http://localhost:3000/api/v1"
   ```

2. **Implement BackendAPIDataSource**:
   - Already scaffolded in iOS app
   - Implements same `LegislatorDataSourceProtocol`
   - Add authentication headers
   - Handle token refresh

3. **Authentication Flow**:
   - Register/login via API
   - Store JWT tokens securely in iOS Keychain
   - Automatic token refresh

## Congress Data Integration

The backend integrates with Congress.gov API to:
- Sync all 535 current legislators
- Import voting records and bills
- Update legislator information
- Track campaign contributors

## Deployment

### Docker Production

```bash
# Build and run with Docker
docker-compose up --build api

# Or build for production
docker build -t repalign-backend .
docker run -p 3000:3000 repalign-backend
```

### Cloud Deployment

Recommended platforms:
- **AWS**: ECS + RDS + ElastiCache
- **Railway**: One-click PostgreSQL + Redis
- **Render**: Auto-deploy from Git
- **Google Cloud**: Cloud Run + Cloud SQL

## Contributing

1. Follow TypeScript and NestJS best practices
2. Write tests for new features
3. Update API documentation
4. Use conventional commit messages
5. Ensure all tests pass before submitting PR

## License

MIT License - see LICENSE file for details.