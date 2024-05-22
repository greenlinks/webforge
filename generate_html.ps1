$listFile = "list.txt"
$htmlFile = "index.html"

function Get-MapDetails {
    param (
        [string]$url
    )
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $html = $response.Content

        # Extract map name (assuming it's in the title tag for simplicity)
        if ($html -match '<title>(.*?)</title>') {
            $mapName = $matches[1] -replace ' - Halo Infinite', ''
            $mapName = $mapName -replace ' - UGC', ''
        } else {
            $mapName = "Unknown Map"
        }

        # Extract hero image URL
        $imgUrlMatch = [regex]::Match($html, '(https:\/\/blobs-infiniteugc\.svc\.halowaypoint\.com\/ugcstorage\/map\/.*?\/images\/thumbnail\.jpg)')
        if ($imgUrlMatch.Success) {
            $imgUrl = $imgUrlMatch.Value -replace 'thumbnail.jpg', 'hero.jpg'
        } else {
            $imgUrl = "https://via.placeholder.com/200x200?text=No+Image"
        }

        return @{
            Name = $mapName
            ImgUrl = $imgUrl
        }
    }
    catch {
        Write-Error "Failed to get details for $url"
        return $null
    }
}

if (Test-Path $listFile) {
    $htmlContent = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css?family=Rajdhani" rel="stylesheet">
    <title>Forge Map List</title>
    <style>
        body {
            font-family: 'Rajdhani', sans-serif;
            font-weight: bold;
            background-color: #0F0F0F;
            color: #E0E0E0;
            margin: 0;
            padding: 20px;
        } 
        h1 {
            text-align: center;
            color: #FFFFFF;
            margin-bottom: 20px;
        }
        footer {
            text-align: center;
            width: 100%;
            padding: 10px 0; 
        }
        .container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        .tile {
            background-color: #1A1A1A;
            border: 1px solid #FFFFFF;
            overflow: hidden;
            transition: transform 0.3s, box-shadow 0.3s;
            position: relative;
        }
        .tile::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            border: 4px solid transparent;
            transition: border-color 0.3s;
            z-index: 5;
        }
        .tile:hover::before {
            border-color: #FFFFFF;
        }
        .tile:hover {
            transform: translateY(-5px);
            box-shadow: 0 0 30px rgba(255, 255, 255, 0.3);
        }
        .tile a {
            text-decoration: none;
            color: #FFFFFF;
            display: block;
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 10;
        }
        .tile .content {
            padding: 10px;
            font-size: 20px;
            background-color: rgba(0, 0, 0, 0.75);
            position: absolute;
            bottom: 0;
            width: 100%;
            text-align: left;
            transition: background-color 0.3s, color 0.3s;
            z-index: 6;
        }
        .tile:hover .content {
            background-color: #FFFFFF;
            color: #0F0F0F;
        }
        .tile img {
            width: 100%;
            height: 200px;
            object-fit: cover;
            display: block;
        }
    </style>
</head>
<body>

    <h1>Forge Map List</h1>
    <div class="container">
'@

    $lines = Get-Content -Path $listFile

    foreach ($line in $lines) {
        $details = Get-MapDetails -url $line.Trim()
        if ($details) {
            $mapName = $details.Name
            $mapLink = $line.Trim()
            $imgLink = $details.ImgUrl

            $htmlContent += @"
        <div class="tile">
            <img src="$imgLink" alt="$mapName">
            <div class="content">$mapName</div>
            <a href="$mapLink"></a>
        </div>
"@
        }
    }

    $htmlContent += @'
    </div>
</body>
</html>
'@

    Set-Content -Path $htmlFile -Value $htmlContent
    Write-Host "index.html file has been created successfully."
} else {
    Write-Host "Error: list.txt not found."
}