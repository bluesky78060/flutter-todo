#!/usr/bin/env python3
import http.server
import socketserver
import os
from pathlib import Path

PORT = 9000
DIRECTORY = "build/app/outputs/flutter-apk"

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        # Cache control
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            
            # List APK files
            apk_files = list(Path(DIRECTORY).glob('*.apk'))
            
            html = f'''
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>DoDo APK 다운로드</title>
                <style>
                    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
                    body {{
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                        background: linear-gradient(135deg, #1a1f2e 0%, #2d3748 100%);
                        color: #ffffff;
                        min-height: 100vh;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        padding: 20px;
                    }}
                    .container {{
                        background: rgba(45, 55, 72, 0.8);
                        backdrop-filter: blur(10px);
                        border-radius: 20px;
                        padding: 40px;
                        max-width: 600px;
                        width: 100%;
                        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
                    }}
                    h1 {{
                        font-size: 2.5em;
                        margin-bottom: 10px;
                        background: linear-gradient(135deg, #2B8DEE 0%, #1E6BB8 100%);
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        background-clip: text;
                    }}
                    .subtitle {{
                        color: #92ADC9;
                        margin-bottom: 30px;
                        font-size: 1.1em;
                    }}
                    .apk-list {{
                        list-style: none;
                    }}
                    .apk-item {{
                        background: rgba(26, 31, 46, 0.6);
                        border-radius: 12px;
                        padding: 20px;
                        margin-bottom: 15px;
                        transition: transform 0.2s, box-shadow 0.2s;
                    }}
                    .apk-item:hover {{
                        transform: translateY(-2px);
                        box-shadow: 0 10px 30px rgba(43, 141, 238, 0.3);
                    }}
                    .apk-name {{
                        font-size: 1.2em;
                        font-weight: 600;
                        margin-bottom: 10px;
                        color: #ffffff;
                    }}
                    .apk-info {{
                        color: #92ADC9;
                        font-size: 0.9em;
                        margin-bottom: 15px;
                    }}
                    .download-btn {{
                        display: inline-block;
                        background: linear-gradient(135deg, #2B8DEE 0%, #1E6BB8 100%);
                        color: white;
                        padding: 12px 30px;
                        border-radius: 8px;
                        text-decoration: none;
                        font-weight: 600;
                        transition: transform 0.2s, box-shadow 0.2s;
                        box-shadow: 0 4px 12px rgba(43, 141, 238, 0.3);
                    }}
                    .download-btn:hover {{
                        transform: scale(1.05);
                        box-shadow: 0 6px 20px rgba(43, 141, 238, 0.5);
                    }}
                    .instructions {{
                        background: rgba(255, 153, 51, 0.1);
                        border-left: 4px solid #FF9933;
                        padding: 15px;
                        border-radius: 8px;
                        margin-top: 30px;
                    }}
                    .instructions h3 {{
                        color: #FF9933;
                        margin-bottom: 10px;
                        font-size: 1.1em;
                    }}
                    .instructions ol {{
                        margin-left: 20px;
                        color: #92ADC9;
                        line-height: 1.6;
                    }}
                    .instructions li {{
                        margin-bottom: 8px;
                    }}
                    .qr-section {{
                        text-align: center;
                        margin-top: 30px;
                        padding: 20px;
                        background: rgba(26, 31, 46, 0.4);
                        border-radius: 12px;
                    }}
                    .qr-section p {{
                        color: #92ADC9;
                        margin-bottom: 15px;
                    }}
                    @media (max-width: 600px) {{
                        .container {{ padding: 25px; }}
                        h1 {{ font-size: 2em; }}
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🎯 DoDo APK</h1>
                    <div class="subtitle">Todo 앱 다운로드</div>
                    
                    <ul class="apk-list">
            '''
            
            for apk_file in apk_files:
                file_size = apk_file.stat().st_size / (1024 * 1024)  # MB
                html += f'''
                        <li class="apk-item">
                            <div class="apk-name">{apk_file.name}</div>
                            <div class="apk-info">📦 크기: {file_size:.1f} MB</div>
                            <a href="/{apk_file.name}" class="download-btn" download>
                                ⬇️ 다운로드
                            </a>
                        </li>
                '''
            
            html += '''
                    </ul>
                    
                    <div class="qr-section">
                        <p>📱 모바일에서 이 주소로 접속하세요:</p>
                        <p style="font-size: 1.2em; font-weight: 600; color: #2B8DEE;">
                            http://YOUR_IP:9000
                        </p>
                    </div>
                    
                    <div class="instructions">
                        <h3>📋 설치 방법</h3>
                        <ol>
                            <li>위 다운로드 버튼을 클릭하여 APK 파일 다운로드</li>
                            <li>다운로드한 APK 파일 실행</li>
                            <li>"알 수 없는 출처" 허용 (필요시)</li>
                            <li>설치 진행</li>
                            <li>앱 실행 및 알림 권한 허용</li>
                        </ol>
                    </div>
                </div>
            </body>
            </html>
            '''
            
            self.wfile.write(html.encode('utf-8'))
        else:
            super().do_GET()

Handler = MyHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"✅ 서버 시작됨: http://localhost:{PORT}")
    print(f"📱 모바일에서 접속: http://YOUR_IP:{PORT}")
    print(f"📂 제공 디렉토리: {DIRECTORY}")
    print("\n🛑 종료하려면 Ctrl+C를 누르세요\n")
    httpd.serve_forever()
