# Audit Log Monitoring Guide

**Date:** November 30, 2025  
**Purpose:** Guide for monitoring audit logs and security events  
**Phase:** Phase 7, Section 43-44 (7.3.5-6)

---

## Overview

The audit log system tracks all sensitive data access and security events. This guide explains how to monitor and analyze audit logs for security incidents.

---

## Audit Log Types

### 1. Data Access (`data_access`)
Tracks when sensitive data fields are accessed.

**Fields:**
- `userId` - User whose data was accessed
- `fieldName` - Field that was accessed (email, name, phone, etc.)
- `action` - Action performed (read, write, delete, update)
- `timestamp` - When access occurred

**Example Query:**
```sql
SELECT * FROM audit_logs 
WHERE type = 'data_access' 
ORDER BY timestamp DESC 
LIMIT 100;
```

### 2. Security Events (`security_event`)
Tracks authentication, authorization, and other security events.

**Fields:**
- `eventType` - Type of event (authentication, authorization, encryption, etc.)
- `userId` - User ID (if applicable)
- `status` - Event status (success, failure, blocked)
- `timestamp` - When event occurred

**Example Query:**
```sql
SELECT * FROM audit_logs 
WHERE type = 'security_event' 
AND status = 'failure'
ORDER BY timestamp DESC;
```

### 3. Data Modifications (`data_modification`)
Tracks when sensitive data is modified.

**Fields:**
- `userId` - User whose data was modified
- `fieldName` - Field that was modified
- `oldValue` - Previous value (masked)
- `newValue` - New value (masked)
- `timestamp` - When modification occurred

**Example Query:**
```sql
SELECT * FROM audit_logs 
WHERE type = 'data_modification' 
ORDER BY timestamp DESC 
LIMIT 50;
```

### 4. Anonymization Events (`anonymization`)
Tracks when users are anonymized for AI2AI network.

**Fields:**
- `userId` - User ID that was anonymized
- `agentId` - Agent ID that was created
- `timestamp` - When anonymization occurred

**Example Query:**
```sql
SELECT * FROM audit_logs 
WHERE type = 'anonymization' 
ORDER BY timestamp DESC;
```

---

## Monitoring Queries

### Recent Security Events
```sql
SELECT 
  timestamp,
  eventType,
  status,
  userId,
  metadata
FROM audit_logs 
WHERE type = 'security_event'
  AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;
```

### Failed Authentication Attempts
```sql
SELECT 
  timestamp,
  userId,
  metadata
FROM audit_logs 
WHERE type = 'security_event'
  AND eventType = 'authentication'
  AND status = 'failure'
ORDER BY timestamp DESC;
```

### Unusual Data Access Patterns
```sql
SELECT 
  userId,
  fieldName,
  COUNT(*) as access_count,
  MAX(timestamp) as last_access
FROM audit_logs 
WHERE type = 'data_access'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY userId, fieldName
HAVING COUNT(*) > 100
ORDER BY access_count DESC;
```

### Data Modifications by User
```sql
SELECT 
  userId,
  fieldName,
  COUNT(*) as modification_count,
  MAX(timestamp) as last_modification
FROM audit_logs 
WHERE type = 'data_modification'
  AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY userId, fieldName
ORDER BY modification_count DESC;
```

### Anonymization Activity
```sql
SELECT 
  DATE(timestamp) as date,
  COUNT(*) as anonymization_count
FROM audit_logs 
WHERE type = 'anonymization'
  AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

---

## Alert Conditions

Set up alerts for the following conditions:

### 1. Multiple Failed Authentication Attempts
```sql
-- Alert if > 5 failed auth attempts in 1 hour
SELECT userId, COUNT(*) as failures
FROM audit_logs 
WHERE type = 'security_event'
  AND eventType = 'authentication'
  AND status = 'failure'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY userId
HAVING COUNT(*) > 5;
```

### 2. Unusual Data Access Volume
```sql
-- Alert if user accesses > 1000 records in 1 hour
SELECT userId, COUNT(*) as accesses
FROM audit_logs 
WHERE type = 'data_access'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY userId
HAVING COUNT(*) > 1000;
```

### 3. Bulk Data Modifications
```sql
-- Alert if > 50 modifications in 1 hour
SELECT userId, COUNT(*) as modifications
FROM audit_logs 
WHERE type = 'data_modification'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY userId
HAVING COUNT(*) > 50;
```

### 4. Anonymization Failures
```sql
-- Alert on any anonymization failures
SELECT *
FROM audit_logs 
WHERE type = 'anonymization'
  AND status = 'failure'
  AND timestamp > NOW() - INTERVAL '1 hour';
```

---

## Dashboard Queries

### Daily Summary
```sql
SELECT 
  DATE(timestamp) as date,
  type,
  COUNT(*) as event_count
FROM audit_logs 
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), type
ORDER BY date DESC, type;
```

### Top Users by Activity
```sql
SELECT 
  userId,
  COUNT(*) as total_events,
  COUNT(CASE WHEN type = 'data_access' THEN 1 END) as data_accesses,
  COUNT(CASE WHEN type = 'data_modification' THEN 1 END) as modifications
FROM audit_logs 
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY userId
ORDER BY total_events DESC
LIMIT 20;
```

### Security Event Breakdown
```sql
SELECT 
  eventType,
  status,
  COUNT(*) as count
FROM audit_logs 
WHERE type = 'security_event'
  AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY eventType, status
ORDER BY count DESC;
```

---

## Retention Policy

### Recommended Retention
- **Security Events:** 90 days
- **Data Access:** 30 days
- **Data Modifications:** 90 days
- **Anonymization Events:** 365 days

### Cleanup Query
```sql
-- Delete old audit logs (run monthly)
DELETE FROM audit_logs 
WHERE timestamp < NOW() - INTERVAL '90 days'
  AND type IN ('data_access', 'data_modification');
```

---

## Integration with Monitoring Tools

### Supabase Dashboard
- View audit logs in Supabase dashboard
- Set up alerts via Supabase webhooks
- Export logs for analysis

### External Monitoring
- Export logs to external SIEM
- Set up alerts via webhooks
- Integrate with monitoring tools (Datadog, New Relic, etc.)

---

## Best Practices

1. **Regular Review:** Review audit logs weekly
2. **Automated Alerts:** Set up alerts for suspicious patterns
3. **Retention:** Maintain logs according to compliance requirements
4. **Access Control:** Limit access to audit logs (admin only)
5. **Backup:** Regularly backup audit logs
6. **Analysis:** Analyze patterns to detect anomalies

---

## Compliance

### GDPR
- Audit logs help demonstrate compliance
- Track data access and modifications
- Support data subject requests

### CCPA
- Track data access and sharing
- Support consumer requests
- Demonstrate security measures

---

## Troubleshooting

### No Audit Logs
- Check if AuditLogService is registered in DI
- Verify database connection
- Check RLS policies allow inserts

### Missing Events
- Verify services are calling audit methods
- Check for errors in application logs
- Verify database permissions

### Performance Issues
- Add indexes on frequently queried fields
- Archive old logs
- Optimize queries

---

**Last Updated:** November 30, 2025  
**Status:** Active

