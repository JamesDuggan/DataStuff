$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition; 

# relating to project name. This may be abstract or concrete and used to generate files names, descriptions, etc.
$global:testSettings = @{
    projectName = "SQLUnitTestingConnections"
}

# relating to expected paths
$global:testSettings += @{
    rootPath = Split-Path $scriptPath
    powershellPath = $scriptPath
}

# relating to dependencies
$global:testSettings += @{
    vsTestConsole = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console"
}

# relating to TSQL Unit Testing config file building
$global:testSettings += @{
    testingAppConfigTemplate = "sqlunittest.config.template"
    testingAppConfigFile = "{0}.sqlunittest.config"
    testingConnectionString="Data Source={0};Initial Catalog={1};Integrated Security=True;Pooling=False"
}

function ConfigureTestingAppConfig
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=1, ValueFromPipeline=$true)][String]$templateFile
)
    # sql unit tests are not per se deployed.
    # instead the testing project is built and the tests executed from that location
    # this script builds an environment specific app.config from a template.
    # the custom script has naming format <machineName>.sqlunittest.config
    $template = [System.IO.File]::ReadAllText($templateFile);
    $template = $template.Replace("%connection_string%", ($global:testSettings.testingConnectionString -f $global:environmentSettings.targetServer, $global:environmentSettings.targetDatabase));
    $configFile = Join-Path (Split-Path $templateFile) ($global:testSettings.testingAppConfigFile -f ($env:computername));

    Write-Host ("Creating test config file: {0}" -f $configFile) -foregroundcolor Cyan;

    [System.IO.File]::WriteAllText($configFile, $template);
}


function RunTestingDll
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=1, ValueFromPipeline=$true)][String]$testingDll
)
    &$global:testSettings.vsTestConsole $testingDll /UseVsixExtensions:false /Logger:trx;
   
}

function ImportSettingsFile 
{
[CmdletBinding()]
Param 
(
    [Parameter(Mandatory=1)][String]$environment
)
    $settingsFile = (Join-Path $global:testSettings.powershellPath ("{0}.Settings.ps1" -f $environment.ToUpper()));

    if (!(Test-Path -Path $settingsFile)) 
    {
        throw ("Failed to import settings file. File '{0}' not found for environment {1} '$environment'." -f $settingsFile, $_.Exception.Message)
    };

    Import-Module $settingsFile -Force;
}


# Convenience functions
function Find
{
[CmdletBinding()]
Param 
(
    [Parameter(Mandatory=1)][String]$path
   ,[Parameter(Mandatory=1)][String]$pattern
   ,[Parameter(Mandatory=0)][String]$exclude = ""           # (wildcard) filespec to be excluded
   ,[Parameter(Mandatory=0)][Object]$ignorePath = @()       # (wildcard) list of directories to exclude
)
    if ($ignorePath) 
    { 
       gci -r $path $pattern -exclude $exclude | foreach {$nomatch=$true; foreach ($path in $ignorePath) {if($_.FullName -like "*\$path\*") {$nomatch = $false;}}; if($nomatch) {$_.FullName}}; 
    }
    else 
    {
       gci -r $path $pattern -exclude $exclude | %{ $_.FullName };
    }
}