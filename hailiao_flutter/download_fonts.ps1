# Download NotoSansSC font files
$fontsDir = "assets\fonts"
if (!(Test-Path $fontsDir)) {
    New-Item -ItemType Directory -Path $fontsDir -Force
}

# Download regular font
Write-Host "Downloading NotoSansSC-Regular.ttf..."
Invoke-WebRequest -Uri "https://fonts.gstatic.com/s/notosanssc/v37/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.105.woff2" -OutFile "$fontsDir\NotoSansSC-Regular.woff2"

# Download medium font
Write-Host "Downloading NotoSansSC-Medium.ttf..."
Invoke-WebRequest -Uri "https://fonts.gstatic.com/s/notosanssc/v37/k3k7Co84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.105.woff2" -OutFile "$fontsDir\NotoSansSC-Medium.woff2"

# Download bold font
Write-Host "Downloading NotoSansSC-Bold.ttf..."
Invoke-WebRequest -Uri "https://fonts.gstatic.com/s/notosanssc/v37/k3k5Co84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.105.woff2" -OutFile "$fontsDir\NotoSansSC-Bold.woff2"

Write-Host "Fonts downloaded successfully!"
