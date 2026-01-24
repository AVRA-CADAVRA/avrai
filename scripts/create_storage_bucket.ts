#!/usr/bin/env -S deno run --allow-net --allow-env
/**
 * Create the local-llm-models storage bucket via Supabase Management API
 * 
 * Usage:
 *   deno run --allow-net --allow-env scripts/create_storage_bucket.ts
 * 
 * Requires:
 *   - SUPABASE_ACCESS_TOKEN (from Supabase Dashboard → Settings → Access Tokens)
 *   - SUPABASE_PROJECT_REF (or will use nfzlwgbvezwwrutqpedy)
 */

const PROJECT_REF = Deno.env.get('SUPABASE_PROJECT_REF') || 'nfzlwgbvezwwrutqpedy';
const ACCESS_TOKEN = Deno.env.get('SUPABASE_ACCESS_TOKEN');

if (!ACCESS_TOKEN) {
  console.error('❌ SUPABASE_ACCESS_TOKEN environment variable is required');
  console.error('   Get it from: https://supabase.com/dashboard/account/tokens');
  Deno.exit(1);
}

const API_URL = `https://api.supabase.com/v1/projects/${PROJECT_REF}`;

async function createBucket() {
  console.log('📦 Creating storage bucket: local-llm-models');
  
  try {
    // Create bucket
    const bucketResponse = await fetch(`${API_URL}/storage/buckets`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        id: 'local-llm-models',
        name: 'local-llm-models',
        public: true,
      }),
    });

    if (bucketResponse.status === 409) {
      console.log('✅ Bucket already exists');
    } else if (!bucketResponse.ok) {
      const error = await bucketResponse.text();
      console.error('❌ Failed to create bucket:', error);
      Deno.exit(1);
    } else {
      console.log('✅ Bucket created successfully');
    }

    // Note: RLS policies need to be created via SQL
    // The bucket creation via API doesn't set up the policies
    console.log('\n⚠️  Note: Storage policies need to be created via SQL Editor');
    console.log('   Run the SQL from: supabase/migrations/064_local_llm_models_bucket_v1.sql');
    console.log('   Or use the Supabase Dashboard → SQL Editor');
    
  } catch (error) {
    console.error('❌ Error:', error);
    Deno.exit(1);
  }
}

createBucket();
