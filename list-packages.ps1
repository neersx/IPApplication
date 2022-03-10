Param(
    [string] $output = ".\App License Attributions.txt"
)

function FindNugetPackages() {
    $path = "."
    $packages = New-Object System.Collections.ArrayList

    foreach ($file in Get-ChildItem $path -Filter "project.assets.json" -Recurse -ErrorAction silentlycontinue) {
        if ($file.FullName -like '*.Test*' -or $file.FullName -like '*Demogod*') {
            continue;
        }

        $json = Get-Content $file.FullName | Out-String | ConvertFrom-Json
        
        foreach ($package in  $json.libraries.PSObject.Properties) {
            $packages.Add($package.Name) | Out-Null 
        }
    }

    return $packages | Where-Object { $_ -notlike "*paglobal*" } | Sort-Object { $_ } -Unique    
}

function FindDependencyPackages() {

    $client = Get-Content '.\condor\client\batchEventUpdate\package.json' | Out-String | ConvertFrom-Json    
    $condor = Get-Content '.\condor\package.json' | Out-String | ConvertFrom-Json

    $packages = @{};
    # if you want package to be ignored, put name in the $ignorePackages hashtable
    $ignorePackages = @{};

    foreach ($p in ($condor, $client)) {
        if ($p -ne "") {
            foreach ($prop in $p.dependencies | Get-Member -MemberType NoteProperty) {
                $v = $p.dependencies | Select-Object -ExpandProperty $prop.Name;
                if ($v -like '*git*' -or $v -like '*http*' -or $v -eq '*') {
                    $v = $null
                }
                
                if ($prop.Name -like 'cpa*' -or $ignorePackages.ContainsKey($prop.Name)) {
                    continue;
                }

                if ($packages.ContainsKey($prop.Name)) {
                    if ($packages[$prop.Name] -eq $v) {
                        continue;
                    }
                    $version = $packages[$prop.Name];
                    $packages[$prop.Name] = $version + ', ' + $v;
                    continue;
                }
                
                
                if ($prop.Name -like '@types/*') {
                    continue;
                }
                
                $packages.Add($prop.Name, $v);
            } 
        }
    }

    return $packages.GetEnumerator() | sort -Property name
}

Set-Content -Value "" -Path $output

foreach ($package in FindNugetPackages) {
    Add-Content -Value "$($package) [http://www.nuget.org/packages/$($package)]" -Path $output
}

Add-Content -Value "--------------------" -Path $output

foreach ($package in FindDependencyPackages) {
    Add-Content -Value "$($package.Name) $($package.Value)" -Path $output
}