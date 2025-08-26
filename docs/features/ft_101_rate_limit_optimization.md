# FT-101: Rate Limit Optimization Fix

**Status**: 🚨 URGENT  
**Priority**: Critical  
**Category**: Performance / API Management  
**Effort**: 30 minutes  

## Problem Statement

**Excessive API calls causing rate limiting**: 5-7 `get_current_time` calls per user message across multiple services:

| **Service** | **Calls per Message** | **Purpose** |
|-------------|----------------------|-------------|
| FT-060 Time Context | 2-3 calls | Time gap calculations |
| Two-pass Processing | 1-2 calls | MCP command execution |
| Background Detection | 1-2 calls | Activity semantic analysis |
| System Context | 1+ calls | System prompt generation |

**Result**: Rate limiting errors → "Claude error detected, returning text-only response"

## Root Cause Analysis

**No time data caching** - Each service independently calls `get_current_time` within the same message processing cycle, even though the time data is virtually identical (milliseconds apart).

**Evidence from Logs**:
```
Line 388: get_current_time → 2025-08-25T17:38:37.818525
Line 409: get_current_time → 2025-08-25T17:38:37.887432  (69ms later)
Line 443: get_current_time → 2025-08-25T17:38:41.850829  (4sec later)
Line 484: get_current_time → 2025-08-25T17:38:44.938493  (3sec later)
```

## Solution Strategy

**Implement message-level time data caching** - Cache `get_current_time` result for the duration of message processing to eliminate redundant API calls.

## Implementation Plan

### **Phase 1: Time Data Cache Service**
- Create singleton cache for current message processing
- Cache `get_current_time` response for ~30 seconds (message processing duration)
- All services use cached data instead of making new API calls

### **Phase 2: Service Integration**
- Update FT-060 Time Context to use cache
- Update Two-pass Processing to use cache  
- Update Background Detection to use cache
- Maintain existing functionality with cached data

### **Phase 3: Cache Management**
- Clear cache between user messages
- Handle cache expiration gracefully
- Fallback to API call if cache fails

## Expected Outcome

**API calls reduction**: 5-7 calls → 1 call per message (85% reduction)
**Rate limiting elimination**: No more "Claude error detected" responses
**Maintained functionality**: All time-dependent features continue working
**Performance improvement**: Faster response times due to cached data

## Implementation Location

**New File**: `lib/services/time_cache_service.dart`
**Modified Files**: 
- `lib/services/time_context_service.dart`
- `lib/services/integrated_mcp_processor.dart`  
- `lib/services/system_mcp_service.dart`

## Success Criteria

- [ ] Single `get_current_time` call per user message
- [ ] No rate limiting errors in logs
- [ ] All temporal features continue functioning
- [ ] Response times improve or maintain current speed

---

**Dependencies**: SystemMCP, FT-060  
**Breaking Changes**: None (internal optimization)  
**Rollback Strategy**: Remove caching, revert to direct API calls
