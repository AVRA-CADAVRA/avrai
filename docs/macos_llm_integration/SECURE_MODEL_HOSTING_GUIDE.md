# Secure Model Hosting Guide for macOS LLM Models

**Date:** January 2025  
**Purpose:** Best practices for securely hosting and distributing LLM model files

## Security Requirements

When hosting LLM models, we need to ensure:

1. **Integrity**: Models aren't tampered with or corrupted
2. **Availability**: Models are accessible when needed
3. **Authenticity**: Models come from trusted source
4. **Performance**: Fast downloads for good UX
5. **Cost**: Efficient bandwidth usage

## Current Security Implementation

The AVRAI app already implements several security layers:

### ✅ Already Implemented

1. **SHA-256 Verification** (`model_pack_manager.dart`)
   - Every downloaded model is verified against expected hash
   - Prevents corruption and tampering
   - Automatic rejection of mismatched files

2. **Signed Manifests** (`signed_manifest_verifier.dart`)
   - Manifests are signed with Ed25519
   - Client-side verification prevents MITM attacks
   - Key rotation support built-in

3. **Secure Manifest Distribution**
   - Manifests served via Supabase Edge Functions
   - No user-provided URLs in production
   - Server-side signing prevents tampering

## Recommended Hosting Approaches

### Option 1: Supabase Storage (Recommended for Start)

**Security Level:** ⭐⭐⭐⭐ (Very Good)

**Pros:**
- ✅ Integrated with existing infrastructure
- ✅ Built-in CDN (via Supabase)
- ✅ Easy to manage
- ✅ Already using for other assets
- ✅ Public access with SHA-256 verification is secure

**Cons:**
- ⚠️ Bandwidth costs can add up with large models
- ⚠️ Less control over CDN configuration

**Implementation:**

```sql
-- Create public bucket for models
INSERT INTO storage.buckets (id, name, public)
VALUES ('local-llm-models', 'local-llm-models', true)
ON CONFLICT (id) DO NOTHING;

-- Public read access (models are verified via SHA-256)
CREATE POLICY "Public read access for LLM models" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'local-llm-models');

-- Restrict uploads to service role only
CREATE POLICY "Service role can upload models" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );
```

**Security Notes:**
- Models are **publicly readable** but this is safe because:
  - SHA-256 verification ensures integrity
  - Signed manifests ensure authenticity
  - Models are not sensitive data (they're open-source weights)
- Uploads restricted to service role prevents unauthorized modifications

### Option 2: Supabase Storage + Signed URLs (More Secure)

**Security Level:** ⭐⭐⭐⭐⭐ (Excellent)

**Pros:**
- ✅ All benefits of Supabase Storage
- ✅ Additional access control layer
- ✅ Can track/download patterns
- ✅ Time-limited access

**Cons:**
- ⚠️ Requires Edge Function to generate signed URLs
- ⚠️ Slightly more complex implementation

**Implementation:**

```sql
-- Create private bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('local-llm-models', 'local-llm-models', false)
ON CONFLICT (id) DO NOTHING;

-- Only service role can read
CREATE POLICY "Service role can read models" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );
```

**Edge Function** (`supabase/functions/get-model-url/index.ts`):
```typescript
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

serve(async (req) => {
  const { modelId, platform } = await req.json()
  
  // Verify request (optional: add auth checks)
  // Generate signed URL (expires in 1 hour)
  const signedUrl = await supabase.storage
    .from('local-llm-models')
    .createSignedUrl(`${platform}/${modelId}`, 3600)
  
  return new Response(JSON.stringify({ url: signedUrl }))
})
```

**Update manifest to include signed URL endpoint:**
- Manifest contains signed URL endpoint instead of direct URL
- Client requests signed URL from Edge Function
- Downloads with time-limited access

### Option 3: CDN with Cloudflare/AWS CloudFront (Best Performance)

**Security Level:** ⭐⭐⭐⭐ (Very Good)

**Pros:**
- ✅ Best performance (global CDN)
- ✅ Lower bandwidth costs
- ✅ DDoS protection
- ✅ Advanced caching

**Cons:**
- ⚠️ Additional infrastructure to manage
- ⚠️ More complex setup

**Implementation:**

1. **Upload to S3/GCS:**
   ```bash
   aws s3 cp llama-3.1-8b-instruct-coreml.zip \
     s3://avrai-llm-models/macos/llama-3.1-8b-instruct-coreml.zip \
     --acl public-read
   ```

2. **Configure CloudFront:**
   - Origin: S3 bucket
   - Cache policy: Cache-Control headers
   - Security: Origin Access Control (OAC)
   - HTTPS only

3. **Security Headers:**
   ```
   X-Content-Type-Options: nosniff
   X-Frame-Options: DENY
   Content-Security-Policy: default-src 'self'
   ```

4. **Update Manifest:**
   - Use CloudFront URL in manifest
   - SHA-256 verification still applies
   - Signed manifests still verify authenticity

### Option 4: Hybrid Approach (Recommended for Production)

**Security Level:** ⭐⭐⭐⭐⭐ (Excellent)

**Architecture:**
- **Manifests**: Supabase Edge Function (signed, verified)
- **Models**: CDN (Cloudflare/AWS) for performance
- **Verification**: SHA-256 on client (always)
- **Access**: Public read (safe due to verification)

**Flow:**
1. Client requests manifest from Supabase Edge Function
2. Manifest contains CDN URLs + SHA-256 hashes
3. Client downloads from CDN
4. Client verifies SHA-256 before activation
5. If verification fails, download is rejected

**Benefits:**
- ✅ Best performance (CDN)
- ✅ Best security (signed manifests + SHA-256)
- ✅ Cost-effective (CDN bandwidth)
- ✅ Scalable (handles large downloads)

## Security Best Practices

### 1. Always Verify Integrity

**✅ DO:**
```dart
// SHA-256 verification (already implemented)
final digest = (await sha256.bind(file.openRead()).first).toString();
if (digest.toLowerCase() != expectedHash.toLowerCase()) {
  throw Exception('SHA-256 verification failed');
}
```

**❌ DON'T:**
- Skip hash verification
- Use weak hashes (MD5, SHA-1)
- Trust URLs without verification

### 2. Use Signed Manifests

**✅ DO:**
- Sign manifests with Ed25519 (already implemented)
- Verify signatures client-side
- Support key rotation

**❌ DON'T:**
- Allow user-provided manifest URLs in production
- Skip signature verification
- Use weak signing algorithms

### 3. Implement Access Controls

**✅ DO:**
- Restrict uploads to service role
- Use RLS policies for storage
- Monitor access patterns

**❌ DON'T:**
- Allow public uploads
- Skip access logging
- Use weak authentication

### 4. Use HTTPS Only

**✅ DO:**
- Force HTTPS for all downloads
- Use TLS 1.2+ only
- Verify certificates

**❌ DON'T:**
- Allow HTTP downloads
- Skip certificate verification
- Use self-signed certificates in production

### 5. Monitor and Log

**✅ DO:**
- Log all download attempts
- Monitor for anomalies
- Track verification failures
- Alert on suspicious patterns

**❌ DON'T:**
- Skip logging
- Ignore verification failures
- Allow silent failures

## Recommended Setup for AVRAI

### Phase 1: Start Simple (Current Plan)

**Use:** Supabase Storage (public bucket)

**Why:**
- ✅ Already integrated
- ✅ SHA-256 verification provides security
- ✅ Signed manifests ensure authenticity
- ✅ Simple to implement
- ✅ Good enough for initial launch

**Security:**
- Public read access (safe: models verified)
- Service role upload only
- SHA-256 verification on download
- Signed manifest verification

### Phase 2: Scale Up (When Needed)

**Use:** Hybrid (Supabase manifests + CDN models)

**Why:**
- ✅ Better performance (CDN)
- ✅ Lower costs (CDN bandwidth)
- ✅ Same security (verification unchanged)
- ✅ Better scalability

**Migration:**
- Keep Supabase for manifests
- Move models to CDN
- Update manifest URLs
- No client changes needed (URLs come from manifest)

## Threat Model Analysis

### Threats Addressed

1. **Model Tampering** ✅
   - **Mitigation:** SHA-256 verification
   - **Risk:** Low (hash mismatch detected)

2. **MITM Attacks** ✅
   - **Mitigation:** Signed manifests + HTTPS
   - **Risk:** Low (signature verification)

3. **Unauthorized Access** ✅
   - **Mitigation:** Service role uploads only
   - **Risk:** Low (RLS policies)

4. **Corruption During Transfer** ✅
   - **Mitigation:** SHA-256 verification
   - **Risk:** Low (automatic detection)

5. **DDoS on Storage** ⚠️
   - **Mitigation:** CDN with DDoS protection (Phase 2)
   - **Risk:** Medium (mitigated by CDN)

### Threats NOT Addressed (Acceptable)

1. **Model Theft** ❌
   - **Why Acceptable:** Models are open-source weights
   - **Impact:** None (not sensitive data)

2. **Download Tracking** ❌
   - **Why Acceptable:** Public models, tracking is expected
   - **Impact:** Low (no PII in models)

## Implementation Checklist

### Supabase Storage Setup

- [ ] Create `local-llm-models` bucket
- [ ] Set bucket to public (read-only)
- [ ] Create RLS policy: Service role upload only
- [ ] Upload models
- [ ] Calculate SHA-256 hashes
- [ ] Configure Supabase secrets
- [ ] Test public URL access
- [ ] Verify SHA-256 in app

### CDN Setup (Optional, Phase 2)

- [ ] Set up S3/GCS bucket
- [ ] Configure CloudFront/Cloudflare
- [ ] Set security headers
- [ ] Upload models to CDN
- [ ] Update manifest URLs
- [ ] Test CDN performance
- [ ] Monitor bandwidth costs

### Security Verification

- [ ] Test SHA-256 verification (correct hash)
- [ ] Test SHA-256 rejection (wrong hash)
- [ ] Test signed manifest verification
- [ ] Test invalid signature rejection
- [ ] Verify HTTPS only
- [ ] Test access controls
- [ ] Monitor download logs

## Cost Considerations

### Supabase Storage

- **Storage:** ~$0.021/GB/month
- **Bandwidth:** ~$0.09/GB (outbound)
- **Example:** 8GB model, 1000 downloads = ~$720/month

### CDN (Cloudflare)

- **Storage:** ~$0.005/GB/month (R2)
- **Bandwidth:** Free (egress)
- **Example:** 8GB model, 1000 downloads = ~$4/month

**Recommendation:** Start with Supabase, migrate to CDN when costs become significant.

## Final Recommendation

### For AVRAI: **Supabase Storage (Public Bucket)**

**Rationale:**
1. ✅ **Security is sufficient**: SHA-256 + signed manifests provide strong protection
2. ✅ **Simple to implement**: Already integrated
3. ✅ **Good enough for launch**: Performance is acceptable
4. ✅ **Easy to migrate**: Can move to CDN later without client changes
5. ✅ **Cost-effective initially**: Free tier covers early usage

**Security Justification:**
- Public read access is **safe** because:
  - Models are verified with SHA-256 (prevents tampering)
  - Manifests are signed (prevents MITM)
  - Models contain no sensitive data (open-source weights)
  - Uploads are restricted (service role only)

**When to Upgrade:**
- Download volume > 10,000/month
- Bandwidth costs > $500/month
- Performance issues reported
- Need advanced CDN features

## Additional Security Enhancements (Optional)

### 1. Rate Limiting

Add rate limiting to manifest endpoint:
```typescript
// In Edge Function
const rateLimit = await checkRateLimit(userId)
if (!rateLimit.allowed) {
  return new Response('Rate limit exceeded', { status: 429 })
}
```

### 2. Download Quotas

Track downloads per user:
```sql
CREATE TABLE model_downloads (
  user_id UUID,
  model_id TEXT,
  downloaded_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, model_id)
);
```

### 3. Anomaly Detection

Monitor for suspicious patterns:
- Multiple failed verifications
- Unusual download patterns
- Rapid manifest requests

### 4. Content Security Policy

Add CSP headers to storage/CDN:
```
Content-Security-Policy: default-src 'self'; 
  script-src 'none'; 
  object-src 'none';
```

## Conclusion

**Recommended Approach:** Supabase Storage with public read access

**Security Level:** ⭐⭐⭐⭐ (Very Good)

**Why It's Safe:**
- SHA-256 verification prevents tampering
- Signed manifests prevent MITM
- Service role uploads prevent unauthorized changes
- Models contain no sensitive data

**Migration Path:**
- Start: Supabase Storage (simple, secure)
- Scale: Add CDN when needed (performance, cost)
- No client changes required (URLs from manifest)

The current implementation with SHA-256 verification and signed manifests provides strong security even with public model access.
