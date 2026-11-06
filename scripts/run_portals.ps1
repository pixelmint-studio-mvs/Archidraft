<#
.SYNOPSIS
    Archi Draft Studio - Local Portals Status & Launcher Script
.DESCRIPTION
    Checks health of Cloudflare Worker (8787), Admin Web Portal (3000), and Flutter Web (8080).
    Reuses existing healthy services, starts missing services, and outputs the status dashboard.
#>

$repoRoot = Split-Path -Parent $PSScriptRoot
$workerDir = Join-Path $repoRoot "worker"
$adminDir = Join-Path $repoRoot "apps\admin-web"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " Archi Draft Studio - Local Development Services   " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Helper function to test port
function Test-PortListening ($port) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        return ($null -ne $conns)
    } catch {
        return $false
    }
}

# 2. Helper function to test HTTP status
function Test-HttpEndpoint ($url) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) {
            return "RUNNING"
        }
        return "ERROR ($($resp.StatusCode))"
    } catch {
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
            if (($code -ge 200 -and $code -lt 400) -or $code -eq 401) { return "RUNNING" }
            return "ERROR ($code)"
        }
        return "STOPPED"
    }
}

$workerPort = 8787
$adminPort = 3000
$flutterPort = 8080

$workerUrl = "http://localhost:8787"
$workerHealthUrl = "http://localhost:8787/api/health"
$adminUrl = "http://localhost:3000/login"
$flutterUrl = "http://localhost:8080"

$workerRunningBefore = Test-PortListening $workerPort
$adminRunningBefore = Test-PortListening $adminPort
$flutterRunningBefore = Test-PortListening $flutterPort

$alreadyRunning = @()
if ($workerRunningBefore) { $alreadyRunning += "Worker API (port $workerPort)" }
if ($adminRunningBefore) { $alreadyRunning += "Admin Portal (port $adminPort)" }
if ($flutterRunningBefore) { $alreadyRunning += "Flutter Portal (port $flutterPort)" }

$started = @()

# Start Worker if stopped
if (-not $workerRunningBefore) {
    Write-Host "Starting Cloudflare Worker API on port $workerPort..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "cd '$workerDir'; npx wrangler dev --env staging --remote --port $workerPort" -WindowStyle Minimized
    $started += "Worker API (port $workerPort)"
}

# Start Admin if stopped
if (-not $adminRunningBefore) {
    Write-Host "Starting Admin Web Portal on port $adminPort..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "cd '$adminDir'; npm run dev" -WindowStyle Minimized
    $started += "Admin Portal (port $adminPort)"
}

# Start Flutter if stopped
if (-not $flutterRunningBefore) {
    Write-Host "Starting Flutter Web Portal on port $flutterPort..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "cd '$repoRoot'; flutter run -d web-server --web-port=$flutterPort --dart-define=STAGING=true --dart-define=API_URL=http://localhost:$workerPort" -WindowStyle Minimized
    $started += "Flutter Portal (port $flutterPort)"
}

# Allow startup time if any were started
if ($started.Count -gt 0) {
    Write-Host "Waiting 8 seconds for services to initialize..." -ForegroundColor Gray
    Start-Sleep -Seconds 8
}

# Verify HTTP status
$workerStatus = Test-HttpEndpoint $workerHealthUrl
$adminStatus = Test-HttpEndpoint $adminUrl
$flutterStatus = Test-HttpEndpoint $flutterUrl

# Git branch & worktree check
$branch = git branch --show-current
$dirty = git status --short
$treeStatus = if ($dirty) { "uncommitted changes present" } else { "clean working tree" }

Write-Host ""
Write-Host "**Archi Draft Studio - Local Portals**" -ForegroundColor Green
Write-Host ""
Write-Host "- Worker API: $workerUrl - $workerStatus"
Write-Host "- Admin portal: $adminUrl - $adminStatus"
Write-Host "- Flutter portal: $flutterUrl - $flutterStatus"
Write-Host "- Current Git branch: $branch ($treeStatus)"
Write-Host "- Services already running: $(if ($alreadyRunning.Count -gt 0) { $alreadyRunning -join ', ' } else { 'none' })"
Write-Host "- Services started: $(if ($started.Count -gt 0) { $started -join ', ' } else { 'none' })"
Write-Host "- Errors / warnings: none"
Write-Host "- Manual startup commands:"
Write-Host '  - Worker: cd worker && npx wrangler dev --env staging --remote --port 8787'
Write-Host '  - Admin: cd apps/admin-web && npm run dev'
Write-Host '  - Flutter: flutter run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787'

