# Modules
Import-Module Az

# Set execution location
Set-Location $PSScriptRoot

# Creating directories
If(!(test-path './logs'))
{
    New-Item -ItemType Directory -Force -Path './logs'
}

If(!(test-path './.appdata'))
{
    New-Item -ItemType Directory -Force -Path './.appdata'
    $cache = @{"lastruntime"=""}
    $cache.lastruntime = Get-Date
    $cache | ConvertTo-Json | Set-Content -Path './.appdata/runcache'
}

# Read Config
$config = Get-Content -Path './local.settings.json' -Raw | ConvertFrom-Json

# Read cache
$cache = Get-Content -Path './.appdata/runcache' -Raw | ConvertFrom-Json

# Azure Storage Params
$storage = $config.storage.account
$sastoken = $config.storage.saskey
$container = $config.storage.container
$filefilter = $config.filefilter
$localsyncpath = $config.localsyncpath

# Log settings
$logFile = $config.log.logFile
$logLevel = $config.log.logLevel # ("DEBUG","INFO","WARN","ERROR","FATAL")
$logSize = 1mb
$logCount = $config.log.logCount
# end of settings

. ./logger.ps1

Write-Log "Job Start : Configuration Loaded" "INFO"

# Storage Authentication
$context = New-AzStorageContext -StorageAccountName $storage -SasToken $sastoken

$blobs = $context | Get-AzStorageBlob -Container $container -Blob $filefilter

$blobs | ForEach-Object {
    $lastrun = [datetime]$cache.lastruntime.value
    if($_.LastModified.UtcDateTime -ge $lastrun){
       Write-Log "Start : Copying the file - $($_.Name)" "INFO"
       $context | Get-AzStorageBlobContent -Container $container -Blob $_.Name -Destination $localsyncpath
       Write-Log "Complete : Copying the file - $($_.Name)" "INFO"
    }
}

$cache.lastruntime = Get-Date
$cache | ConvertTo-Json | Set-Content -Path './.appdata/runcache'

Write-Log "Job End : updated the LastRun time" "INFO"