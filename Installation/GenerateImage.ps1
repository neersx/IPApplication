 
 Param ( 
 
    [string] $SourceImage = "",
    [string] $TargetImage = "",
    [string] $MessageText = "",    
    [string] $Year = ""
 
      ) 

$MessageText1 = "© 1994-" + $Year + " CPA Global Software Solutions Australia Pty Ltd"

Function Write-TextOnImage($SourceImage,$TargetImage,$MessageText,$MessageText1)
{ 

 
    [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null 
 
    #read source image and create new target image 
    $srcImg = [System.Drawing.Image]::FromFile($SourceImage) 
    $tarImg = new-object System.Drawing.Bitmap([int]($srcImg.width)),([int]($srcImg.height)) 
 
    #Intialize Graphics 
    $Image = [System.Drawing.Graphics]::FromImage($tarImg) 
    $Image.SmoothingMode = "AntiAlias" 
 
    $Rectangle = New-Object Drawing.Rectangle 0, 0, $srcImg.Width, $srcImg.Height 
    $Image.DrawImage($srcImg, $Rectangle, 0, 0, $srcImg.Width, $srcImg.Height, ([Drawing.GraphicsUnit]::Pixel)) 
 
    #Write MessageText
    $Font = new-object System.Drawing.Font("MS Sans Serif", 14) 
    $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,0,0,128)) 
    $Image.DrawString($MessageText, $Font, $Brush, 120, 70) 

    $Font1 = new-object System.Drawing.Font("MS Sans Serif", 8) 
    $Brush1 = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,0,0,0)) 
    $Image.DrawString($MessageText1, $Font1, $Brush1, 70, 230) 
     
    #Save and close the files 
    $tarImg.save($targetImage, [System.Drawing.Imaging.ImageFormat]::Bmp) 
    $srcImg.Dispose() 
    $tarImg.Dispose() 
}

Write-TextOnImage $SourceImage $TargetImage $MessageText $MessageText1
