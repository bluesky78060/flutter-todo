// Supabase Edge Function for Naver Geocoding API Proxy
// This bypasses CORS restrictions for address search

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Get credentials from environment variables
const NAVER_CLIENT_ID = Deno.env.get('NAVER_LOCAL_SEARCH_CLIENT_ID') || ''
const NAVER_CLIENT_SECRET = Deno.env.get('NAVER_LOCAL_SEARCH_CLIENT_SECRET') || ''

interface GeocodeRequest {
  query: string
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Check credentials
    if (!NAVER_CLIENT_ID || !NAVER_CLIENT_SECRET) {
      console.error('❌ Naver API credentials not configured')
      return new Response(
        JSON.stringify({ error: 'API credentials not configured', addresses: [] }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request
    const { query }: GeocodeRequest = await req.json()

    if (!query || query.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Query is required', addresses: [] }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`🔍 Geocoding address: ${query}`)

    // Call Naver Geocoding API
    const geocodeUrl = `https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=${encodeURIComponent(query)}`

    const response = await fetch(geocodeUrl, {
      headers: {
        'X-NCP-APIGW-API-KEY-ID': NAVER_CLIENT_ID,
        'X-NCP-APIGW-API-KEY': NAVER_CLIENT_SECRET,
      }
    })

    if (!response.ok) {
      console.error(`❌ Naver Geocoding API error: ${response.status}`)
      return new Response(
        JSON.stringify({ error: `Naver API error: ${response.status}`, addresses: [] }),
        {
          status: response.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const data = await response.json()
    console.log(`✅ Geocoding results: ${data.addresses?.length || 0} addresses`)

    // Return response
    return new Response(
      JSON.stringify(data),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(
      JSON.stringify({ error: error.message, addresses: [] }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
