# YTEmpire API Documentation

## Overview
This document describes the RESTful API endpoints for the YTEmpire platform.

## Base URL
```
Production: https://api.ytempire.com
Development: http://localhost:5000
```

## Authentication
All API requests require authentication using JWT tokens.

```
Authorization: Bearer <token>
```

## Endpoints

### Auth Endpoints

#### POST /api/auth/register
Register a new user account.

#### POST /api/auth/login
Authenticate user and receive JWT token.

#### POST /api/auth/refresh
Refresh expired JWT token.

#### POST /api/auth/logout
Logout and invalidate token.

### User Endpoints

#### GET /api/users/profile
Get current user profile.

#### PUT /api/users/profile
Update user profile.

#### DELETE /api/users/account
Delete user account.

### Channel Endpoints

#### GET /api/channels
List all user channels.

#### POST /api/channels
Create new channel.

#### GET /api/channels/:id
Get channel details.

#### PUT /api/channels/:id
Update channel settings.

#### DELETE /api/channels/:id
Delete channel.

### Video Endpoints

#### GET /api/videos
List all videos.

#### POST /api/videos
Upload new video.

#### GET /api/videos/:id
Get video details.

#### PUT /api/videos/:id
Update video metadata.

#### DELETE /api/videos/:id
Delete video.

## TODO
- [ ] Complete implementation
- [ ] Add request/response examples
- [ ] Add error codes documentation
- [ ] Add rate limiting information