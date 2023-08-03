Function PressAnyKeyToContinue($exitCode = 0) {
    Write-Host -ForegroundColor Yellow "Press space bar to continue..."
    $key = $null
    while ($key -notmatch ' ') {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    }
    exit $exitCode
}

# Define the path for the configuration file
$configPath = "$env:APPDATA\ZomboidModConfig.json"

try {
    $configExists = Test-Path $configPath

    if ($configExists) {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        $choices = @("Load Previous Configuration", "Modify Configuration")
        
        # Display menu to the user
        Write-Host "Select an option:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $choices.Count; $i++) {
            # Adjust list to start from 1
            Write-Host "$($i + 1): $($choices[$i])"
        }

        # Display the previous configuration
        Write-Host "`nPrevious Configuration:" -ForegroundColor Green
        Write-Host "Workshop Path: $($config.workshopPath)"
        Write-Host "Mod List Path: $($config.modListPath)"
        Write-Host "Preset: $($config.preset)`n"

        $selection = Read-Host -Prompt "Enter the number for your choice [Default: 1]"
        if (-not $selection) {
            $selection = 1
        }
        $selection = $selection - 1

        switch ($selection) {
            0 { # Load Previous Configuration
                $workshopPath = $config.workshopPath
                $modListPath = $config.modListPath
                $preset = $config.preset
            }
            1 { # Modify Configurations
                Write-Host -ForegroundColor Yellow 'Enter the workshop path, e.g. "C:\Program Files (x86)\Steam\steamapps\workshop\content\108600"'
                $workshopPath = Read-Host -Prompt "Previous: $($config.workshopPath)"
                if (-not $workshopPath) { $workshopPath = $config.workshopPath }
                Write-Host

                Write-Host -ForegroundColor Yellow 'Enter the mod list path, e.g. "C:\Users\YOURNAME\Zomboid\Lua\saved_modlists.txt"'
                $modListPath = Read-Host -Prompt "Previous: $($config.modListPath)"
                if (-not $modListPath) { $modListPath = $config.modListPath }
                Write-Host

                Write-Host -ForegroundColor Yellow 'Enter the saved preset from Zomboid Mods'
                $preset = Read-Host -Prompt "Previous: $($config.preset)"
                if (-not $preset) { $preset = $config.preset }
                Write-Host
            } default {
                Write-Host "Invalid selection" -ForegroundColor Red
                PressAnyKeyToContinue 1
            }
        }
    } else {
        $workshopPath = Read-Host -Prompt 'Enter the workshop path, e.g. "C:\Program Files (x86)\Steam\steamapps\workshop\content\108600"'
        $modListPath = Read-Host -Prompt 'Enter the mod list path, e.g. "C:\Users\YOURNAME\Zomboid\Lua\saved_modlists.txt"'
        $preset = Read-Host -Prompt 'Enter the saved preset from Zomboid Mods'
    }

    # Save the configurations back to the config file after the user has made selections
    $config = @{
        workshopPath = $workshopPath
        modListPath = $modListPath
        preset = $preset
    } | ConvertTo-Json

    Set-Content -Path $configPath -Value $config

    # Create an object/list with the workshop ID and mod ID associated
    $workshopModMap = @{}
    $workshopPathExists = Test-Path $workshopPath
    if (-Not $workshopPathExists) {
        Write-Host "Workshop path doesn't exist" -ForegroundColor Red
        PressAnyKeyToContinue 1
    }
    Get-ChildItem $workshopPath -Directory | ForEach-Object {
        $workshopId = $_.Name
        $modPath = Join-Path $_.FullName "mods"
        if (Test-Path $modPath) {
            Get-ChildItem $modPath -Directory | ForEach-Object {
                # Open directory "$modPath/$modName/" and read the mod.info file
                $modName = $_.Name
                $modInfoPath = Join-Path $_.FullName "mod.info"
                $modInfoContent = Get-Content -Raw -LiteralPath $modInfoPath
                # Split the content by line
                $modInfoContent = $modInfoContent -split "`n"
                # Find line with "name=" at the beginning and get the mod ID
                $found = $false;
                foreach ($line in $modInfoContent) {
                    if ($line.StartsWith("id=")) {
                        $found = $true
                        $modId = $line.Split('=')[1]
                        if (-not $workshopModMap.ContainsKey($workshopId)) {
                            $workshopModMap[$workshopId] = @{}
                        }
                        $workshopModMap[$workshopId][$modId] = @{}
                        $workshopModMap[$workshopId][$modId]["name"] = $modName

                        # Check if directory "$modPath/$modName/media/maps/" exists
                        # If it does, copy all folder names to the modMaps list
                        # Ignore duplicates
                        $mapsPath = Join-Path $_.FullName "media\maps"
                        if (Test-Path $mapsPath) {
                            Get-ChildItem $mapsPath -Directory | ForEach-Object {
                                if (-not $workshopModMap[$workshopId][$modId].ContainsKey("map")) {
                                    $workshopModMap[$workshopId][$modId]["map"] = @()
                                }
                                $mapName = $_.Name
                                $workshopModMap[$workshopId][$modId]["map"] += $mapName
                            }
                        }
                    }
                }

                if (!$found) {
                    Write-Host -ForegroundColor Red "Could not find mod ID in $($modInfoPath)."
                    PressAnyKeyToContinue 1
                }
            }
        }
    }
    Write-Host -ForegroundColor Green "Found $($workshopModMap.Count) workshop IDs."

    # Get the mod IDs for the preset
    $presetModIds = @()
    $modListPathExists = Test-Path $modListPath
    if (-Not $modListPathExists) {
        Write-Host "Mod list path doesn't exist" -ForegroundColor Red
        PressAnyKeyToContinue 1
    }
    $modList = [System.Collections.Generic.List[string]](Get-Content "$modListPath")
    $found = $false;
    foreach ($line in $modList) {
        if ($line.StartsWith($preset)) {
            $found = $true
            $lineParts = $line.Split(':')
            $modIds = $lineParts[1].Split(';')
            foreach ($modId in $modIds) {
                $presetModIds += $modId
            }
        }
    }
    if (!$found) {
        Write-Host -ForegroundColor Red "Could not find preset $($preset)."
        PressAnyKeyToContinue 1
    }

    $presetWorkshopIds = @()
    $missingMods = @()
    $modMaps = @()
    $workshopIds = @()
    foreach ($presetModId in $presetModIds) {
        $found = $false
        foreach ($workshopId in $workshopModMap.Keys) {
            foreach ($modId in $workshopModMap[$workshopId].Keys) {
                if ($modId.Trim() -eq $presetModId.Trim()) {
                    $presetWorkshopIds += $workshopModMap[$workshopId][$modId]["name"]
                    if ($workshopModMap[$workshopId][$modId].ContainsKey("map")) {
                        $modMaps += $workshopModMap[$workshopId][$modId]["map"]
                    }
                    if (-not $workshopIds.Contains($workshopId)) {
                        $workshopIds += $workshopId
                    }
                    $found = $true
                    break
                }
            }
            if ($found) {
                break
            }
        }
        if (!$found) {
            $missingMods += $presetModId
        }
    }

    if ($missingMods.Count -gt 0) {
        Write-Host "Could not find these mods: $($missingMods -join ', ')"
    }

    Write-Host -ForegroundColor Green "Found $($presetModIds.Count) mod IDs for preset $($preset)."

    Write-Host -ForegroundColor Blue "Copy these mod IDs to the server ini file: $($presetModIds -join ';')"
    Write-Host ""
    Write-Host -ForegroundColor Blue "Copy these workshop IDs to the server ini file: $($workshopIds -join ';')"
    Write-Host ""
    Write-Host -ForegroundColor Blue "Copy these maps to the server: $($modMaps -join ';')"

    PressAnyKeyToContinue
} catch {
    Write-Error $_.Exception.ToString()
    PressAnyKeyToContinue 69
}
