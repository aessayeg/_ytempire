# YTEmpire API Endpoints

## Overview

Complete API endpoint documentation for the YTEmpire platform.

## Base Configuration

```
Base URL: https://api.ytempire.com
Version: v1
Format: JSON
Authentication: Bearer Token (JWT)
```

## Authentication Endpoints

### POST /api/v1/auth/register

Register new user account.

**Request:**

```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "user": {...},
    "token": "jwt-token"
  }
}
```

### POST /api/v1/auth/login

Login user.

### POST /api/v1/auth/logout

Logout user.

### POST /api/v1/auth/refresh

Refresh JWT token.

### POST /api/v1/auth/forgot-password

Send password reset email.

### POST /api/v1/auth/reset-password

Reset password with token.

## User Endpoints

### GET /api/v1/users/profile

Get current user profile.

### PUT /api/v1/users/profile

Update user profile.

### PUT /api/v1/users/password

Change user password.

### DELETE /api/v1/users/account

Delete user account.

### GET /api/v1/users/subscription

Get subscription details.

### POST /api/v1/users/subscription

Update subscription plan.

## Channel Endpoints

### GET /api/v1/channels

List user channels.

**Query Parameters:**

- page (number): Page number
- limit (number): Items per page
- sort (string): Sort field
- order (string): Sort order (asc/desc)

### POST /api/v1/channels

Create new channel.

### GET /api/v1/channels/:id

Get channel details.

### PUT /api/v1/channels/:id

Update channel.

### DELETE /api/v1/channels/:id

Delete channel.

### POST /api/v1/channels/:id/sync

Sync channel with YouTube.

### GET /api/v1/channels/:id/analytics

Get channel analytics.

## Video Endpoints

### GET /api/v1/videos

List videos.

**Query Parameters:**

- channelId (string): Filter by channel
- status (string): Filter by status
- page (number): Page number
- limit (number): Items per page

### POST /api/v1/videos

Create new video.

### GET /api/v1/videos/:id

Get video details.

### PUT /api/v1/videos/:id

Update video.

### DELETE /api/v1/videos/:id

Delete video.

### POST /api/v1/videos/:id/upload

Upload video file.

### POST /api/v1/videos/:id/publish

Publish video to YouTube.

### GET /api/v1/videos/:id/analytics

Get video analytics.

## Content Generation Endpoints

### POST /api/v1/content/generate-script

Generate video script using AI.

**Request:**

```json
{
  "topic": "string",
  "style": "string",
  "length": "number",
  "keywords": ["string"]
}
```

### POST /api/v1/content/generate-title

Generate video title.

### POST /api/v1/content/generate-description

Generate video description.

### POST /api/v1/content/generate-tags

Generate video tags.

### POST /api/v1/content/generate-thumbnail

Generate thumbnail suggestions.

## Analytics Endpoints

### GET /api/v1/analytics/overview

Get analytics overview.

### GET /api/v1/analytics/channels/:id

Get channel analytics.

### GET /api/v1/analytics/videos/:id

Get video analytics.

### GET /api/v1/analytics/revenue

Get revenue analytics.

### GET /api/v1/analytics/audience

Get audience demographics.

## Automation Endpoints

### GET /api/v1/automation/rules

List automation rules.

### POST /api/v1/automation/rules

Create automation rule.

### GET /api/v1/automation/rules/:id

Get automation rule.

### PUT /api/v1/automation/rules/:id

Update automation rule.

### DELETE /api/v1/automation/rules/:id

Delete automation rule.

### POST /api/v1/automation/rules/:id/toggle

Enable/disable rule.

### GET /api/v1/automation/history

Get automation history.

## Error Responses

### Error Format

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {}
  }
}
```

### Common Error Codes

- AUTH_REQUIRED: Authentication required
- INVALID_TOKEN: Invalid or expired token
- FORBIDDEN: Access forbidden
- NOT_FOUND: Resource not found
- VALIDATION_ERROR: Validation failed
- RATE_LIMIT: Rate limit exceeded
- SERVER_ERROR: Internal server error

## Rate Limiting

- Default: 100 requests per minute
- Upload: 10 requests per hour
- AI Generation: 50 requests per day

## TODO

- [ ] Complete implementation
- [ ] Add webhook endpoints
- [ ] Add GraphQL schema
- [ ] Add WebSocket events
