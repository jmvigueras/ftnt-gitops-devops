<powershell>
# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Git and Notepad++
choco install -y git notepadplusplus

# Create three environment variables with random 4-letter values
$chars = "abcdefghijklmnopqrstuvwxyz0123456789"
$random = New-Object System.Random

# Create text file on administrator's desktop with git remote command
$cloneRepo = "git clone https://github.com/${github_site}/__APP_NAME__.git \n"
$addOrigin = "git remote add origin https://${github_token}@github.com/${github_site}/__APP_NAME__.git"
$adminDesktop = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory)
$file = "$adminDesktop\README.txt"
New-Item -ItemType File -Path $file -Value $cloneRepo
Add-Content $file $addOrigin
</powershell>