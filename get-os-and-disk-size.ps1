# Import computer names from CSV
$computers = Import-Csv -Path "C:\script\computers_from_ou.csv" | Select-Object -ExpandProperty Name

# Output path for results
$outputPath = "C:\script\Disk_OS_Report.csv"

# Ensure output file is fresh
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Force
}

foreach ($computer in $computers) {
    Write-Host "Checking $computer..." -ForegroundColor Cyan
    $result = $null

    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        # Start WMI retrieval in a background job to control timeout
        $job = Start-Job -ScriptBlock {
            param($comp)

            try {
                # Re-create DCOM session option inside the job
                $sessionOptions = New-CimSessionOption -Protocol DCOM
                $session = New-CimSession -ComputerName $comp -SessionOption $sessionOptions -ErrorAction Stop

                $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -CimSession $session -ErrorAction Stop
                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session -ErrorAction Stop
                Remove-CimSession -CimSession $session

                return ,@($disks, $osInfo)
            } catch {
                return "WMI Error: $($_.Exception.Message)"
            }
        } -ArgumentList $computer

        # Wait max 10 seconds for job to complete
        if (Wait-Job -Job $job -Timeout 10) {
            $output = Receive-Job $job
            Remove-Job $job

            if ($output -is [string] -and $output -like "WMI Error:*") {
                Write-Warning ("WMI/CIM error on {0}: {1}" -f $computer, $output)
                $result = [PSCustomObject]@{
                    ComputerName = $computer
                    DriveLetter  = "N/A"
                    TotalGB      = "WMI Error"
                    FreeGB       = "WMI Error"
                    UsedGB       = "WMI Error"
                    OSType       = "WMI Error"
                    OSBuild      = "WMI Error"
                    Timestamp    = Get-Date
                }
            } else {
                $disks, $osInfo = $output

                foreach ($disk in $disks) {
                    $result = [PSCustomObject]@{
                        ComputerName = $computer
                        DriveLetter  = $disk.DeviceID
                        TotalGB      = [math]::Round($disk.Size / 1GB, 2)
                        FreeGB       = [math]::Round($disk.FreeSpace / 1GB, 2)
                        UsedGB       = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                        OSType       = $osInfo.Caption
                        OSBuild      = $osInfo.BuildNumber
                        Timestamp    = Get-Date
                    }

                    $writeHeader = -not (Test-Path $outputPath)
                    $result | Export-Csv -Path $outputPath -NoTypeInformation -Append:(!$writeHeader)
                }
            }
        } else {
            # Timeout
            Stop-Job $job -Force
            Remove-Job $job
            Write-Warning "WMI timeout on $computer (skipped after 10s)"

            $result = [PSCustomObject]@{
                ComputerName = $computer
                DriveLetter  = "N/A"
                TotalGB      = "Timeout"
                FreeGB       = "Timeout"
                UsedGB       = "Timeout"
                OSType       = "Timeout"
                OSBuild      = "Timeout"
                Timestamp    = Get-Date
            }
        }

        # Write timeout or error result
        if ($result) {
            $writeHeader = -not (Test-Path $outputPath)
            $result | Export-Csv -Path $outputPath -NoTypeInformation -Append:(!$writeHeader)
        }

    } else {
        Write-Warning "$computer is offline or unreachable. Skipping."

        $result = [PSCustomObject]@{
            ComputerName = $computer
            DriveLetter  = "N/A"
            TotalGB      = "Offline"
            FreeGB       = "Offline"
            UsedGB       = "Offline"
            OSType       = "N/A"
            OSBuild      = "N/A"
            Timestamp    = Get-Date
        }

        $writeHeader = -not (Test-Path $outputPath)
        $result | Export-Csv -Path $outputPath -NoTypeInformation -Append:(!$writeHeader)
    }
}

Write-Host "✅ Report completed: $outputPath" -ForegroundColor Green
