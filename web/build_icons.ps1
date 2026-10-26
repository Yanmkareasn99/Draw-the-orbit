# Regenerate platform sizes from the selected master artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$iconDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\icons'
$sourceImage = [System.Drawing.Image]::FromFile((Join-Path $iconDirectory 'bonk-icon-master.png'))

function Export-Icon([int]$Size, [string]$Filename, [double]$ContentScale = 1.0) {
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    try {
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#10172e'))
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $edge = [int][Math]::Round($Size * $ContentScale)
        $inset = [int][Math]::Floor(($Size - $edge) / 2.0)
        $destination = New-Object System.Drawing.Rectangle($inset, $inset, $edge, $edge)
        $graphics.DrawImage($sourceImage, $destination, 0, 0, $sourceImage.Width, $sourceImage.Height,
            [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        $bitmap.Save((Join-Path $iconDirectory $Filename), [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output "$Filename ($Size x $Size)"
    }
    finally {
        $attributes.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    foreach ($size in @(32, 64, 144, 180, 192, 512)) {
        Export-Icon $size "bonk-icon-$size.png"
    }
    # 56% of the square fits completely inside the maskable central 80% circle.
    Export-Icon 512 'bonk-icon-maskable-512.png' 0.56
}
finally {
    $sourceImage.Dispose()
}
