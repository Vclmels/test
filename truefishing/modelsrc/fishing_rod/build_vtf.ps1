param(
    [Parameter(Mandatory = $true)] [string] $InputPath,
    [Parameter(Mandatory = $true)] [string] $OutputPath,
    [switch] $NormalMap
)

Add-Type -AssemblyName System.Drawing

$bitmap = [System.Drawing.Bitmap]::new($InputPath)
try {
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.AddRange([System.Text.Encoding]::ASCII.GetBytes("VTF`0"))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint32]7))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint32]2))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint32]80))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint16]$bitmap.Width))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint16]$bitmap.Height))
    $flags = [uint32]0x300 # TEXTUREFLAGS_NOMIP | TEXTUREFLAGS_NOLOD
    if ($NormalMap) { $flags = $flags -bor [uint32]0x80 }
    $bytes.AddRange([System.BitConverter]::GetBytes($flags))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint16]1))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint16]0))
    $bytes.AddRange([byte[]](0, 0, 0, 0))
    $bytes.AddRange([System.BitConverter]::GetBytes([single]0))
    $bytes.AddRange([System.BitConverter]::GetBytes([single]0))
    $bytes.AddRange([System.BitConverter]::GetBytes([single]0))
    $bytes.AddRange([byte[]](0, 0, 0, 0))
    $bytes.AddRange([System.BitConverter]::GetBytes([single]1))
    $bytes.AddRange([System.BitConverter]::GetBytes([uint32]0)) # IMAGE_FORMAT_RGBA8888
    $bytes.Add([byte]1)
    $bytes.AddRange([System.BitConverter]::GetBytes([uint32]::MaxValue)) # IMAGE_FORMAT_UNKNOWN: no thumbnail
    $bytes.Add([byte]0)
    $bytes.Add([byte]0)
    $bytes.AddRange([System.BitConverter]::GetBytes([uint16]1)) # depth
    while ($bytes.Count -lt 80) { $bytes.Add([byte]0) }

    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $bytes.Add($pixel.R)
            $bytes.Add($pixel.G)
            $bytes.Add($pixel.B)
            $bytes.Add($pixel.A)
        }
    }

    [System.IO.File]::WriteAllBytes($OutputPath, $bytes.ToArray())
}
finally {
    $bitmap.Dispose()
}
