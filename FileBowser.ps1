class GuiLine {
	[bool]$Dirty
	
	[string]$Text
	[bool]$Selected

	GuiLine() {
		$this.Selected = $false
		$this.Dirty = $false
	}

	[string] Formatter() {
		if ($this.Selected) {
			#return "`e[31m"
			return "`e[44m"
		} else {
			return "`e[0m"
		}
	}
}

class Gui {
	[GuiLine[]]$Lines
	[int]$Height
	[int]$Width

    Gui() {
		$windowSize = (Get-Host).UI.RawUI.MaxWindowSize

		$this.Width = $windowSize.Width
		$this.Height = $windowSize.Height - 1

		$this.Lines = [GuiLine[]]::new($this.Height)
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$this.Lines[$i] = [GuiLine]::new()
		}

		$this.Lines[6].Selected = $true
    }

	[void] SetLineText([int]$LineIndex, [string]$Text) {
		$this.Lines[$LineIndex].Text = $Text
		$this.Lines[$LineIndex].Dirty = $true
	}

	[void] SetLineSelected([int]$LineIndex) {
		$this.Lines[$LineIndex].Selected = $true
		$this.Lines[$LineIndex].Dirty = $true
	}
	
	[void] SetAllLinesDeselected() {
		foreach ($line in $this.Lines) {
			if ($line.Selected) {
				$line.Selected = $false
				$line.Dirty = $true
			}
		}
	}

	[void] Draw() {
		clear
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			$this.DrawLine($i, $line.Text, $line.Formatter())
			$line.Dirty = $false
		}
	}

	[void] ReDraw() {
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			if ($line.Dirty) {
				$this.DrawLine($i, $line.Text, $line.Formatter())
				$line.Dirty = $false
			}
		}
	}

	[void] DrawLine([int]$LineIndex, [string]$Text, [string]$Formatter) {
		$l = $LineIndex + 1
		Write-Host "`e[$l;1H`e[K|  $Formatter$Text`e[0m"
	}
}

function Main {
	$gui = [Gui]::new()

	$files = Get-ChildItem
	for ($i = 0; $i -lt $files.Length; $i++) {
		$gui.SetLineText($i, $files[$i].Name)
	}
	
	$cursorLine = 0
	$gui.SetLineSelected($cursorLine)
	
	$gui.Draw()
	
	$keepGoing = $true
	Do {
		$key = [System.Console]::ReadKey()

		switch($key.Key) {
			UpArrow {
				$cursorLine--
				if ($cursorLine -lt 0) {
					$cursorLine = $files.Length - 1
				}
			}
			DownArrow {
				$cursorLine++
				if ($cursorLine -gt $files.Length - 1) {
					$cursorLine = 0
				}
			}
			Q {
				$keepGoing = $false
			}
		}
	
		$gui.SetAllLinesDeselected()
		$gui.SetLineSelected($cursorLine)

		$gui.ReDraw()
	} while ($keepGoing)

	clear
}

Main

Exit



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
