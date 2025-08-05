# YTEmpire Database Schema

## Overview
This document describes the database schema and data models for the YTEmpire platform.

## Database Design Principles
- Denormalized for read performance
- Indexed for common queries
- Flexible schema with MongoDB
- Data integrity via application layer

## Collections

### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, indexed),
  username: String (unique, indexed),
  password: String (hashed),
  profile: {
    firstName: String,
    lastName: String,
    avatar: String,
    bio: String,
    location: String,
    website: String
  },
  settings: {
    notifications: {
      email: Boolean,
      push: Boolean,
      sms: Boolean
    },
    privacy: {
      profilePublic: Boolean,
      showEmail: Boolean
    },
    theme: String
  },
  subscription: {
    plan: String (enum: ['free', 'pro', 'enterprise']),
    status: String (enum: ['active', 'cancelled', 'expired']),
    expiresAt: Date
  },
  roles: [String],
  emailVerified: Boolean,
  twoFactorEnabled: Boolean,
  lastLogin: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Channels Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: Users),
  youtubeChannelId: String (unique),
  name: String,
  description: String,
  customUrl: String,
  thumbnail: String,
  banner: String,
  statistics: {
    subscriberCount: Number,
    viewCount: Number,
    videoCount: Number
  },
  credentials: {
    accessToken: String (encrypted),
    refreshToken: String (encrypted),
    expiresAt: Date
  },
  settings: {
    autoUpload: Boolean,
    uploadSchedule: Object,
    defaultTags: [String],
    defaultCategory: String
  },
  status: String (enum: ['active', 'inactive', 'suspended']),
  lastSync: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Videos Collection
```javascript
{
  _id: ObjectId,
  channelId: ObjectId (ref: Channels),
  youtubeVideoId: String,
  title: String,
  description: String,
  tags: [String],
  category: String,
  thumbnail: String,
  duration: Number,
  status: String (enum: ['draft', 'processing', 'uploaded', 'published', 'failed']),
  visibility: String (enum: ['public', 'unlisted', 'private']),
  scheduledAt: Date,
  publishedAt: Date,
  statistics: {
    viewCount: Number,
    likeCount: Number,
    dislikeCount: Number,
    commentCount: Number
  },
  monetization: {
    enabled: Boolean,
    estimatedRevenue: Number
  },
  ai: {
    generatedScript: String,
    generatedTags: [String],
    generatedThumbnail: String
  },
  files: {
    video: String,
    thumbnail: String,
    captions: [Object]
  },
  metadata: {
    resolution: String,
    fileSize: Number,
    format: String
  },
  createdAt: Date,
  updatedAt: Date
}
```

### Analytics Collection
```javascript
{
  _id: ObjectId,
  channelId: ObjectId (ref: Channels),
  videoId: ObjectId (ref: Videos),
  date: Date (indexed),
  metrics: {
    views: Number,
    watchTime: Number,
    averageViewDuration: Number,
    likes: Number,
    dislikes: Number,
    comments: Number,
    shares: Number,
    subscribersGained: Number,
    subscribersLost: Number
  },
  demographics: {
    age: Object,
    gender: Object,
    geography: Object
  },
  traffic: {
    source: Object,
    device: Object
  },
  revenue: {
    estimated: Number,
    ad: Number,
    premium: Number
  },
  createdAt: Date
}
```

### Automation Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: Users),
  channelId: ObjectId (ref: Channels),
  name: String,
  description: String,
  type: String (enum: ['upload', 'optimize', 'analyze', 'respond']),
  trigger: {
    type: String (enum: ['schedule', 'event', 'manual']),
    config: Object
  },
  actions: [{
    type: String,
    config: Object,
    order: Number
  }],
  conditions: [{
    field: String,
    operator: String,
    value: Mixed
  }],
  enabled: Boolean,
  lastRun: Date,
  nextRun: Date,
  runCount: Number,
  errorCount: Number,
  createdAt: Date,
  updatedAt: Date
}
```

## Indexes

### Performance Indexes
```javascript
// Users
db.users.createIndex({ email: 1 })
db.users.createIndex({ username: 1 })

// Channels
db.channels.createIndex({ userId: 1 })
db.channels.createIndex({ youtubeChannelId: 1 })

// Videos
db.videos.createIndex({ channelId: 1, createdAt: -1 })
db.videos.createIndex({ status: 1, scheduledAt: 1 })

// Analytics
db.analytics.createIndex({ channelId: 1, date: -1 })
db.analytics.createIndex({ videoId: 1, date: -1 })
```

## Relationships
- User → Channels (1:N)
- Channel → Videos (1:N)
- Channel → Analytics (1:N)
- Video → Analytics (1:N)
- User → Automation (1:N)

## TODO
- [ ] Complete implementation
- [ ] Add data migration scripts
- [ ] Add validation rules
- [ ] Add aggregation pipelines