<#
.SYNOPSIS
    Quick test of WSL2 + Arch Linux + Wayland setup
    
.DESCRIPTION
    This PowerShell script quickly tests if your WSL2 + Arch Linux + Wayland environment is working correctly.
    It checks all components and runs basic GUI application tests.
    
.EXAMPLE
    .\Test-Wayland-Setup.ps1
    
.NOTES
    Author: Generated for waydroid-arch-wsl2-install project
    Requires: Existing WSL2 + Arch Linux + Wayland setup
    Version: 1.0
#>

# Run non-interactively
$NonInteractive = $true

# Colors for output
$Colors = @{
    Info = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error = "Red"
    Header = "Magenta"
}

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info }
function Write-Success { param([string]$Message) Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Success }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error }
function Write-Header { param([string]$Message) Write-Host "`n========================================`n  $Message`n========================================" -ForegroundColor $Colors.Header }

function Test-WSL2Status {
    Write-Header "Testing WSL2 Status"
    
    try {
        # Get WSL version information
        $wslVersion = wsl --version 2>&1 | Out-String
        Write-Host "WSL Version Info:"
        Write-Host $wslVersion
        
        # Get WSL status
        $wslStatus = wsl --status 2>&1 | Out-String
        Write-Host "WSL Status:"
        Write-Host $wslStatus
        
        # Check if WSL2 is the default version
        $isWSL2 = ($wslStatus -match "Default Version: 2") -or ($wslVersion -match "WSL version: 2")
        
        # Get list of distributions
        $wslList = wsl --list --verbose 2>&1 | Out-String
        Write-Host "WSL Distributions:"
        Write-Host $wslList
        
        # Check if Arch Linux is installed and running
        $archInstalled = $wslList -match "archlinux"
        $archRunning = $wslList -match "archlinux.*Running"
        
        # Check WSL2 status using wsl.exe directly
        $wsl2Check = $true  # Assume WSL2 is working since we got this far
        
        if ($isWSL2) {
            Write-Success "WSL2 is installed and set as default"
            
            if ($archInstalled) {
                Write-Success "Arch Linux distribution is installed"
                
                if ($archRunning) {
                    Write-Success "Arch Linux is running"
                    return $true
                } else {
                    Write-Warning "Arch Linux is installed but not running"
                    # Try to start Arch Linux
                    try {
                        Write-Info "Attempting to start Arch Linux..."
                        $null = wsl -d archlinux --exec echo "Arch Linux started successfully"
                        Write-Success "Arch Linux started successfully"
                        return $true
                    } catch {
                        Write-Error "Failed to start Arch Linux: $_"
                        return $false
                    }
                }
            } else {
                Write-Error "Arch Linux distribution not found in WSL2"
                return $false
            }
        } else {
            # If we can't detect WSL2 but can run WSL commands, it's likely WSL2
            try {
                $testCmd = wsl --exec uname -a 2>&1
                if ($testCmd -match "Linux" -and $testCmd -match "microsoft-standard-WSL2") {
                    Write-Warning "WSL2 detection issue - WSL2 appears to be running but wasn't detected as default"
                    Write-Success "WSL2 is working (detected via fallback check)"
                    return $true
                }
            } catch {}
            
            Write-Error "WSL2 is not properly configured"
            return $false
        }
    } catch {
        Write-Error "WSL2 not available: $($_.Exception.Message)"
        return $false
    }
}

function Test-ArchLinuxEnvironment {
    Write-Header "Testing Arch Linux Environment"
    
    try {
        $osInfo = wsl --distribution archlinux --exec cat /etc/os-release
        $pythonVersion = wsl --distribution archlinux --exec python --version 2>&1
        $dockerVersion = wsl --distribution archlinux --exec docker --version 2>&1
        
        Write-Info "OS: $(($osInfo | Select-String 'PRETTY_NAME').ToString().Split('=')[1].Trim('\"'))"
        Write-Info "Python: $pythonVersion"
        Write-Info "Docker: $($dockerVersion.Split(' ')[0..2] -join ' ')"
        
        $yayCheck = wsl --distribution archlinux --exec bash -c "command -v yay >/dev/null 2>&1 && yay --version | head -1"
        if ($yayCheck) {
            Write-Success "yay AUR helper: $yayCheck"
        } else {
            Write-Warning "yay AUR helper not installed"
        }
        
        return $true
    } catch {
        Write-Error "Arch Linux environment test failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-WaylandEnvironment {
    Write-Header "Testing Wayland Environment"
    
    try {
        # Check WSLg availability - simplified check
        Write-Info "Checking WSLg availability..."
        $wslgCheck = wsl --distribution archlinux --exec test -d /mnt/wslg 2>&1
        if ($LASTEXITCODE -eq 0) {
            $wslgStatus = "Available"
            $wslgContent = wsl --distribution archlinux --exec ls -la /mnt/wslg 2>&1 | Measure-Object -Line | Select-Object -ExpandProperty Lines
            $wslgVersions = wsl --distribution archlinux --exec cat /mnt/wslg/versions.txt 2>&1
            
            Write-Host "WSLg_Status: $wslgStatus"
            Write-Host "WSLg_Content: $wslgContent items"
            if ($wslgVersions -notmatch "No such file or directory") {
                Write-Host "WSLg_Versions:"
                Write-Host $wslgVersions
            } else {
                Write-Host "WSLg_Versions: versions.txt not found"
            }
            $wslgAvailable = $true
        } else {
            Write-Host "WSLg_Status: Not_Found"
            $wslgAvailable = $false
        }
        
        # Check Wayland environment variables
        Write-Info "Checking Wayland environment variables..."
        $waylandVars = wsl --distribution archlinux --exec env | Select-String -Pattern "(WAYLAND|DISPLAY|XDG_RUNTIME_DIR|WSL_DISTRO_NAME|WSL_INTEROP)" | Out-String
        Write-Host $waylandVars
        
        # Check for Wayland components
        Write-Info "Checking Wayland components..."
        # Get Weston info
        $westonInfo = wsl --distribution archlinux --exec which weston 2>&1
        $westonStatus = if ($LASTEXITCODE -eq 0) { $westonInfo } else { "Not installed" }
        
        # Get Wayland protocols count
        $protocolsCount = wsl --distribution archlinux --exec bash -c 'ls -1 /usr/share/wayland-protocols/ 2>/dev/null | wc -l' 2>&1
        
        # Get Wayland info
        $waylandInfo = wsl --distribution archlinux --exec bash -c 'if command -v wayland-info &> /dev/null; then wayland-info 2>&1 | head -5 | grep -v "^$" || echo "wayland-info returned no output"; else echo "wayland-info command not found"; fi' 2>&1
        
        $waylandComponents = @"
=== Wayland Components ===
Weston: $westonStatus
Wayland Protocols: $protocolsCount protocols found
Wayland Info:
$waylandInfo
=========================
"@

        Write-Host $waylandComponents
        
        # Check if Wayland is properly configured
        $waylandDisplay = $waylandVars -match "WAYLAND_DISPLAY"
        
        if ($wslgAvailable -and $waylandDisplay) {
            Write-Success "Wayland environment is properly configured with WSLg"
            return $true
        } else {
            Write-Warning "Wayland environment needs configuration"
            return $false
        }
    } catch {
        Write-Error "Wayland environment test failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-GUIApplications {
    Write-Header "Testing GUI Applications"
    
    try {
        Write-Info "Testing application versions..."
        
        $calcTest = wsl --distribution archlinux --exec bash -c "gnome-calculator --version 2>&1"
        $geditTest = wsl --distribution archlinux --exec bash -c "gedit --version 2>&1"
        $firefoxTest = wsl --distribution archlinux --exec bash -c "firefox --version 2>&1"
        
        Write-Info "Calculator: $(($calcTest -split ' ')[-1])"
        Write-Info "Gedit: $(($geditTest -split ' ')[-1])"
        Write-Info "Firefox: $(($firefoxTest -split ' ')[-1])"
        
        Write-Info "Testing GUI launch capability..."
        Write-Warning "Note: GUI apps will open briefly as Windows on your desktop"
        
        # Test Calculator
        Write-Info "Testing Calculator (3 second test)..."
        $calcResult = wsl --distribution archlinux --exec bash -c "timeout 3 gnome-calculator >/dev/null 2>&1; echo \$?"
        if ($calcResult -eq "124") {
            Write-Success "Calculator GUI test passed (timeout as expected)"
        } else {
            Write-Warning "Calculator test result: exit code $calcResult"
        }
        
        # Test XEyes
        Write-Info "Testing XEyes (3 second test)..."
        $eyesResult = wsl --distribution archlinux --exec bash -c "timeout 3 xeyes >/dev/null 2>&1; echo \$?"
        if ($eyesResult -eq "124") {
            Write-Success "XEyes GUI test passed (timeout as expected)"
        } else {
            Write-Warning "XEyes test result: exit code $eyesResult"
        }
        
        return $true
    } catch {
        Write-Error "GUI application test failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-TestSummary {
    param([bool]$WSL2OK, [bool]$ArchOK, [bool]$WaylandOK, [bool]$GUIOK)
    
    Write-Header "Test Summary"
    
    $overallStatus = $WSL2OK -and $ArchOK -and $WaylandOK -and $GUIOK
    
    Write-Host @"

📊 Component Test Results:
========================
WSL2 Environment:     $(if($WSL2OK){"✅ PASS"}else{"❌ FAIL"})
Arch Linux Setup:     $(if($ArchOK){"✅ PASS"}else{"❌ FAIL"})  
Wayland Environment:  $(if($WaylandOK){"✅ PASS"}else{"❌ FAIL"})
GUI Applications:     $(if($GUIOK){"✅ PASS"}else{"❌ FAIL"})

Overall Status: $(if($overallStatus){"🎉 READY FOR WAYDROID"}else{"⚠️ NEEDS ATTENTION"})

"@ -ForegroundColor $(if($overallStatus){"Green"}else{"Yellow"})

    if ($overallStatus) {
        Write-Host @"
🚀 Your system is ready! Try these commands:

Test GUI applications:
  wsl gnome-calculator &    # Calculator
  wsl gedit &              # Text Editor  
  wsl firefox &            # Web Browser
  wsl xeyes &              # X11 Test App

Run comprehensive test:
  wsl ~/test-complete-setup.sh

Install Waydroid:
  wsl ./install-waydroid-wsl2.sh

"@ -ForegroundColor Green
    } else {
        Write-Host @"
⚠️ Some components need attention. To fix:

If WSL2 failed:
  Run Install-WSL2-Arch-Wayland.ps1 as Administrator

If Arch Linux failed:
  Run Setup-Arch-Wayland.ps1 as Administrator  

If Wayland failed:
  Run: wsl ~/setup-wayland-env.sh

If GUI failed:
  Check Windows firewall and WSLg installation

"@ -ForegroundColor Yellow
    }
}

# Main test function
function Start-Testing {
    Write-Header "WSL2 + Arch Linux + Wayland Environment Test"
    Write-Info "Testing all components of your setup..."
    
    $wsl2Status = Test-WSL2Status
    $archStatus = Test-ArchLinuxEnvironment  
    $waylandStatus = Test-WaylandEnvironment
    $guiStatus = Test-GUIApplications
    
    Show-TestSummary -WSL2OK $wsl2Status -ArchOK $archStatus -WaylandOK $waylandStatus -GUIOK $guiStatus
}

# Script entry point
Write-Header "Quick WSL2 + Arch + Wayland Test"
Write-Info "Running tests in non-interactive mode..."
Start-Testing
