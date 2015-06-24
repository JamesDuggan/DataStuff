[CmdletBinding()]
param 
(
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$TheCartBeforeTheHorseDll,
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$preDeployTemplate,
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$preDeployOutput
)

# load pre-deploy template
$template = [System.IO.File]::ReadAllText($preDeployTemplate);

# get dll as byte array, convert to HEX string and output a pre deploy script based on the loaded template.
$bytes = [System.IO.File]::ReadAllBytes($TheCartBeforeTheHorseDll);
$sb = new-object "System.Text.StringBuilder" ($bytes.Length *2 +2);
$sb.Append("0x") | Out-Null;

foreach ($b in $bytes)
{
   $sb.AppendFormat("{0:X2}", $b) | Out-Null;
}
# template's placeholder is %assembly_hex% 
[System.IO.File]::WriteAllText($preDeployOutput, ($template -replace "%assembly_hex%", $sb.ToString()));