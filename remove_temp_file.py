import subprocess
import os

os.chdir(r'c:\Users\T490\Documents\modulo-vault\devops-capstone-project')
result = subprocess.run(['git', 'rm', '--cached', '%TEMP%/check_pr.py'], capture_output=True, text=True)
print('STDOUT:', result.stdout)
print('STDERR:', result.stderr)
print('RC:', result.returncode)
