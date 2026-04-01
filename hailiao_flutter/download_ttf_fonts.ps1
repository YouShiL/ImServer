# Download TTF font files
$fontsDir = "assets\fonts"
if (!(Test-Path $fontsDir)) {
    New-Item -ItemType Directory -Path $fontsDir -Force
}

# Download NotoSansSC-Regular.ttf
Write-Host "Downloading NotoSansSC-Regular.ttf..."
Invoke-WebRequest -Uri "https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansSC-Regular.otf" -OutFile "$fontsDir\NotoSansSC-Regular.ttf"

# Download Roboto-Regular.ttf
Write-Host "Downloading Roboto-Regular.ttf..."
Invoke-WebRequest -Uri "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf" -OutFile "$fontsDir\Roboto-Regular.ttf"

# Download Roboto-Medium.ttf
Write-Host "Downloading Roboto-Medium.ttf..."
Invoke-WebRequest -Uri "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Medium.ttf" -OutFile "$fontsDir\Roboto-Medium.ttf"

# Download Roboto-Bold.ttf
Write-Host "Downloading Roboto-Bold.ttf..."
Invoke-WebRequest -Uri "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf" -OutFile "$fontsDir\Roboto-Bold.ttf"

Write-Host "All font files downloaded successfully!"