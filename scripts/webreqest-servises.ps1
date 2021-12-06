Param(
 
[string]$select,
[string]$servicestring

)
Import-Module WebAdministration 

# Get list IIS services at json format
if ( $select -eq 'GETSERVICESNAME' )
{
  $jsonData = @()
  $servicesnametmmp = Get-WebApplication -Site "Default Web Site" |  Select-Object Path
  $servicesnameclear = $servicesnametmmp.path -replace '/', ''
  if ($servicesnametmmp)
  {
      foreach ($Name in $servicesnameclear)
      {
         $jsonData += @(@{"{#SERVICENAME}" = $Name})
      }
  }
  $jsonData | ConvertTo-Json -Compress
}

# Get status IIS service
if ( $select -eq 'GETSERVICESTATUS' ) 
{
  # Get service info. Change name service
  $name = Get-WebApplication -Site "Default Web Site" -Name $servicestring
  $nameservice = $name.path -replace '/', ''
  # Set link for service
  if ($name.applicationPool -eq 'MgdAppPool') 
  {
    $link = 'http://localhost/' + $nameservice + '/swagger/v1/swagger.json'
  }

  if ($name.applicationPool -eq 'ServiceProxyAppPool') 
  {
    $link = 'http://localhost/' + $nameservice + '/AisElnService.svc?wsdl'
  }
  # Check link to error
  try{
    $shift = Invoke-RestMethod -Uri $link
  }
  catch{
    $code = $_.Exception.Response.StatusCode.value__
  }
  if ($code -eq $null) {
  $servicestatus = 1
  } else {
  $servicestatus = 0
  }
  # Write service status
  $servicestatus
}
