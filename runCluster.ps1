$json = Get-Content 'config.json' | Out-String | ConvertFrom-Json

$clusterNodes = $json.CLUSTERNODES
$clusters = $json.CLUSTERS

$nodes = @("router")

for ( $cluster = 1; $cluster -le $clusters; $cluster++){
	$cluster 
	for ( $clusterNode = 1; $clusterNode -le $clusterNodes; $clusterNode++){
		$node = -join("server",$cluster,$clusterNode)
		$nodes += $node
	}
}

foreach ($node in $nodes) { Start-Process "c:\hashicorp\vagrant\bin\vagrant.exe" -ArgumentList "up",$node }