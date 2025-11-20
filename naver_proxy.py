#!/usr/bin/env python3
"""
Simple Python proxy server for Naver Local Search API
This bypasses CORS restrictions for web browsers
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.request
import urllib.parse
import json

NAVER_CLIENT_ID = 'quSL_7O8Nb5bh6hK4Kj2'
NAVER_CLIENT_SECRET = 'raJroLJaYw'
PORT = 3000

class ProxyHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        """Handle GET request for /api/search/local"""
        if not self.path.startswith('/api/search/local'):
            self.send_error(404, 'Not Found')
            return

        try:
            # Parse query parameters from URL
            parsed_url = urllib.parse.urlparse(self.path)
            query_params = urllib.parse.parse_qs(parsed_url.query)

            query = query_params.get('query', [''])[0]
            display = query_params.get('display', ['10'])[0]
            start = query_params.get('start', ['1'])[0]
            sort = query_params.get('sort', ['random'])[0]

            if not query:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Query is required'}).encode())
                return

            print(f"🔍 GET request - Searching for: {query}")

            # Call Naver API
            naver_url = f"https://openapi.naver.com/v1/search/local.json?query={urllib.parse.quote(query)}&display={display}&start={start}&sort={sort}"

            req = urllib.request.Request(naver_url)
            req.add_header('X-Naver-Client-Id', NAVER_CLIENT_ID)
            req.add_header('X-Naver-Client-Secret', NAVER_CLIENT_SECRET)

            with urllib.request.urlopen(req) as response:
                result = response.read()
                print(f"✅ Naver API response: {response.status}")

                self.send_response(response.status)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(result)

        except urllib.error.HTTPError as e:
            print(f"❌ HTTP Error: {e.code}")
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(e.read())

        except Exception as e:
            print(f"❌ Error: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_POST(self):
        """Handle POST request"""
        if self.path != '/search':
            self.send_error(404, 'Not Found')
            return

        # Read request body
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)

        try:
            data = json.loads(body.decode('utf-8'))
            query = data.get('query', '')
            display = data.get('display', 10)

            if not query:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Query is required'}).encode())
                return

            print(f"🔍 Searching for: {query}")

            # Call Naver API
            naver_url = f"https://openapi.naver.com/v1/search/local.json?query={urllib.parse.quote(query)}&display={display}"

            req = urllib.request.Request(naver_url)
            req.add_header('X-Naver-Client-Id', NAVER_CLIENT_ID)
            req.add_header('X-Naver-Client-Secret', NAVER_CLIENT_SECRET)

            with urllib.request.urlopen(req) as response:
                result = response.read()
                print(f"✅ Naver API response: {response.status}")

                self.send_response(response.status)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(result)

        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Invalid JSON'}).encode())

        except urllib.error.HTTPError as e:
            print(f"❌ HTTP Error: {e.code}")
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(e.read())

        except Exception as e:
            print(f"❌ Error: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def log_message(self, format, *args):
        """Custom logging"""
        return  # Suppress default logging

if __name__ == '__main__':
    server = HTTPServer(('localhost', PORT), ProxyHandler)
    print(f"🚀 Naver Local Search Proxy Server running on http://localhost:{PORT}")
    print(f"📡 Endpoint: POST http://localhost:{PORT}/search")
    print(f"   Body: {{ \"query\": \"검색어\" }}")
    print("Press Ctrl+C to stop")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
        server.shutdown()
