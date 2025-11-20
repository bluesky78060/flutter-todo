// Simple Node.js proxy server for Naver Local Search API
// This bypasses CORS restrictions

const http = require('http');
const https = require('https');
const url = require('url');

const NAVER_CLIENT_ID = 'quSL_7O8Nb5bh6hK4Kj2';
const NAVER_CLIENT_SECRET = 'raJroLJaYw';
const PORT = 3000;

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method === 'POST' && req.url === '/search') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const { query, display = 10 } = JSON.parse(body);

        if (!query) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Query is required' }));
          return;
        }

        console.log(`🔍 Searching for: ${query}`);

        // Call Naver API
        const naverUrl = `https://openapi.naver.com/v1/search/local.json?query=${encodeURIComponent(query)}&display=${display}`;

        const options = {
          headers: {
            'X-Naver-Client-Id': NAVER_CLIENT_ID,
            'X-Naver-Client-Secret': NAVER_CLIENT_SECRET
          }
        };

        https.get(naverUrl, options, (naverRes) => {
          let data = '';

          naverRes.on('data', chunk => {
            data += chunk;
          });

          naverRes.on('end', () => {
            console.log(`✅ Naver API response: ${naverRes.statusCode}`);
            res.writeHead(naverRes.statusCode, { 'Content-Type': 'application/json' });
            res.end(data);
          });
        }).on('error', (error) => {
          console.error('❌ Error calling Naver API:', error);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: error.message }));
        });

      } catch (error) {
        console.error('❌ Error parsing request:', error);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`🚀 Naver Local Search Proxy Server running on http://localhost:${PORT}`);
  console.log(`📡 Endpoint: POST http://localhost:${PORT}/search`);
  console.log(`   Body: { "query": "검색어" }`);
});
