# YTEmpire Database Schema

## Overview

This document provides a high-level overview of the database schema for the YTEmpire platform. For detailed schema documentation, see [DATABASE_SCHEMA.md](../DATABASE_SCHEMA.md).

## Database Design Principles

- Multi-schema PostgreSQL architecture for organization
- Time-series partitioning for analytics data
- Optimized indexes for query performance
- ACID compliance with PostgreSQL
- Redis caching layer for performance

## Schema Organization

### PostgreSQL Schemas

- **users** - User management and authentication
- **content** - YouTube content metadata
- **analytics** - Performance metrics (partitioned)
- **campaigns** - Marketing campaign management
- **system** - System configuration

### Key Tables

- `users.accounts` - User accounts with roles
- `users.profiles` - Extended user profiles
- `content.channels` - YouTube channels
- `content.videos` - Video metadata
- `analytics.channel_analytics` - Channel metrics (partitioned by month)
- `analytics.video_analytics` - Video metrics (partitioned by month)

### Redis Cache Structure

- `yt:channel:{id}` - Channel metadata cache
- `yt:video:{id}` - Video metadata cache
- `yt:analytics:{type}:{id}:{period}` - Analytics cache
- `session:{id}` - User session data

For complete schema details, refer to the [full documentation](../DATABASE_SCHEMA.md).
