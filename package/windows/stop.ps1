#Requires -Version 5.0

param (
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

#########################################################################
## START main definition

function print {
    [System.Console]::Out.Write($args[0])
    Start-Sleep -Milliseconds 100
}

## END main definition
#########################################################################
## START main execution

# 0 - success
# 1 - crash
# 2 - agent retry
trap {
    $errMsg = $_.Exception.Message

    popd

    if ($errMsg.EndsWith("agent retry")) {
        [System.Console]::Error.Write($errMsg.Substring(0, $errMsg.Length - 13))
        exit 2
    }

    [System.Console]::Error.Write($errMsg)
    exit 1
}

# check powershell #
if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw "PowerShell version 5 or higher is required"
}

# check identity #
$currentPrincipal = new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "You need elevated Administrator privileges in order to run this script, start Windows PowerShell by using the Run as Administrator option"
}

# cni #
# flanneld
try {
    $process = Get-Process -Name "flanneld*" -ErrorAction Ignore
    if ($process) {
        $process | Stop-Process | Out-Null
        print "Stopped flanneld"

        Start-Sleep -s 2
    }
} catch {
    throw "Can't stop the early flanneld process"
}

# kubelet #
try {
    $process = Get-Process -Name "kubelet*" -ErrorAction Ignore
    if ($process) {
        $process | Stop-Process | Out-Null
        print "Stopped kubelet"

        Start-Sleep -s 2
    }
} catch {
    throw "Can't stop the early kubelet process"
}

# kube-proxy #
try {
    $process = Get-Process -Name "kube-proxy*" -ErrorAction Ignore
    if ($process) {
        $process | Stop-Process | Out-Null
        print "Stopped kube-proxy"

        Start-Sleep -s 2
    }
} catch {
    throw "Can't stop the early kube-proxy process"
}

# controlplanes proxy #
try {
    $process = Get-Process -Name "nginx*" -ErrorAction Ignore
    if ($process) {
        $process | Stop-Process | Out-Null
        print "Stopped nginx"

        Start-Sleep -s 2
    }
} catch {
    throw "Can't stop the early nginx process"
}

try {
    # docker clean #
    docker ps -q | % { docker stop $_ *>$null } *>$null

    # clean up rancher parts #
    docker rm kubernetes-binaries *>$null
    docker rm cni-binaries *>$null
} catch { }


## END main execution
#########################################################################