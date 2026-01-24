import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { encodeBase64, decodeBase64 } from 'https://deno.land/std@0.224.0/encoding/base64.ts'
import * as ed25519 from 'npm:@noble/ed25519@2.1.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type Platform = 'android' | 'ios' | 'macos'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = (req.method === 'POST') ? await req.json() : {}
    const tier = typeof body?.tier === 'string' ? body.tier : 'llama8b'
    const platform = (typeof body?.platform === 'string' ? body.platform : '') as Platform

    const keyId = Deno.env.get('LOCAL_LLM_MANIFEST_KEY_ID') ?? 'v1'
    const signingKeyB64 = Deno.env.get('LOCAL_LLM_MANIFEST_SIGNING_KEY_B64') ?? ''
    if (!signingKeyB64) {
      return new Response(JSON.stringify({ error: 'Signing key not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const signingKey = decodeBase64(signingKeyB64)
    if (signingKey.length !== 32) {
      return new Response(JSON.stringify({ error: 'Invalid signing key length (expected 32 bytes seed)' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // These should point at Supabase Storage public URLs.
    // Keep weights out of the repo; configure URLs/hashes via env.
    // Tiered artifacts (prefer llama8b when available).
    const androidUrl8b = Deno.env.get('LOCAL_LLM_ANDROID_GGUF_URL') ?? ''
    const androidSha2568b = Deno.env.get('LOCAL_LLM_ANDROID_GGUF_SHA256') ?? ''
    const androidSize8b = Number(Deno.env.get('LOCAL_LLM_ANDROID_GGUF_SIZE_BYTES') ?? '0')

    const androidUrl3b = Deno.env.get('LOCAL_LLM_ANDROID_GGUF_URL_3B') ?? ''
    const androidSha2563b = Deno.env.get('LOCAL_LLM_ANDROID_GGUF_SHA256_3B') ?? ''
    const androidSize3b = Number(Deno.env.get('LOCAL_LLM_ANDROID_GGUF_SIZE_BYTES_3B') ?? '0')

    const iosUrl8b = Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_URL') ?? ''
    const iosSha2568b = Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_SHA256') ?? ''
    const iosSize8b = Number(Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_SIZE_BYTES') ?? '0')

    const iosUrl3b = Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_URL_3B') ?? ''
    const iosSha2563b = Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_SHA256_3B') ?? ''
    const iosSize3b = Number(Deno.env.get('LOCAL_LLM_IOS_COREML_ZIP_SIZE_BYTES_3B') ?? '0')

    // macOS (Apple Silicon CoreML)
    const macosCoreMLUrl8b = Deno.env.get('LOCAL_LLM_MACOS_COREML_ZIP_URL') ?? ''
    const macosCoreMLSha2568b = Deno.env.get('LOCAL_LLM_MACOS_COREML_ZIP_SHA256') ?? ''
    const macosCoreMLSize8b = Number(Deno.env.get('LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES') ?? '0')

    // macOS (Intel GGUF fallback - optional)
    const macosIntelUrl8b = Deno.env.get('LOCAL_LLM_MACOS_INTEL_GGUF_URL') ?? ''
    const macosIntelSha2568b = Deno.env.get('LOCAL_LLM_MACOS_INTEL_GGUF_SHA256') ?? ''
    const macosIntelSize8b = Number(Deno.env.get('LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES') ?? '0')

    const artifacts: any[] = []
    if (tier === 'small3b') {
      if (androidUrl3b && androidSha2563b && androidSize3b > 0) {
        artifacts.push({
          platform: 'android_gguf',
          url: androidUrl3b,
          sha256: androidSha2563b,
          size_bytes: androidSize3b,
          file_name: 'model.gguf',
          is_zip: false,
        })
      }
      if (iosUrl3b && iosSha2563b && iosSize3b > 0) {
        artifacts.push({
          platform: 'ios_coreml_zip',
          url: iosUrl3b,
          sha256: iosSha2563b,
          size_bytes: iosSize3b,
          file_name: 'model_coreml.zip',
          is_zip: true,
        })
      }
      // macOS 3B tier support can be added here if needed
    } else {
      if (androidUrl8b && androidSha2568b && androidSize8b > 0) {
      artifacts.push({
        platform: 'android_gguf',
        url: androidUrl8b,
        sha256: androidSha2568b,
        size_bytes: androidSize8b,
        file_name: 'model.gguf',
        is_zip: false,
      })
    }
      if (iosUrl8b && iosSha2568b && iosSize8b > 0) {
      artifacts.push({
        platform: 'ios_coreml_zip',
        url: iosUrl8b,
        sha256: iosSha2568b,
        size_bytes: iosSize8b,
        file_name: 'model_coreml.zip',
        is_zip: true,
      })
    }
      // macOS (Apple Silicon - CoreML)
      if (macosCoreMLUrl8b && macosCoreMLSha2568b && macosCoreMLSize8b > 0) {
        artifacts.push({
          platform: 'macos_coreml_zip',
          url: macosCoreMLUrl8b,
          sha256: macosCoreMLSha2568b,
          size_bytes: macosCoreMLSize8b,
          file_name: 'model_coreml.zip',
          is_zip: true,
        })
      }
      // macOS (Intel - GGUF fallback)
      if (macosIntelUrl8b && macosIntelSha2568b && macosIntelSize8b > 0) {
        artifacts.push({
          platform: 'macos_intel_gguf',
          url: macosIntelUrl8b,
          sha256: macosIntelSha2568b,
          size_bytes: macosIntelSize8b,
          file_name: 'model.gguf',
          is_zip: false,
        })
      }
    }

    // Minimal manifest payload (matches Dart schema).
    const payload = {
      model_id: tier === 'small3b' ? 'small3b_instruct' : 'llama3_1_8b_instruct',
      version: '1.0.0',
      family: tier === 'small3b' ? 'small3b' : 'llama3.1',
      context_len: tier === 'small3b' ? 4096 : 8192,
      min_device: tier === 'small3b'
        ? { min_ram_mb: 6144, min_free_disk_mb: 6144 }
        : { min_ram_mb: 8192, min_free_disk_mb: 12288 },
      artifacts,
    }

    // If caller includes platform, we can optionally filter (keeps response small).
    if (platform === 'android') {
      payload.artifacts = artifacts.filter((a) => a.platform === 'android_gguf')
    } else if (platform === 'ios') {
      payload.artifacts = artifacts.filter((a) => a.platform === 'ios_coreml_zip')
    } else if (platform === 'macos') {
      // macOS: prefer CoreML, fallback to Intel GGUF
      const coremlArtifact = artifacts.find((a) => a.platform === 'macos_coreml_zip')
      const intelArtifact = artifacts.find((a) => a.platform === 'macos_intel_gguf')
      payload.artifacts = coremlArtifact ? [coremlArtifact] : (intelArtifact ? [intelArtifact] : [])
    }

    const payloadBytes = new TextEncoder().encode(JSON.stringify(payload))
    const sigBytes = await ed25519.signAsync(payloadBytes, signingKey)

    return new Response(
      JSON.stringify({
        key_id: keyId,
        payload_b64: encodeBase64(payloadBytes),
        sig_b64: encodeBase64(sigBytes),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    )
  } catch (e) {
    console.error('local-llm-manifest error:', e)
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

