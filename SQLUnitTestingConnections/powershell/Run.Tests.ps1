[CmdletBinding()]
Param
(
    [Parameter(Mandatory=0, ValueFromPipeline=$true)][String]$environment="DEV"
)

$ErrorActionPreference = "stop";
$global:environment=$environment;

Import-Module (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "TestingUtils.psm1") -Force;

try
{
    pushd $global:testSettings.rootPath;

    ## environment specific configuration 
    ImportSettingsFile ($global:environment) | out-null;

    $testingDll = Find (Join-Path $global:testSettings.rootPath "SQLUnitTestingConnections.Testing\bin\release") "*testing.dll";
$testingDll
    if ($testingDll) 
    {
        RunTestingDll $testingDll;
    }
}
catch 
{
    throw ("Error - Running script: {0} `n{1} " -f $MyInvocation.InvocationName , $_.Exception.Message);
}
finally {
    popd;
}