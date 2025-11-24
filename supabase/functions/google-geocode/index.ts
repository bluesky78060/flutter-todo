// Supabase Edge Function for Google Maps Geocoding API Proxy
// This bypasses CORS restrictions for address search

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Get Google API Key from environment variables
const GOOGLE_API_KEY = Deno.env.get('GOOGLE_MAPS_API_KEY') || ''

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
    // Check API key
    if (!GOOGLE_API_KEY) {
      console.error('❌ Google API key not configured')
      return new Response(
        JSON.stringify({ error: 'API key not configured', results: [] }),
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
        JSON.stringify({ error: 'Query is required', results: [] }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`🔍 Geocoding address: ${query}`)

    // Call Google Maps Geocoding API
    const geocodeUrl = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(query)}&key=${GOOGLE_API_KEY}&language=ko&region=kr`

    const response = await fetch(geocodeUrl)

    if (!response.ok) {
      console.error(`❌ Google Geocoding API error: ${response.status}`)
      return new Response(
        JSON.stringify({ error: `Google API error: ${response.status}`, results: [] }),
        {
          status: response.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const data = await response.json()

    if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
      console.error(`❌ Google Geocoding error: ${data.status}`)
      return new Response(
        JSON.stringify({ error: `Geocoding error: ${data.status}`, results: [] }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`✅ Geocoding results: ${data.results?.length || 0} addresses`)

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
      JSON.stringify({ error: error.message, results: [] }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
