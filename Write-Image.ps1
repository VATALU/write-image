[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

Function Resize-Image() {
    Param (
        [Parameter(Mandatory = $True)]
        [System.Drawing.Bitmap]$OldImage,
        [Parameter(Mandatory = $False)][Switch]$MaintainRatio,
        [Parameter(Mandatory = $False, ParameterSetName = "Absolute")][Int]$Height,
        [Parameter(Mandatory = $False, ParameterSetName = "Absolute")][Int]$Width,
        [Parameter(Mandatory = $False, ParameterSetName = "Percent")][Double]$Percentage,
        [Parameter(Mandatory = $False)][System.Drawing.Drawing2D.SmoothingMode]$SmoothingMode = "HighQuality",
        [Parameter(Mandatory = $False)][System.Drawing.Drawing2D.InterpolationMode]$InterpolationMode = "HighQualityBicubic",
        [Parameter(Mandatory = $False)][System.Drawing.Drawing2D.PixelOffsetMode]$PixelOffsetMode = "HighQuality",
        [Parameter(Mandatory = $False)][String]$NameModifier = "resized"
    )
    Begin {
        If ($Width -and $Height -and $MaintainRatio) {
            Throw "Absolute Width and Height cannot be given with the MaintainRatio parameter."
        }
 
        If (($Width -xor $Height) -and (-not $MaintainRatio)) {
            Throw "MaintainRatio must be set with incomplete size parameters (Missing height or width without MaintainRatio)"
        }
 
        If ($Percentage -and $MaintainRatio) {
            Write-Warning "The MaintainRatio flag while using the Percentage parameter does nothing"
        }
    }
    Process {

            # Grab these for use in calculations below. 
            $OldHeight = $OldImage.Height
            $OldWidth = $OldImage.Width
 
            If ($MaintainRatio) {
                $OldHeight = $OldImage.Height
                $OldWidth = $OldImage.Width
                If ($Height) {
                    $Width = $OldWidth / $OldHeight * $Height
                }
                If ($Width) {
                    $Height = $OldHeight / $OldWidth * $Width
                }
            }
 
            If ($Percentage) {
                $Product = ($Percentage / 100)
                $Height = $OldHeight * $Product
                $Width = $OldWidth * $Product
            }

            $Bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Width, $Height
            $NewImage = [System.Drawing.Graphics]::FromImage($Bitmap)
             
            #Retrieving the best quality possible
            $NewImage.SmoothingMode = $SmoothingMode
            $NewImage.InterpolationMode = $InterpolationMode
            $NewImage.PixelOffsetMode = $PixelOffsetMode
            $NewImage.DrawImage($OldImage, $(New-Object -TypeName System.Drawing.Rectangle -ArgumentList 0, 0, $Width, $Height))

            $NewImage.Dispose()
            return $Bitmap
    }
}
Function Write-RGB-Square {
    param (
        [Parameter(Position = 0,Mandatory=$True)]
        [int16]$red,
        [Parameter(Position = 1,Mandatory=$True)]
        [int16]$green,
        [Parameter(Position = 2,Mandatory=$True)]
        [int16]$blue
    )
    $escape = [char]27 + '['
    $resetAttributes = "$($escape)0m"
    $Text = "  "
    $background = "$($escape)48;2;$($red);$($green);$($blue)m"
    Write-Host ($background + $Text + $resetAttributes) -NoNewline:$NoNewLine
}

Function Write-Image {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0,Mandatory=$True)][string]$filepath
    )
    # $OldImage = New-Object -TypeName System.Drawing.Bitmap -ArgumentList (Resolve-Path $filepath).Path
    $OldImage = [System.Drawing.Bitmap]::FromFile((Get-Item $filepath).fullname) 
    $WindowWidth = $host.UI.RawUI.WindowSize.Width/2
    $WindowHeight = $host.UI.RawUI.WindowSize.Height/2

    if($OldImage.Height -gt $WindowHeight -and $OldImage.Width -lt $WindowWidth){
        $BitMap = Resize-Image -OldImage $OldImage -MaintainRatio -Width $WindowHeight
    }
    elseif ($OldImage.Height -lt $WindowHeight -and $OldImage.Width -gt $WindowWidth) {
        $BitMap = Resize-Image -OldImage $OldImage -MaintainRatio -Width $WindowWidth
    }elseif ($OldImage.Height -lt $WindowHeight -and $OldImage.Width -lt $WindowWidth){
        $BitMap=$OldImage
    }else {
        $BitMap = Resize-Image -OldImage $OldImage -MaintainRatio -Width $WindowWidth
    }

    foreach ($h in 1..$BitMap.Height) {
        foreach ($w in 1..$BitMap.Width) {
            $rgb = $BitMap.GetPixel($w - 1, $h - 1)
            Write-RGB-Square $rgb.R $rgb.G $rgb.B
        }
        Write-Host ""
    }
    $BitMap.Dispose()
}