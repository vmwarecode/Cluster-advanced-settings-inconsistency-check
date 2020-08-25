function Get-ClusterAdvSettingsInconsistency {
    <#
    .NOTES
        Author: Robert Nordell
        Last edit: 2020-08-25
        Version: 1.0
    .SYNOPSIS
        Get a list of advanced settings not consistently set in a cluster
    .EXAMPLE
        PS C:\> Get-ClusterAdvSettingsInconsistency -Cluster WorkloadCluster01
    .EXAMPLE
        PS C:\> $inconsitent = Get-ClusterAdvSettingsInconsistency -Cluster WorkloadCluster01 -Exclude $strArrExclude -ReturnSettingsAndValues
    .OUTPUTS
        String array of setting names with, or without, values and hostnames
    #>
    param (
        [parameter(Mandatory=$True)][string]$Cluster,
        [parameter(Mandatory=$False)][string[]]$Exclude,
        [parameter(Mandatory=$False)][switch]$ReturnSettingsAndValues
    )
    
    begin {
        if ($null -eq $Exclude) { 
            # Exclude some advanced settings by default
            $Exclude =  "Vpx.Vpxa.config.vpxa.hostKey",
                        "Syslog.global.logDir",
                        "ScratchConfig.CurrentScratchLocation",
                        "ScratchConfig.ConfiguredScratchLocation",
                        "Vpx.Vpxa.config.vpxa.hostIp"
        }
    }

    process {
        # All advanced settings, minus excluded settings
        $advSettings = Get-Cluster $Cluster | Get-VMHost | Get-AdvancedSetting | Where-Object { $_.Name -notin $Exclude }
        
        # All inconsistent settings
        $incSettings = Compare-Object -ReferenceObject ($advSettings | Select-Object Name -Unique) -DifferenceObject ($advSettings | Select-Object Name,Value -Unique) -Property Name
        $incSettings = $advSettings | Where-Object { $_.Name -in $incSettings.Name }
    }

    end {
        if ($null -eq $incSettings) {
            # There were no inconsistent settings, nice!
            Write-Host "Cluster [$Cluster] has no inconsistent advanced settings (excluding $($Exclude -join ","))."
        } else {
            if ($false -eq $ReturnSettingsAndValues) {
                # Return setting names
                ($incSettings | Select-Object Name -Unique | Sort-Object -Property Name).Name
            } else {
                # Return all inconsistent setting names and values for each host
                $incSettings | Select-Object Entity,Name,Value | Sort-Object -Property Name,Entity
            }
        }
    }
}
