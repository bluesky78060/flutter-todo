#!/usr/bin/env python3
"""
Simple HTTP server for APK download
Usage: python3 download_server.py
"""

import http.server
import socketserver
import os
import socket
from pathlib import Path

# Configuration
PORT = 9000
APK_DIR = Path("build/app/outputs/flutter-apk")
APK_FILE = "app-release.apk"

class APKDownloadHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler for APK downloads with nice UI"""

    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_html_page()
        elif self.path == '/download':
            self.download_apk()
        elif self.path == '/info':
            self.show_apk_info()
        else:
            super().do_GET()

    def send_html_page(self):
        """Send the main download page"""
        apk_path = APK_DIR / APK_FILE

        if not apk_path.exists():
            self.send_error(404, "APK file not found")
            return

        # Get file info
        file_size = apk_path.stat().st_size
        file_size_mb = file_size / (1024 * 1024)

        # Get local IP
        local_ip = get_local_ip()

        html_content = f"""
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DoDo 앱 다운로드</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }}

        .container {{
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            text-align: center;
        }}

        .logo {{
            font-size: 80px;
            margin-bottom: 20px;
        }}

        h1 {{
            color: #333;
            font-size: 32px;
            margin-bottom: 10px;
        }}

        .subtitle {{
            color: #666;
            font-size: 16px;
            margin-bottom: 30px;
        }}

        .info-box {{
            background: #f8f9fa;
            border-radius: 12px;
            padding: 20px;
            margin: 30px 0;
            text-align: left;
        }}

        .info-item {{
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }}

        .info-item:last-child {{
            border-bottom: none;
        }}

        .info-label {{
            color: #666;
            font-weight: 500;
        }}

        .info-value {{
            color: #333;
            font-weight: 600;
        }}

        .download-btn {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 50px;
            padding: 18px 50px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
        }}

        .download-btn:hover {{
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }}

        .download-btn:active {{
            transform: translateY(0);
        }}

        .secondary-btn {{
            background: white;
            color: #667eea;
            border: 2px solid #667eea;
        }}

        .secondary-btn:hover {{
            background: #f8f9fa;
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.2);
        }}

        .qr-section {{
            margin-top: 30px;
            padding-top: 30px;
            border-top: 2px solid #e0e0e0;
        }}

        .qr-title {{
            color: #666;
            font-size: 14px;
            margin-bottom: 15px;
        }}

        .qr-code {{
            background: white;
            padding: 20px;
            border-radius: 12px;
            display: inline-block;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }}

        .network-info {{
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 12px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
        }}

        .steps {{
            text-align: left;
            margin: 30px 0;
            background: #e3f2fd;
            padding: 20px;
            border-radius: 12px;
        }}

        .steps h3 {{
            color: #1976d2;
            margin-bottom: 15px;
        }}

        .steps ol {{
            padding-left: 20px;
        }}

        .steps li {{
            color: #333;
            margin: 10px 0;
            line-height: 1.6;
        }}

        .footer {{
            margin-top: 30px;
            color: #999;
            font-size: 14px;
        }}

        @media (max-width: 600px) {{
            .container {{
                padding: 30px 20px;
            }}

            h1 {{
                font-size: 24px;
            }}

            .download-btn {{
                width: 100%;
                margin: 10px 0;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📱</div>
        <h1>DoDo 앱 다운로드</h1>
        <p class="subtitle">할 일 관리가 쉬워지는 순간</p>

        <div class="info-box">
            <div class="info-item">
                <span class="info-label">📦 파일 크기</span>
                <span class="info-value">{file_size_mb:.1f} MB</span>
            </div>
            <div class="info-item">
                <span class="info-label">📱 버전</span>
                <span class="info-value">1.0.0+1</span>
            </div>
            <div class="info-item">
                <span class="info-label">🤖 플랫폼</span>
                <span class="info-value">Android 6.0+</span>
            </div>
            <div class="info-item">
                <span class="info-label">🔐 서명</span>
                <span class="info-value">Debug (테스트용)</span>
            </div>
        </div>

        <a href="/download" class="download-btn">
            ⬇️ APK 다운로드
        </a>

        <a href="/info" class="download-btn secondary-btn">
            ℹ️ 상세 정보
        </a>

        <div class="network-info">
            <strong>📡 네트워크 주소</strong><br>
            같은 Wi-Fi에 연결된 기기에서 접속하세요:<br>
            <strong>http://{local_ip}:{PORT}</strong>
        </div>

        <div class="steps">
            <h3>📲 설치 방법</h3>
            <ol>
                <li>위의 "APK 다운로드" 버튼 클릭</li>
                <li>다운로드된 APK 파일 열기</li>
                <li>"제공처를 알 수 없는 앱" 설치 허용</li>
                <li>설치 진행 및 완료</li>
            </ol>
        </div>

        <div class="qr-section">
            <div class="qr-title">📱 모바일에서 QR 코드로 접속</div>
            <div class="qr-code">
                <svg width="200" height="200" viewBox="0 0 200 200">
                    <rect width="200" height="200" fill="white"/>
                    <text x="100" y="100" text-anchor="middle"
                          font-size="16" fill="#666">
                        QR Code Generator
                    </text>
                    <text x="100" y="120" text-anchor="middle"
                          font-size="12" fill="#999">
                        http://{local_ip}:{PORT}
                    </text>
                </svg>
            </div>
            <p style="color: #666; font-size: 12px; margin-top: 10px;">
                QR 코드 생성기를 사용하여 위 주소로 QR 코드를 만드세요
            </p>
        </div>

        <div class="footer">
            <p>⚠️ 테스트용 APK입니다. 프로덕션 배포용이 아닙니다.</p>
            <p>© 2025 DoDo App. Built with Flutter.</p>
        </div>
    </div>
</body>
</html>
        """

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', len(html_content.encode('utf-8')))
        self.end_headers()
        self.wfile.write(html_content.encode('utf-8'))

    def download_apk(self):
        """Send the APK file for download"""
        apk_path = APK_DIR / APK_FILE

        if not apk_path.exists():
            self.send_error(404, "APK file not found")
            return

        self.send_response(200)
        self.send_header('Content-type', 'application/vnd.android.package-archive')
        self.send_header('Content-Disposition', f'attachment; filename="DoDo-v1.0.0.apk"')
        self.send_header('Content-Length', apk_path.stat().st_size)
        self.end_headers()

        with open(apk_path, 'rb') as f:
            self.wfile.write(f.read())

        print(f"✅ APK downloaded by {self.client_address[0]}")

    def show_apk_info(self):
        """Show detailed APK information"""
        apk_path = APK_DIR / APK_FILE

        if not apk_path.exists():
            self.send_error(404, "APK file not found")
            return

        file_size = apk_path.stat().st_size
        file_size_mb = file_size / (1024 * 1024)

        # Read SHA1
        sha1_path = APK_DIR / "app-release.apk.sha1"
        sha1 = "Not available"
        if sha1_path.exists():
            with open(sha1_path, 'r') as f:
                sha1 = f.read().strip()

        html_content = f"""
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DoDo 앱 상세 정보</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 40px 20px;
        }}

        .container {{
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
        }}

        h1 {{
            color: #333;
            margin-bottom: 30px;
            text-align: center;
        }}

        .info-section {{
            background: #f8f9fa;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
        }}

        .info-section h2 {{
            color: #667eea;
            margin-bottom: 15px;
            font-size: 20px;
        }}

        .info-table {{
            width: 100%;
            border-collapse: collapse;
        }}

        .info-table td {{
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }}

        .info-table td:first-child {{
            font-weight: 600;
            color: #666;
            width: 40%;
        }}

        .info-table td:last-child {{
            color: #333;
            word-break: break-all;
        }}

        .back-btn {{
            display: inline-block;
            margin-top: 30px;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            transition: transform 0.2s;
        }}

        .back-btn:hover {{
            transform: translateY(-2px);
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📋 DoDo 앱 상세 정보</h1>

        <div class="info-section">
            <h2>📦 파일 정보</h2>
            <table class="info-table">
                <tr>
                    <td>파일명</td>
                    <td>{APK_FILE}</td>
                </tr>
                <tr>
                    <td>파일 크기</td>
                    <td>{file_size_mb:.2f} MB ({file_size:,} bytes)</td>
                </tr>
                <tr>
                    <td>SHA-1 해시</td>
                    <td><code>{sha1}</code></td>
                </tr>
            </table>
        </div>

        <div class="info-section">
            <h2>📱 앱 정보</h2>
            <table class="info-table">
                <tr>
                    <td>앱 이름</td>
                    <td>DoDo</td>
                </tr>
                <tr>
                    <td>패키지명</td>
                    <td>com.example.todo_app</td>
                </tr>
                <tr>
                    <td>버전</td>
                    <td>1.0.0+1</td>
                </tr>
                <tr>
                    <td>최소 Android 버전</td>
                    <td>Android 6.0 (API 23)</td>
                </tr>
                <tr>
                    <td>대상 Android 버전</td>
                    <td>Android 14 (API 34)</td>
                </tr>
            </table>
        </div>

        <div class="info-section">
            <h2>🔨 빌드 정보</h2>
            <table class="info-table">
                <tr>
                    <td>빌드 타입</td>
                    <td>Release</td>
                </tr>
                <tr>
                    <td>서명</td>
                    <td>Debug Key (테스트용)</td>
                </tr>
                <tr>
                    <td>빌드 도구</td>
                    <td>Flutter SDK</td>
                </tr>
                <tr>
                    <td>컴파일 SDK</td>
                    <td>Android 34</td>
                </tr>
            </table>
        </div>

        <div class="info-section">
            <h2>✨ 주요 기능</h2>
            <ul style="padding-left: 20px; line-height: 2;">
                <li>할 일 추가, 수정, 삭제</li>
                <li>알림 설정</li>
                <li>다크 모드 지원</li>
                <li>Google/Kakao 소셜 로그인</li>
                <li>클라우드 동기화</li>
                <li>통계 및 진행률 확인</li>
            </ul>
        </div>

        <div style="text-align: center;">
            <a href="/" class="back-btn">← 다운로드 페이지로 돌아가기</a>
        </div>
    </div>
</body>
</html>
        """

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', len(html_content.encode('utf-8')))
        self.end_headers()
        self.wfile.write(html_content.encode('utf-8'))

def get_local_ip():
    """Get local IP address"""
    try:
        # Create a socket to get the local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "127.0.0.1"

def main():
    # Change to project directory
    project_root = Path(__file__).parent
    os.chdir(project_root)

    # Check if APK exists
    apk_path = APK_DIR / APK_FILE
    if not apk_path.exists():
        print(f"❌ Error: APK file not found at {apk_path}")
        print(f"   Please build the APK first: flutter build apk --release")
        return

    # Get local IP
    local_ip = get_local_ip()

    # Start server
    with socketserver.TCPServer(("", PORT), APKDownloadHandler) as httpd:
        print("=" * 70)
        print("🚀 DoDo APK Download Server")
        print("=" * 70)
        print(f"")
        print(f"📱 APK: {APK_FILE} ({apk_path.stat().st_size / (1024*1024):.1f} MB)")
        print(f"")
        print(f"🌐 Server URLs:")
        print(f"   Local:   http://localhost:{PORT}")
        print(f"   Network: http://{local_ip}:{PORT}")
        print(f"")
        print(f"📲 Mobile access:")
        print(f"   같은 Wi-Fi에서 접속: http://{local_ip}:{PORT}")
        print(f"")
        print(f"⚡ Quick actions:")
        print(f"   Download:  http://{local_ip}:{PORT}/download")
        print(f"   Info:      http://{local_ip}:{PORT}/info")
        print(f"")
        print("=" * 70)
        print(f"Press Ctrl+C to stop the server")
        print("=" * 70)
        print("")

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n👋 Server stopped")

if __name__ == "__main__":
    main()
