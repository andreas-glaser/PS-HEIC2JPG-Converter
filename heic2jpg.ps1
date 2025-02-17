param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDirectory,

    # Recurse is disabled by default; add -Recurse to process subdirectories.
    [switch]$Recurse,

    # Original file is moved to the Recycle Bin by default. Use -MoveToTrash:$false to keep originals.
    [bool]$MoveToTrash = $true,

    # Enable logging if specified; log files are created in the same directory as the script.
    [switch]$EnableLogging,

    # File extension filter for input files.
    [string]$InputExtension = "*.heic",

    # Output extension (e.g. .jpg).
    [string]$OutputExtension = ".jpg",

    # JPEG quality for ImageMagick conversion. Ranges from 1 (lowest) to 100 (highest quality). Default is 95.
    [ValidateRange(1,100)]
    [int]$Quality = 95
)

#region Helper Functions
function Get-UniqueFilename {
    param (
        [string]$Directory,
        [string]$BaseName,
        [string]$Extension
    )
    $outputFile = Join-Path $Directory ("{0}{1}" -f $BaseName, $Extension)
    if (-not (Test-Path $outputFile)) {
        return $outputFile
    }
    $i = 1
    while (Test-Path (Join-Path $Directory ("{0} ({1}){2}" -f $BaseName, $i, $Extension))) {
        $i++
    }
    return (Join-Path $Directory ("{0} ({1}){2}" -f $BaseName, $i, $Extension))
}
#endregion

#region Parameter Validation
if (-not (Test-Path $TargetDirectory)) {
    Write-Error "Target directory '$TargetDirectory' does not exist."
    exit
}

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Error "ImageMagick's 'magick' command is not available. Please ensure it is installed and in your system's PATH."
    exit
}
#endregion

#region Build File List & Display Files
if ($Recurse) {
    $fileList = Get-ChildItem -Path $TargetDirectory -Filter $InputExtension -Recurse
} else {
    $fileList = Get-ChildItem -Path $TargetDirectory -Filter $InputExtension
}

$totalFiles = $fileList.Count
if ($totalFiles -eq 0) {
    Write-Host "No files found in '$TargetDirectory' matching '$InputExtension'." -ForegroundColor Yellow
    exit
}

Write-Host "Found $totalFiles file(s) to convert." -ForegroundColor Green

if ($totalFiles -le 10) {
    Write-Host "Files to be converted:" -ForegroundColor Cyan
    $fileList | ForEach-Object { Write-Host $_.FullName }
} else {
    Write-Host "Files to be converted (first 10):" -ForegroundColor Cyan
    $fileList[0..9] | ForEach-Object { Write-Host $_.FullName }
    Write-Host "And $($totalFiles - 10) more files..."
}
#endregion

#region Parameter Summary & Confirmation
$params = @(
    [PSCustomObject]@{ Parameter = "Target Directory"; Value = $TargetDirectory },
    [PSCustomObject]@{ Parameter = "Recurse"; Value = $Recurse },
    [PSCustomObject]@{ Parameter = "Move To Trash"; Value = $MoveToTrash },
    [PSCustomObject]@{ Parameter = "Enable Logging"; Value = $EnableLogging },
    [PSCustomObject]@{ Parameter = "Input Extension"; Value = $InputExtension },
    [PSCustomObject]@{ Parameter = "Output Extension"; Value = $OutputExtension },
    [PSCustomObject]@{ Parameter = "Quality"; Value = $Quality }
)
Write-Host "Conversion Parameters:" -ForegroundColor Cyan
$params | Format-Table -AutoSize | Out-String | Write-Host

$confirmation = Read-Host "Do you really want to convert the above files? (Y/N)"
if ($confirmation -notmatch '^[Yy]$') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}
#endregion

#region Logging Setup
if ($EnableLogging) {
    $logFile = Join-Path $PSScriptRoot "conversion.log"
    $errorLogFile = Join-Path $PSScriptRoot "conversion_errors.log"
} else {
    $logFile = $null
    $errorLogFile = $null
}
#endregion

#region Timing Setup
$scriptStartTime = Get-Date
#endregion

#region File Processing
$counter = 0
foreach ($file in $fileList) {
    $fileStartTime = Get-Date
    $counter++
    try {
        $outputFile = Get-UniqueFilename -Directory $file.DirectoryName -BaseName $file.BaseName -Extension $OutputExtension
        Write-Host "Starting conversion: $($file.FullName)" -ForegroundColor Cyan

        $arguments = @(
            $file.FullName,          # Input file.
            "-quality", $Quality,    # Set JPEG quality.
            $outputFile              # Output file.
        )
        $imOutput = & magick @arguments 2>&1

        if ($EnableLogging -and $logFile) {
            Add-Content -Path $logFile -Value $imOutput
        }

        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick conversion failed with exit code $LASTEXITCODE"
        } else {
            Write-Host "Finished conversion: $($file.FullName) -> $outputFile" -ForegroundColor Green

            # Calculate file sizes.
            $origSize = $file.Length
            $newSize = (Get-Item $outputFile).Length
            $origSizeMB = [math]::Round($origSize / 1MB, 2)
            $newSizeMB = [math]::Round($newSize / 1MB, 2)
            $ratio = [math]::Round(($newSize / $origSize) * 100, 2)
            if ($ratio -gt 100) {
                $changeText = "increased by " + ([math]::Round(($ratio - 100), 2)) + "%"
            } else {
                $changeText = "reduced by " + ([math]::Round((100 - $ratio), 2)) + "%"
            }
            Write-Host "Original size: $origSizeMB MB, New size: $newSizeMB MB ($ratio% of original, $changeText)." -ForegroundColor Magenta

            if ($MoveToTrash) {
                Add-Type -AssemblyName Microsoft.VisualBasic
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                    $file.FullName,
                    [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
                Write-Host "Moved to Recycle Bin: $($file.FullName)" -ForegroundColor Yellow
            }
            else {
                Write-Host "Original file kept in place: $($file.FullName)" -ForegroundColor Yellow
            }
        }
    } catch {
        $errorMessage = "$($file.FullName) - Error: $_"
        Write-Host "Error converting $($file.FullName): $errorMessage" -ForegroundColor Red
        if ($EnableLogging -and $errorLogFile) {
            Add-Content -Path $errorLogFile -Value $errorMessage
        }
    }
    $fileEndTime = Get-Date
    $fileElapsed = $fileEndTime - $fileStartTime
    Write-Host "Conversion time for $($file.Name): $($fileElapsed.TotalSeconds) seconds" -ForegroundColor Cyan

    $percentComplete = ($counter / $totalFiles) * 100
    Write-Progress -Activity "Converting files" -Status "$counter of $totalFiles processed ($([math]::Round($percentComplete,2))%)" -PercentComplete $percentComplete
}
#endregion

#region Final Timing
$scriptEndTime = Get-Date
$totalElapsed = $scriptEndTime - $scriptStartTime
Write-Host "Total conversion time: $($totalElapsed.ToString())" -ForegroundColor Green
#endregion

Write-Host "All conversions complete." -ForegroundColor Green
