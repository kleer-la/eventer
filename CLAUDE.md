# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KEventer is a comprehensive event management and training platform built with Rails 7.2.2 and Ruby 3.3.6. It serves as the backend for Kleer's public website, managing courses, calendars, registrations, and educational content delivery. The platform supports both online and classroom-based training with robust participant management, content delivery, and business intelligence capabilities.

## Development Environment Setup

**IMPORTANT**: All Rails commands must be executed inside the devcontainer, not on the host Ubuntu system.

### Accessing the Devcontainer
The Rails application runs inside a Docker devcontainer. You cannot execute Rails commands directly from the Ubuntu host.

### Common Development Commands (Inside Devcontainer)

### Setup and Dependencies
```bash
bundle install                    # Install Ruby dependencies
rails db:migrate                  # Run database migrations
rails db:seed                     # Load initial data
rails db:test:prepare             # Prepare test database
```

### Testing
```bash
bundle exec rake ci               # Run fast tests (exclude slow tests)
bundle exec rake slow_tests       # Run slow tests only
bundle exec rake spec             # Run all RSpec tests
bundle exec rake spec SPEC=<path> # Run specific test file
# Note: Cucumber features are currently broken
```

### Development Server
```bash
rails s -b 0                     # Development server without SSL
rails s -b 'ssl://0:3000?key=localhost.key&cert=localhost.crt'  # With SSL
./runserver.sh                   # Start with environment variables loaded
```

### Database Operations
```bash
RAILS_ENV=test rails db:migrate   # Run migrations in test environment
rails db:schema:dump             # Generate schema file
```

### Code Quality
```bash
rubocop                          # Ruby linting
brakeman                         # Security analysis
```

## Core Application Architecture

### Business Domain: Event Management & Training Platform

The application manages a complex event ecosystem with the following key components:

#### Core Models and Relationships

**Event Management (Primary Business Logic)**
- **Event**: Central entity representing training sessions/courses
  - Complex pricing with early bird discounts, volume pricing, and coupon system
  - Multiple trainers support (primary, trainer2, trainer3)
  - Multi-modal delivery (classroom, online, blended)
  - Timezone support and sophisticated scheduling

- **EventType**: Course templates/definitions with multi-language support
  - Categories system for content organization
  - Recommendation engine integration via `Recommendable` concern
  - Platform enum: keventer, academia

- **Participant**: Registration and lifecycle management
  - Status workflow: New → Contacted → Confirmed → Attended → Certified
  - Payment tracking, ratings, and feedback collection
  - Certificate generation and batch import capabilities

**Content Management**
- **Article**: Blog posts and educational content with SEO optimization
- **Resource**: Educational materials (books, infographics, assessments, videos)
- **Service**: Professional services offered beyond events
- **Podcast**: Audio content with Spotify/YouTube integration

**Geographic & Marketing**
- **Country/InfluenceZone**: Geographic organization and participant segmentation
- **Campaign/CampaignSource**: Marketing attribution and analytics
- **Coupon**: Discount and promotion system

**Assessment System**
- **Assessment/Question/QuestionGroup**: Quiz and evaluation framework
- Multi-level assessment structure for complex evaluations

#### Key Architectural Patterns

1. **Multi-language Support**: Spanish/English throughout (lang fields, separate content)
2. **Recommendation Engine**: `Recommendable` concern connects EventTypes, Articles, Resources, Services
3. **Image Management**: `ImageReference` concern tracks image usage across models
4. **Geographic Segmentation**: Country → InfluenceZone hierarchy
5. **Complex Pricing Logic**: Early bird, volume discounts, coupon integration
6. **Event Lifecycle Management**: Full participant journey from registration to certification

### Key Controllers and Features

- **ActiveAdmin**: Admin interface for content management
- **API**: RESTful endpoints for external integrations (v3 namespace for latest)
- **Marketing Dashboard**: Campaign tracking and analytics
- **Participant Management**: Registration, communication, and certification
- **Content Delivery**: Multi-format educational content

### Environment Configuration

- Environment variables loaded from `eventer.env` (see `eventer.env.template`)
- SSL certificates for HTTPS development (`localhost.key`, `localhost.crt`)
- AWS S3 integration for file storage
- New Relic monitoring
- Xero integration for invoicing

### Development Environment

- **Host OS**: Windows with WSL2 (Ubuntu)
- **Containerization**: Docker + devcontainer
- **IDE**: VS Code with Remote-Containers extension
- **Runtime**: Rails application runs inside Docker container
- **Database**: SQLite (development), PostgreSQL (staging/production on Heroku)

### Testing Strategy

- RSpec for unit and integration tests
- SimpleCov for test coverage
- Separate fast/slow test suites for CI optimization
- Factory Bot for test data generation
- Note: Cucumber feature tests are currently broken

### Development Tools

- **Debugging**: `debug` gem for interactive debugging
- **Performance**: `derailed_benchmarks`, `stackprof`
- **Code Quality**: `rubocop`, `brakeman`
- **IDE Support**: `ruby-lsp`, `solargraph`

## Development Recommendations

### TDD Development Approach
- **Test-First Development**: Write tests before implementing functionality
- **Small Increments**: Make small, focused changes that can be easily tested and verified
- **Step-by-Step Process**: Break down complex features into smaller, testable units
- **Red-Green-Refactor Cycle**: Write failing test → Make it pass → Refactor code

### Outside-In Development Strategy
- **Start with Integration Tests**: Begin with high-level RSpec feature tests
- **Work Inward**: Progress from controller tests to model tests to implementation
- **Null Infrastructure**: Use test doubles and mocks to isolate business logic from external dependencies
- **Focus on Behavior**: Test what the system does, not how it does it

## Important Notes

- The application uses ActiveRecord with sophisticated associations and concerns
- Multi-tenant-like behavior through Country/InfluenceZone segmentation
- Complex business logic around pricing, discounts, and participant lifecycle
- Rich content management with recommendation algorithms
- Extensive use of Rails conventions and patterns
- Strong emphasis on internationalization and localization