class GuiLine {
	[string]$Text
	[bool]$Selected
	[bool]$Dirty
}


function Write-BrowserGuiLine {
	param (
		$Text,
		$Selected
	)

	if ($Selected) {
		Write-Host $Text -BackgroundColor White -ForegroundColor Black
	} else {
		Write-Host $Text -BackgroundColor Black -ForegroundColor White
	}
}

function Build-BrowserGui {
	$windowSize = (Get-Host).UI.RawUI.MaxWindowSize
	
}

function Write-BrowserGui {
	param (
		$SelectedLine,
		$Items
	)
	
	$currentLine = 0

	clear
	foreach ($child in $Items) {
		if ($child -is [System.IO.DirectoryInfo]) {
			$text = "`t" + $child.Name + "/"
		} else {
			$text = "`t" + $child.Name
		}

		$selected = $currentLine -eq $SelectedLine
		Write-BrowserGuiLine -Text $text -Selected $selected 	

		$currentLine++
	}
}

$keepGoing = $true

$selectedLine = 0

$children = Get-ChildItem
Write-BrowserGui -Items $children -SelectedLine $selectedLine

Do {
	$key = [System.Console]::ReadKey()

	switch($key.Key) {
		UpArrow {
			$selectedLine--
			if ($selectedLine -lt 0) {
				$selectedLine = $children.Length - 1
			}
		}
		DownArrow {
			$selectedLine++
			if ($selectedLine -gt $children.Length - 1) {
				$selectedLine = 0
			}
		}
		Q {
			$keepGoing = $false
		}
	}
	
	$children = Get-ChildItem
	Write-BrowserGui -Items $children -SelectedLine $selectedLine
} while ($keepGoing)

clear
