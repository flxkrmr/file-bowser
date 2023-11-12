class GuiLine {
	[bool]$Dirty
	
	[string]$Text
	[string]$Formatter
	
	GuiLine() {
		$this.Dirty = $false
		$this.Formatter = "`e[0m"
	}

	[void] Reset() {
		$this.Text = ""
		$this.Formatter = "`e[0m"
		$this.Dirty = $true
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
	}

	[void] SetLine([int]$LineIndex, [string]$Text, [string]$Formatter) {
		if ($LineIndex -gt ($this.Lines.Length - 1)) {
			return
		}

		$this.Lines[$LineIndex].Text = $Text
		$this.Lines[$LineIndex].Formatter = $Formatter
		$this.Lines[$LineIndex].Dirty = $true
	}

	[void] Draw() {
		clear
		# Hide cursor
		Write-Host "`e[?25l"]`"
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
		Write-Host "`e[$l;1H`e[K$Formatter$Text`e[0m"
		# Reset cursor
		$h = $this.Height
		Write-Host "`e[$h;1H"
	}

	[void] ResetAllLines() {
		foreach ($line in $this.Lines) {
			$line.Reset()
		}
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
			return "`e[33;44m"
		} else {
			return "`e[33m"
		}
	}

	[string] FormatterFile() {
		if ($this.Selected) {
			return "`e[44m"
		} else {
			return "`e[0m"
		}
	}

	[string] Text() {
		if ($this.IsDirectory()) {
			return $this.File.Name + "/"
		} else {
			return $this.File.Name	
		}
	}

	[boolean] IsDirectory() {
		return $this.File.GetType() -eq [System.IO.DirectoryInfo]
	}
}

class FileGui {
	[FileGuiLine[]]$FileLines
	[Gui]$Gui
	[int]$FileCursorLine
	[string]$CurrentLocation

	FileGui() {
		$this.Gui = [Gui]::new()
		$this.Gui.Draw()
		$this.FileCursorLine = 0
	}

	[void] SetFiles([System.IO.FileSystemInfo[]]$Files) {
		$this.FileLines = @()
		$this.Gui.ResetAllLines()
		$this.FileCursorLine = 0
		
		$this.FileLines = foreach ($file in $Files) {
			$file = [FileGuiLine]::new($file)
			Write-Output $file
		}
		
		for ($i = 0; $i -lt $this.FileLines.Length; $i++) {
			$line = $this.FileLines[$i]
			$this.Gui.SetLine($i+2, $line.Text(), $line.Formatter())
		}

		$this.SetFileLineSelected($this.FileCursorLine)

		$this.Gui.ReDraw()
	}

	[void] SetFileLineSelected([int]$LineIndex) {
		if ($this.FileLines.Length -eq 0) {
			return
		}

		$line = $this.FileLines[$LineIndex]
		$line.Selected = $true
		$this.Gui.SetLine($LineIndex+2, $line.Text(), $line.Formatter())
	}

	[void] SetAllFileLinesDeselected() {
		if ($this.FileLines.Length -eq 0) {
			return
		}

		for ($i = 0; $i -lt $this.FileLines.Length; $i++) {
			$line = $this.FileLines[$i]
			if ($line.Selected) {
				$line.Selected = $false
				$this.Gui.SetLine($i+2, $line.Text(), $line.Formatter())
			}
		}
	}

	[void] IncFileCursorLine() {
		if ($this.FileLines.Length -eq 0) {
			return
		}

		$this.FileCursorLine++
		if ($this.FileCursorLine -gt $this.FileLines.Length - 1) {
			$this.FileCursorLine = 0
		}

		$this.SetAllFileLinesDeselected()
		$this.SetFileLineSelected($this.FileCursorLine)

		$this.Gui.ReDraw()
	}

	[void] DecFileCursorLine() {
		if ($this.FileLines.Length -eq 0) {
			return
		}

		$this.FileCursorLine--
		if ($this.FileCursorLine -lt 0) {
			$this.FileCursorLine = $this.FileLines.Length - 1
		}

		$this.SetAllFileLinesDeselected()
		$this.SetFileLineSelected($this.FileCursorLine)

		$this.Gui.ReDraw()
	}

	[void] DisplayCurrentDirectory() {
		$files = Get-ChildItem
		$this.SetFiles($files)
		
		$location = Get-Location
		$this.CurrentLocation = $location.Path
		
		$this.Gui.SetLine(0, $this.CurrentLocation, "`e[32m")
		
		$this.Gui.ReDraw()
	}

	[void] ChangeDirectoryToCursor() {
		if ($this.FileLines.Length -eq 0) {
			return
		}

		$line = $this.FileLines[$this.FileCursorLine]
		if ($line.IsDirectory()) {
			Set-Location -Path $line.File.Name
			$this.DisplayCurrentDirectory()
		} else {
			# TODO warning sound
			#Write-Host "`a`r"
		}
	}

	[void] ChangeDirectoryToTop() {
		Set-Location -Path ..
		$this.DisplayCurrentDirectory()
	}
}

function Main {
	$gui = [FileGui]::new()

	$gui.DisplayCurrentDirectory()

	$keepGoing = $true
	Do {
		$key = [System.Console]::ReadKey()

		switch($key.Key) {
			K {
				$gui.DecFileCursorLine()
			}
			J {
				$gui.IncFileCursorLine()
			}
			Enter {
				$gui.ChangeDirectoryToCursor()
			}
			OemMinus {
				$gui.ChangeDirectoryToTop()
			}
			Q {
				$keepGoing = $false
			}
		}
	} while ($keepGoing)

	clear
}

Main
