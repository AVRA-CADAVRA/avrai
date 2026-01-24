# Model Hosting Security - Quick Reference

## TL;DR: Recommended Approach

**Use:** Supabase Storage (public bucket)  
**Security Level:** ⭐⭐⭐⭐ (Very Good)  
**Why Safe:** SHA-256 verification + signed manifests

## Security Layers (Already Implemented)

1. ✅ **SHA-256 Verification** - Every model verified before activation
2. ✅ **Signed Manifests** - Ed25519 signatures prevent MITM
3. ✅ **HTTPS Only** - All downloads encrypted in transit
4. ✅ **Service Role Uploads** - Only authorized uploads allowed

## Setup Steps

### 1. Create Storage Bucket

```bash
# Run migration
supabase migration up

# Or manually in SQL Editor:
# See: supabase/migrations/064_local_llm_models_bucket_v1.sql
```

### 2. Upload Models

- Upload via Supabase Dashboard → Storage → local-llm-models
- Files automatically publicly readable (secure due to verification)

### 3. Configure Secrets

```bash
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://..."
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[hash]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[size]"
```

### 4. Deploy Edge Function

```bash
supabase functions deploy local-llm-manifest --no-verify-jwt
```

## Why Public Access is Safe

✅ **Models are verified:**
- SHA-256 hash verification (prevents tampering)
- Signed manifests (prevents MITM)
- Automatic rejection of invalid files

✅ **Models aren't sensitive:**
- Open-source weights (not proprietary)
- No user data in models
- Public access is expected

✅ **Uploads are restricted:**
- Only service role can upload
- RLS policies enforce access control

## When to Upgrade

**Move to CDN when:**
- Download volume > 10,000/month
- Bandwidth costs > $500/month
- Performance issues reported

**Migration:** No client changes needed (URLs come from manifest)

## Full Documentation

- **Security Guide:** [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md)
- **Setup Guide:** [MODEL_HOSTING_GUIDE.md](./MODEL_HOSTING_GUIDE.md)
- **Migration:** `supabase/migrations/064_local_llm_models_bucket_v1.sql`

## Security Checklist

- [ ] Storage bucket created with RLS policies
- [ ] Models uploaded to bucket
- [ ] SHA-256 hashes calculated
- [ ] Supabase secrets configured
- [ ] Edge Function deployed
- [ ] SHA-256 verification tested
- [ ] Signed manifest verification tested
- [ ] HTTPS enforced
- [ ] Access logs monitored
