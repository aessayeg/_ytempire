-- YTEmpire Redis Cache Helper Functions
-- Reusable Lua functions for cache operations

-- Function: Get or Set Cache
-- Gets value from cache, or sets it if not found
local get_or_set = function(key, ttl, fetch_function)
    local value = redis.call('GET', key)
    
    if value then
        redis.call('HINCRBY', 'yt:cache:stats', 'hits', 1)
        return value
    else
        redis.call('HINCRBY', 'yt:cache:stats', 'misses', 1)
        -- In real implementation, fetch_function would be called from application
        -- This is a placeholder for the pattern
        return nil
    end
end

-- Function: Batch Get with Missing Keys
-- Gets multiple keys and returns both values and missing keys
local batch_get = function(keys)
    local values = redis.call('MGET', unpack(keys))
    local result = {found = {}, missing = {}}
    
    for i, key in ipairs(keys) do
        if values[i] then
            result.found[key] = values[i]
        else
            table.insert(result.missing, key)
        end
    end
    
    redis.call('HINCRBY', 'yt:cache:stats', 'hits', #result.found)
    redis.call('HINCRBY', 'yt:cache:stats', 'misses', #result.missing)
    
    return result
end

-- Function: Invalidate Related Cache
-- Invalidates all cache entries related to a specific entity
local invalidate_related = function(entity_type, entity_id)
    local patterns = {
        ['channel'] = {
            'yt:channel:' .. entity_id,
            'yt:channel:' .. entity_id .. ':*',
            'yt:analytics:channel:' .. entity_id .. ':*'
        },
        ['video'] = {
            'yt:video:' .. entity_id,
            'yt:video:' .. entity_id .. ':*',
            'yt:analytics:video:' .. entity_id .. ':*'
        }
    }
    
    local count = 0
    local pattern_list = patterns[entity_type] or {}
    
    for _, pattern in ipairs(pattern_list) do
        local cursor = "0"
        repeat
            local result = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 100)
            cursor = result[1]
            local keys = result[2]
            
            if #keys > 0 then
                count = count + #keys
                redis.call("DEL", unpack(keys))
            end
        until cursor == "0"
    end
    
    redis.call('HINCRBY', 'yt:cache:stats', 'invalidations', count)
    return count
end

-- Function: Cache Warming
-- Pre-populate cache with frequently accessed data
local cache_warm = function(entity_type, entity_ids, ttl)
    local warmed = 0
    local prefix = 'yt:' .. entity_type .. ':'
    
    for _, id in ipairs(entity_ids) do
        local key = prefix .. id
        -- In real implementation, data would be fetched from database
        -- This is a placeholder
        local exists = redis.call('EXISTS', key)
        if exists == 0 then
            warmed = warmed + 1
        end
    end
    
    redis.call('HINCRBY', 'yt:cache:stats', 'warmed', warmed)
    return warmed
end

-- Function: Get Cache Statistics
local get_cache_stats = function()
    local stats = redis.call('HGETALL', 'yt:cache:stats')
    local result = {}
    
    for i = 1, #stats, 2 do
        result[stats[i]] = stats[i + 1]
    end
    
    -- Calculate hit rate
    local hits = tonumber(result.hits) or 0
    local misses = tonumber(result.misses) or 0
    local total = hits + misses
    
    if total > 0 then
        result.hit_rate = string.format("%.2f%%", (hits / total) * 100)
    else
        result.hit_rate = "N/A"
    end
    
    -- Get memory info
    local info = redis.call('INFO', 'memory')
    local used_memory = string.match(info, "used_memory_human:([^\r\n]+)")
    result.memory_used = used_memory
    
    return result
end

-- Function: Session Management
local manage_session = function(action, session_id, data, ttl)
    local key = 'session:' .. session_id
    
    if action == 'create' or action == 'update' then
        redis.call('SETEX', key, ttl or 3600, data)
        return 'OK'
    elseif action == 'get' then
        local session = redis.call('GET', key)
        if session then
            -- Refresh TTL on access
            redis.call('EXPIRE', key, ttl or 3600)
        end
        return session
    elseif action == 'delete' then
        return redis.call('DEL', key)
    elseif action == 'exists' then
        return redis.call('EXISTS', key)
    end
end

-- Store helper function references
redis.call('SET', 'yt:helpers:loaded', '1')
redis.call('SET', 'yt:helpers:version', '1.0.0')

return "Cache helper functions loaded successfully"