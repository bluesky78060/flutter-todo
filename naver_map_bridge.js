// Naver Map Bridge - Pure JavaScript implementation
(function() {
  'use strict';

  console.log('🗺️ Naver Map Bridge: Initializing');

  // Store map instances
  const mapInstances = new Map();

  // Initialize a new map
  window.initNaverMap = function(divId, centerLat, centerLng, zoom) {
    console.log(`🗺️ initNaverMap called: divId=${divId}, center=${centerLat},${centerLng}, zoom=${zoom}`);

    try {
      if (!window.naver || !window.naver.maps) {
        console.error('❌ Naver Maps API not loaded');
        window.parent.postMessage({
          type: 'naver_map_error',
          divId: divId,
          error: 'Naver Maps API not loaded'
        }, '*');
        return;
      }

      const mapDiv = document.getElementById(divId);
      if (!mapDiv) {
        console.error(`❌ Map div not found: ${divId}`);
        window.parent.postMessage({
          type: 'naver_map_error',
          divId: divId,
          error: 'Map div not found'
        }, '*');
        return;
      }

      // Create map
      const mapOptions = {
        center: new naver.maps.LatLng(centerLat, centerLng),
        zoom: zoom || 15,
        zoomControl: true,
        zoomControlOptions: {
          position: naver.maps.Position.TOP_RIGHT
        }
      };

      const map = new naver.maps.Map(mapDiv, mapOptions);

      // Store map instance
      mapInstances.set(divId, {
        map: map,
        marker: null,
        circle: null
      });

      // Add click listener
      naver.maps.Event.addListener(map, 'click', function(e) {
        const lat = e.coord.y;
        const lng = e.coord.x;
        console.log(`🗺️ Map clicked: ${lat}, ${lng}`);

        window.parent.postMessage({
          type: 'naver_map_tap',
          divId: divId,
          lat: lat,
          lng: lng
        }, '*');
      });

      console.log(`✅ Naver Map initialized: ${divId}`);

      // Notify Flutter that map is ready
      window.parent.postMessage({
        type: 'naver_map_ready',
        divId: divId
      }, '*');

    } catch (error) {
      console.error('❌ Error initializing Naver Map:', error);
      window.parent.postMessage({
        type: 'naver_map_error',
        divId: divId,
        error: error.message
      }, '*');
    }
  };

  // Update map overlays (marker and circle)
  window.updateNaverMapOverlays = function(divId, lat, lng, radiusMeters) {
    console.log(`🗺️ updateNaverMapOverlays: divId=${divId}, position=${lat},${lng}, radius=${radiusMeters}`);

    const instance = mapInstances.get(divId);
    if (!instance) {
      console.error(`❌ Map instance not found: ${divId}`);
      return;
    }

    const map = instance.map;

    try {
      // Remove existing marker
      if (instance.marker) {
        instance.marker.setMap(null);
      }

      // Remove existing circle
      if (instance.circle) {
        instance.circle.setMap(null);
      }

      const position = new naver.maps.LatLng(lat, lng);

      // Create marker
      instance.marker = new naver.maps.Marker({
        position: position,
        map: map,
        icon: {
          content: '<div style="background-color: #4285F4; width: 20px; height: 20px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.3);"></div>',
          anchor: new naver.maps.Point(10, 10)
        }
      });

      // Create circle
      instance.circle = new naver.maps.Circle({
        map: map,
        center: position,
        radius: radiusMeters,
        strokeColor: '#4285F4',
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: '#4285F4',
        fillOpacity: 0.2
      });

      // Center map on position
      map.setCenter(position);

      console.log(`✅ Map overlays updated: ${divId}`);
    } catch (error) {
      console.error('❌ Error updating map overlays:', error);
    }
  };

  // Move camera to position
  window.moveNaverMapCamera = function(divId, lat, lng) {
    console.log(`🗺️ moveNaverMapCamera: divId=${divId}, position=${lat},${lng}`);

    const instance = mapInstances.get(divId);
    if (!instance) {
      console.error(`❌ Map instance not found: ${divId}`);
      return;
    }

    try {
      const position = new naver.maps.LatLng(lat, lng);
      instance.map.setCenter(position);
      console.log(`✅ Camera moved: ${divId}`);
    } catch (error) {
      console.error('❌ Error moving camera:', error);
    }
  };

  // Multi-strategy search (like mobile implementation)
  // Strategy 1: Naver Local Search (for place names)
  // Strategy 2: Google Geocoding (for addresses)
  // Strategy 3: First word only (for compound queries)
  window.searchNaverPlaces = async function(query) {
    console.log(`🔍 searchNaverPlaces called: query="${query}"`);

    if (!query || query.trim().length === 0) {
      console.error('❌ Empty search query');
      return Promise.reject('Empty search query');
    }

    try {
      // Strategy 1: Try exact query with Naver Local Search API
      console.log('🔍 Strategy 1: Naver Local Search (exact query)');
      let results = await searchNaverLocalAPI(query);
      if (results.length > 0) {
        console.log(`✅ Strategy 1 success: ${results.length} results`);
        return results;
      }

      // Strategy 2: Try Google Geocoding for address search
      console.log('🔍 Strategy 2: Google Geocoding (address search)');
      results = await searchGoogleGeocoding(query);
      if (results.length > 0) {
        console.log(`✅ Strategy 2 success: ${results.length} results`);
        return results;
      }

      // Strategy 3: Try first word only (for compound queries like "스타벅스 강남")
      const firstWord = query.split(/\s+/)[0];
      if (firstWord !== query && firstWord.length > 0) {
        console.log(`🔍 Strategy 3: First word only "${firstWord}"`);
        results = await searchNaverLocalAPI(firstWord);
        if (results.length > 0) {
          console.log(`✅ Strategy 3 success: ${results.length} results`);
          return results;
        }
      }

      console.log('⚠️ No results found for:', query);
      return [];

    } catch (error) {
      console.error('❌ Search error:', error);
      return [];
    }
  };

  // Internal function: Search using Naver Local Search API (via proxy)
  async function searchNaverLocalAPI(query) {
    try {
      console.log(`   → Naver Local Search: "${query}"`);

      const response = await fetch('http://localhost:3000/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: query,
          display: 10
        })
      });

      if (!response.ok) {
        console.error(`   ✗ Proxy error: ${response.status}`);
        return [];
      }

      const data = await response.json();
      const items = data.items || [];

      console.log(`   → Found ${items.length} items`);

      if (items.length === 0) {
        return [];
      }

      // Convert Naver results to our format
      const results = items
        .map(item => {
          const mapx = parseInt(item.mapx);
          const mapy = parseInt(item.mapy);

          if (!mapx || !mapy) {
            return null;
          }

          // Convert Naver coordinates to WGS84
          const longitude = mapx / 10000000.0;
          const latitude = mapy / 10000000.0;

          // Remove HTML tags
          const name = item.title.replace(/<[^>]*>/g, '').replace(/&quot;/g, '"').replace(/&amp;/g, '&');
          const address = item.roadAddress || item.address || '';

          return {
            name: name,
            address: address,
            roadAddress: item.roadAddress || '',
            latitude: latitude,
            longitude: longitude,
            category: item.category || ''
          };
        })
        .filter(item => item !== null);

      console.log(`   ✓ Valid results: ${results.length}`);
      return results;

    } catch (error) {
      console.error('   ✗ Naver API error:', error);
      return [];
    }
  }

  // Search using Google Places JavaScript SDK (AutocompleteService + PlacesService)
  async function searchGooglePlaces(query) {
    return new Promise((resolve) => {
      try {
        console.log('🔍 Google Places - Starting search for:', query);

        if (!window.google || !window.google.maps || !window.google.maps.places) {
          console.error('❌ Google Maps Places library not loaded');
          resolve([]);
          return;
        }

        // Use AutocompleteService for predictions
        const autocompleteService = new google.maps.places.AutocompleteService();
        const placesService = new google.maps.places.PlacesService(document.createElement('div'));

        autocompleteService.getPlacePredictions({
          input: query,
          language: 'ko',
          componentRestrictions: { country: 'kr' }
        }, (predictions, status) => {
          if (status !== google.maps.places.PlacesServiceStatus.OK || !predictions) {
            console.log('⚠️ AutocompleteService status:', status);
            resolve([]);
            return;
          }

          console.log(`📍 Found ${predictions.length} predictions`);

          // Get details for each prediction
          const results = [];
          let completed = 0;
          const maxResults = Math.min(predictions.length, 10);

          if (maxResults === 0) {
            resolve([]);
            return;
          }

          predictions.slice(0, maxResults).forEach((prediction) => {
            placesService.getDetails({
              placeId: prediction.place_id,
              fields: ['name', 'formatted_address', 'geometry', 'types']
            }, (place, detailStatus) => {
              if (detailStatus === google.maps.places.PlacesServiceStatus.OK && place && place.geometry) {
                results.push({
                  name: place.name || prediction.description,
                  address: place.formatted_address || prediction.description,
                  roadAddress: place.formatted_address || prediction.description,
                  latitude: place.geometry.location.lat(),
                  longitude: place.geometry.location.lng(),
                  category: (place.types || []).join(', ')
                });
              }

              completed++;
              if (completed === maxResults) {
                console.log(`✅ Google Places - Found ${results.length} valid results`);
                resolve(results);
              }
            });
          });
        });
      } catch (error) {
        console.error('❌ Google Places error:', error);
        resolve([]);
      }
    });
  }

  // Search using Google Geocoding JavaScript SDK (no CORS issues)
  async function searchGoogleGeocoding(query) {
    return new Promise((resolve) => {
      try {
        if (!window.google || !window.google.maps || !window.google.maps.Geocoder) {
          console.error('❌ Google Maps Geocoder not loaded');
          resolve([]);
          return;
        }

        const geocoder = new google.maps.Geocoder();

        geocoder.geocode({
          address: query,
          language: 'ko',
          region: 'KR'
        }, (results, status) => {
          if (status === 'OK' && results) {
            const places = results.map(result => {
              return {
                name: result.formatted_address,
                address: result.formatted_address,
                roadAddress: result.formatted_address,
                latitude: result.geometry.location.lat(),
                longitude: result.geometry.location.lng(),
                category: (result.types || []).join(', ')
              };
            });

            console.log(`✅ Google Geocoding - Found ${places.length} results`);
            resolve(places);
          } else {
            console.log(`⚠️ Google Geocoding status: ${status}`);
            resolve([]);
          }
        });
      } catch (error) {
        console.error('❌ Google Geocoding error:', error);
        resolve([]);
      }
    });
  }

  console.log('✅ Naver Map Bridge: Ready (with Google Places/Geocoding search support)');

  // Message-based command handler for postMessage API
  window.addEventListener('message', async function(event) {
    try {
      const data = event.data;
      if (!data || typeof data !== 'object') return;
      if (!data.type || !data.channel || data.channel !== 'naver_map_bridge') return;

      const { type, payload } = data;
      if (type === 'naver_map_init') {
        const { divId, centerLat, centerLng, zoom } = payload || {};
        window.initNaverMap(divId, centerLat, centerLng, zoom);
      } else if (type === 'naver_map_update_overlays') {
        const { divId, lat, lng, radiusMeters } = payload || {};
        window.updateNaverMapOverlays(divId, lat, lng, radiusMeters);
      } else if (type === 'naver_map_move_camera') {
        const { divId, lat, lng } = payload || {};
        window.moveNaverMapCamera(divId, lat, lng);
      } else if (type === 'naver_search') {
        const { requestId, query } = payload || {};
        let results = [];
        try {
          results = await window.searchNaverPlaces(query);
        } catch (e) {
          console.error('❌ searchNaverPlaces error:', e);
        }
        // Respond back with results
        window.parent.postMessage({
          channel: 'naver_map_bridge',
          type: 'naver_search_result',
          requestId: requestId,
          results: results,
        }, '*');
      }
    } catch (err) {
      console.error('❌ postMessage handler error:', err);
    }
  });
})();
