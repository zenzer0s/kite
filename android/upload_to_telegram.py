import urllib.request
import urllib.parse
import os
import sys
import mimetypes

# Configuration
BOT_TOKEN = "8177276400:AAF289B1ViCwyIAVlGf9mp6u5lriZD7n-Zk"
CHAT_ID = "2123961513"

# Get the script's directory and then find the build directory
# This script is at: android/upload_to_telegram.py
# The APK is at: build/app/outputs/apk/release/app-release.apk (where 'build' is in the project root)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# If 'android' is project_root/android, then project_root is SCRIPT_DIR/..
# APK is project_root/build/...
APK_PATH = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "build", "app", "outputs", "apk", "release", "app-release.apk"))

def upload_apk():
    if not os.path.exists(APK_PATH):
        print(f"Error: APK not found at {APK_PATH}")
        sys.exit(1)

    print(f"Uploading {APK_PATH} to Telegram using urllib...")
    
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendDocument"
    boundary = '---Boundary'
    
    # Prepare the multipart data
    body = []
    
    # Add chat_id
    body.extend([
        f'--{boundary}',
        'Content-Disposition: form-data; name="chat_id"',
        '',
        str(CHAT_ID)
    ])
    
    # Add caption
    body.extend([
        f'--{boundary}',
        'Content-Disposition: form-data; name="caption"',
        '',
        "🚀 New Release Build: app-release.apk"
    ])
    
    # Add file
    filename = os.path.basename(APK_PATH)
    with open(APK_PATH, 'rb') as f:
        file_content = f.read()
    
    body.extend([
        f'--{boundary}',
        f'Content-Disposition: form-data; name="document"; filename="{filename}"',
        f'Content-Type: {mimetypes.guess_type(APK_PATH)[0] or "application/vnd.android.package-archive"}',
        '',
        file_content
    ])
    
    body.append(f'--{boundary}--')
    body.append('')
    
    # Encode body
    def encode_body(data):
        encoded = b''
        for item in data:
            if isinstance(item, str):
                encoded += item.encode('utf-8') + b'\r\n'
            elif isinstance(item, bytes):
                encoded += item + b'\r\n'
        return encoded

    data = encode_body(body)
    
    req = urllib.request.Request(url, data=data)
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')
    req.add_header('Content-Length', len(data))
    
    try:
        with urllib.request.urlopen(req) as response:
            result = response.read().decode('utf-8')
            print("✅ Upload successful!")
            print(result)
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    upload_apk()
