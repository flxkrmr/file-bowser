class GuiLine {
	[bool]$Dirty
	
	[string]$Text
	[string]$Formatter
	
	GuiLine() {
		$this.Dirty = $false
		$this.Formatter = "`e[0m"
	}

	#[string] Formatter() {
	#	if ($this.Selected) {
	#		#return "`e[31m"
	#		return "`e[44m"
	#	} else {
	#		return "`e[0m"
	#	}
	#}
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
    }

	[void] SetLine([int]$LineIndex, [string]$Text) {
		$this.Lines[$LineIndex].Text = $Text
		$this.Lines[$LineIndex].Dirty = $true
	}

	[void] SetLine([int]$LineIndex, [string]$Text, [string]$Formatter) {
		$this.Lines[$LineIndex].Text = $Text
		$this.Lines[$LineIndex].Formatter = $Formatter
		$this.Lines[$LineIndex].Dirty = $true
	}

	[void] Draw() {
		clear
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			$this.DrawLine($i, $line.Text, $line.Formatter)
			$line.Dirty = $false
		}
	}

	[void] ReDraw() {
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			if ($line.Dirty) {
				$this.DrawLine($i, $line.Text, $line.Formatter)
				$line.Dirty = $false
			}
		}
	}

	[void] DrawLine([int]$LineIndex, [string]$Text, [string]$Formatter) {
		$l = $LineIndex + 1
		Write-Host "`e[$l;1H`e[K| $Formatter$Text`e[0m"
	}
}

class FileGuiLine {
	[System.IO.FileSystemInfo]$File
	[bool]$Selected

	FileGuiLine([System.IO.FileSystemInfo]$File) {
		$this.File = $File
		$this.Selected = $false
	}

	[string] Formatter() {
		if ($this.File.GetType() -eq [System.IO.DirectoryInfo]) {
			return $this.FormatterDirectory()
		} else {
			return $this.FormatterFile()
		}
	}

	[string] FormatterDirectory() {
		if ($this.Selected) {
			return "`e[33;45m"
		} else {
			return "`e[33m"
		}
	}

	[string] FormatterFile() {
		if ($this.Selected) {
			return "`e[45m"
		} else {
			return "`e[0m"
		}
	}

	[string] Text() {
		if ($this.File.GetType() -eq [System.IO.DirectoryInfo]) {
			return "$this.File.Name/"
		} else {
			return $this.File.Name	
		}
	}
}

class FileGui {
	[FileGuiLine[]]$Lines
	[Gui]$Gui

	FileGui() {
		$this.Gui = [Gui]::new()
		$this.Gui.Draw()
	}

	[void] SetFiles([System.IO.FileSystemInfo[]]$Files) {
		$this.Lines = foreach ($file in $Files) {
			$file = [FileGuiLine]::new($file)
			Write-Output $file
		}
		
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			$this.Gui.SetLine($i, $line.Text(), $line.Formatter())
		}

		$this.Gui.ReDraw()
	}

	[void] SetLineSelected([int]$LineIndex) {
		$line = $this.Lines[$LineIndex]
		$line.Selected = $true
		$this.Gui.SetLine($LineIndex, $line.Text(), $line.Formatter())

		$this.Gui.ReDraw()
	}

	[void] SetAllLinesDeselected() {
		for ($i = 0; $i -lt $this.Lines.Length; $i++) {
			$line = $this.Lines[$i]
			if ($line.Selected) {
				$line.Selected = $false
				$this.Gui.SetLine($i, $line.Text(), $line.Formatter())
			}
		}

		$this.Gui.ReDraw()
	}
}

function Main {
	$gui = [FileGui]::new()

	$files = Get-ChildItem
	$gui.SetFiles($files)

	
	$cursorLine = 0
	$gui.SetLineSelected($cursorLine)
	
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
	} while ($keepGoing)

	clear
}

Main
