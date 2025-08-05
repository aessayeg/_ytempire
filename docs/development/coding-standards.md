# YTEmpire Coding Standards & Best Practices

This document outlines the coding standards, conventions, and best practices for the YTEmpire project.

## Table of Contents

- [General Principles](#general-principles)
- [JavaScript/TypeScript Standards](#javascripttypescript-standards)
- [React/Frontend Standards](#reactfrontend-standards)
- [Backend/API Standards](#backendapi-standards)
- [Database Standards](#database-standards)
- [Testing Standards](#testing-standards)
- [Documentation Standards](#documentation-standards)
- [Git Commit Standards](#git-commit-standards)

## General Principles

### Core Values

1. **Readability**: Code should be self-documenting
2. **Maintainability**: Easy to modify and extend
3. **Consistency**: Follow established patterns
4. **Simplicity**: Avoid over-engineering
5. **Performance**: Optimize when necessary
6. **Security**: Security-first mindset

### File Organization

```
project/
├── src/
│   ├── components/     # React components
│   ├── services/       # Business logic
│   ├── utils/          # Utility functions
│   ├── hooks/          # Custom React hooks
│   ├── models/         # Data models
│   ├── types/          # TypeScript types
│   └── constants/      # Constants and configs
├── tests/              # Test files
└── docs/               # Documentation
```

## JavaScript/TypeScript Standards

### Language Features

- Use ES6+ features (const, let, arrow functions, destructuring)
- Prefer TypeScript for new code
- Use strict mode
- Avoid `var` declarations

### Naming Conventions

```javascript
// Constants - UPPER_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3;
const API_BASE_URL = 'https://api.example.com';

// Variables and functions - camelCase
const userName = 'John';
const calculateTotalPrice = (items) => { };

// Classes and Types - PascalCase
class UserService { }
interface UserProfile { }
type ChannelData = { };

// Private methods/properties - prefix with underscore
class Service {
  private _privateMethod() { }
}

// Boolean variables - prefix with is/has/should
const isLoading = true;
const hasPermission = false;
const shouldUpdate = true;

// Async functions - suffix with Async (optional but recommended)
const fetchUserDataAsync = async () => { };
```

### Code Style

#### Variables

```javascript
// ✅ Good
const user = {
  id: 1,
  name: 'John',
  email: 'john@example.com',
};

// ❌ Bad
const user = { id: 1, name: 'John', email: 'john@example.com' };

// ✅ Use destructuring
const { id, name } = user;

// ❌ Avoid
const id = user.id;
const name = user.name;
```

#### Functions

```javascript
// ✅ Good - Arrow functions for simple operations
const double = (n) => n * 2;

// ✅ Good - Regular functions for complex logic
async function fetchUserData(userId) {
  try {
    const response = await api.get(`/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching user:', error);
    throw error;
  }
}

// ✅ Good - Default parameters
function createUser(name, role = 'user') {
  // ...
}

// ❌ Bad - Avoid nested ternaries
const status = isActive ? (isVerified ? 'active' : 'pending') : 'inactive';

// ✅ Good - Use if/else for clarity
let status;
if (!isActive) {
  status = 'inactive';
} else if (isVerified) {
  status = 'active';
} else {
  status = 'pending';
}
```

#### Async/Await

```javascript
// ✅ Good
async function processData() {
  try {
    const data = await fetchData();
    const processed = await transform(data);
    return processed;
  } catch (error) {
    logger.error('Processing failed:', error);
    throw new ProcessingError('Failed to process data', error);
  }
}

// ❌ Bad - Mixing promises and async/await
async function processData() {
  return fetchData().then((data) => {
    return transform(data);
  });
}
```

### TypeScript Specific

```typescript
// ✅ Good - Explicit types
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

// ✅ Good - Type guards
function isUser(obj: any): obj is User {
  return (
    obj &&
    typeof obj.id === 'string' &&
    typeof obj.name === 'string' &&
    typeof obj.email === 'string'
  );
}

// ✅ Good - Enums for constants
enum UserRole {
  Admin = 'ADMIN',
  User = 'USER',
  Guest = 'GUEST',
}

// ✅ Good - Utility types
type PartialUser = Partial<User>;
type UserWithoutId = Omit<User, 'id'>;
type UserId = Pick<User, 'id'>;
```

## React/Frontend Standards

### Component Structure

```jsx
// ✅ Good - Functional component with TypeScript
import React, { useState, useEffect } from 'react';
import { useUser } from '@/hooks/useUser';
import styles from './UserProfile.module.css';

interface UserProfileProps {
  userId: string;
  onUpdate?: (user: User) => void;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId, onUpdate }) => {
  const [isLoading, setIsLoading] = useState(false);
  const { user, error } = useUser(userId);

  useEffect(() => {
    // Side effects here
  }, [userId]);

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;

  return <div className={styles.container}>{/* Component JSX */}</div>;
};
```

### Component Best Practices

```jsx
// ✅ Good - Custom hooks for logic
function useChannelData(channelId) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchChannelData(channelId)
      .then(setData)
      .finally(() => setLoading(false));
  }, [channelId]);

  return { data, loading };
}

// ✅ Good - Memoization for expensive operations
const ExpensiveComponent = React.memo(({ data }) => {
  const processedData = useMemo(() => processData(data), [data]);

  return <div>{processedData}</div>;
});

// ✅ Good - Error boundaries
class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    logErrorToService(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback />;
    }
    return this.props.children;
  }
}
```

### State Management

```javascript
// ✅ Good - Redux Toolkit
import { createSlice } from '@reduxjs/toolkit';

const userSlice = createSlice({
  name: 'user',
  initialState: {
    data: null,
    loading: false,
    error: null,
  },
  reducers: {
    fetchStart: (state) => {
      state.loading = true;
    },
    fetchSuccess: (state, action) => {
      state.data = action.payload;
      state.loading = false;
    },
    fetchError: (state, action) => {
      state.error = action.payload;
      state.loading = false;
    },
  },
});
```

## Backend/API Standards

### API Route Structure

```javascript
// ✅ Good - RESTful routes
router.get('/channels', getChannels); // GET all
router.get('/channels/:id', getChannel); // GET one
router.post('/channels', createChannel); // CREATE
router.put('/channels/:id', updateChannel); // UPDATE
router.delete('/channels/:id', deleteChannel); // DELETE

// ✅ Good - Nested resources
router.get('/channels/:channelId/videos', getChannelVideos);
router.post('/channels/:channelId/videos', createChannelVideo);
```

### Error Handling

```javascript
// ✅ Good - Centralized error handling
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  const { statusCode = 500, message } = err;

  logger.error({
    error: err,
    request: req.url,
    method: req.method,
    ip: req.ip,
  });

  res.status(statusCode).json({
    status: 'error',
    message: statusCode === 500 ? 'Internal server error' : message,
  });
};

// ✅ Good - Try-catch in async routes
const getChannel = async (req, res, next) => {
  try {
    const channel = await Channel.findById(req.params.id);
    if (!channel) {
      throw new AppError('Channel not found', 404);
    }
    res.json({ data: channel });
  } catch (error) {
    next(error);
  }
};
```

### Input Validation

```javascript
// ✅ Good - Input validation with Joi
const Joi = require('joi');

const channelSchema = Joi.object({
  name: Joi.string().min(3).max(100).required(),
  description: Joi.string().max(500),
  youtubeId: Joi.string()
    .pattern(/^UC[\w-]{22}$/)
    .required(),
});

const validateChannel = (req, res, next) => {
  const { error } = channelSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      error: error.details[0].message,
    });
  }
  next();
};
```

## Database Standards

### SQL Naming Conventions

```sql
-- Tables: plural, snake_case
CREATE TABLE users (...);
CREATE TABLE channel_analytics (...);

-- Columns: snake_case
CREATE TABLE videos (
  id UUID PRIMARY KEY,
  channel_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes: idx_table_columns
CREATE INDEX idx_videos_channel_id ON videos(channel_id);
CREATE INDEX idx_videos_created_at ON videos(created_at DESC);

-- Foreign keys: fk_table_column_reference
ALTER TABLE videos
  ADD CONSTRAINT fk_videos_channel_id_channels
  FOREIGN KEY (channel_id) REFERENCES channels(id);
```

### Query Best Practices

```javascript
// ✅ Good - Parameterized queries
const user = await db.query('SELECT * FROM users WHERE email = $1', [email]);

// ❌ Bad - SQL injection vulnerable
const user = await db.query(`SELECT * FROM users WHERE email = '${email}'`);

// ✅ Good - Transaction handling
const client = await pool.connect();
try {
  await client.query('BEGIN');
  await client.query('INSERT INTO users ...');
  await client.query('INSERT INTO profiles ...');
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

## Testing Standards

### Test Structure

```javascript
// ✅ Good - Descriptive test names
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', async () => {
      // Arrange
      const userData = { name: 'John', email: 'john@example.com' };

      // Act
      const user = await userService.createUser(userData);

      // Assert
      expect(user).toHaveProperty('id');
      expect(user.name).toBe(userData.name);
      expect(user.email).toBe(userData.email);
    });

    it('should throw error for duplicate email', async () => {
      // Test implementation
    });
  });
});
```

### Test Coverage Requirements

- Unit tests: 80% coverage minimum
- Integration tests: Critical paths covered
- E2E tests: Main user journeys

## Documentation Standards

### Code Comments

```javascript
/**
 * Fetches channel analytics for a given date range
 * @param {string} channelId - YouTube channel ID
 * @param {Date} startDate - Start date for analytics
 * @param {Date} endDate - End date for analytics
 * @returns {Promise<AnalyticsData>} Channel analytics data
 * @throws {NotFoundError} If channel doesn't exist
 * @throws {ValidationError} If date range is invalid
 */
async function fetchChannelAnalytics(channelId, startDate, endDate) {
  // Implementation
}

// ✅ Good - Explain WHY, not WHAT
// Calculate retention rate using 30-day rolling average
// to smooth out weekly fluctuations
const retentionRate = calculateRollingAverage(data, 30);

// ❌ Bad - Obvious comment
// Increment counter by 1
counter++;
```

## Git Commit Standards

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Build process or auxiliary tool changes

### Examples

```bash
# ✅ Good
git commit -m "feat(auth): add OAuth2 Google authentication"
git commit -m "fix(api): handle null values in channel response"
git commit -m "docs(readme): update installation instructions"

# ❌ Bad
git commit -m "fixed stuff"
git commit -m "WIP"
git commit -m "updates"
```

## Code Review Checklist

Before submitting a PR, ensure:

- [ ] Code follows style guidelines
- [ ] Self-review performed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No console.logs or debug code
- [ ] Security considerations addressed
- [ ] Performance impact considered
- [ ] Error handling implemented
- [ ] Accessibility requirements met

---

[← Back to Documentation](../README.md) | [Git Workflow →](git-workflow.md)
