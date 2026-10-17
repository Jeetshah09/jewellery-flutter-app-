$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $projectRoot 'backend'

Start-Process -FilePath 'python' `
  -ArgumentList '-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '8003', '--reload' `
  -WorkingDirectory $backendPath

Set-Location $projectRoot
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8003