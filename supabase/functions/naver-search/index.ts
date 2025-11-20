// Supabase Edge Function for Naver Local Search API Proxy
// This bypasses CORS restrictions in web browsers

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const NAVER_CLIENT_ID = 'quSL_7O8Nb5bh6hK4Kj2'
const NAVER_CLIENT_SECRET = 'raJroLJaYw'

interface SearchRequest {
  query: string
  display?: number
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { query, display = 10 }: SearchRequest = await req.json()

    if (!query || query.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Query is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`🔍 Searching for: ${query}`)

    // Call Naver Local Search API
    const naverUrl = `https://openapi.naver.com/v1/search/local.json?query=${encodeURIComponent(query)}&display=${display}`

    const response = await fetch(naverUrl, {
      headers: {
        'X-Naver-Client-Id': NAVER_CLIENT_ID,
        'X-Naver-Client-Secret': NAVER_CLIENT_SECRET,
      }
    })

    if (!response.ok) {
      console.error(`❌ Naver API error: ${response.status}`)
      return new Response(
        JSON.stringify({ error: `Naver API error: ${response.status}` }),
        {
          status: response.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const data = await response.json()
    console.log(`✅ Found ${data.items?.length || 0} results`)

    // Return Naver API response
    return new Response(
      JSON.stringify(data),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
