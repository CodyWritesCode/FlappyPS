## SFML assemblies must be loaded before running: .\LoadSFML.ps1

# Classes -----------------------------------------------------------------------------

# Player
Class Player : SFML.Graphics.Drawable
{
	[SFML.Graphics.Sprite]$sprite
	[float]$height
	[float]$yVel
	
	[bool]$dead
  
	# Constructor
	Player () {
		$this.dead = $FALSE
	
		$this.height = 300
		$this.yVel = 0.1
		$size = New-Object -TypeName SFML.System.Vector2f -ArgumentList 32, 32
		
		$tex = New-Object -TypeName SFML.Graphics.Texture -ArgumentList "Sprites/parrot.png"
		
		$this.sprite = New-Object -TypeName SFML.Graphics.Sprite -ArgumentList $tex
		$this.sprite.Origin = New-Object -TypeName SFML.System.Vector2f -ArgumentList 16, 16
		$this.sprite.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList 300, $this.height
	}

	# SFML.Drawable.Draw() override
	Draw ([SFML.Graphics.RenderTarget]$target, [SFML.Graphics.RenderStates]$states) {
		$target.Draw($this.sprite)
	}

	Update () {
		$this.yVel += 0.13
		$this.height += $this.yVel
		$this.sprite.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.sprite.Position.X, $this.height
	}
	
	Flap() {
		$this.yVel = -4
	}
	
	Die() {
		If ($this.dead -eq $FALSE) {
			$this.dead = $TRUE
			$this.yVel = 20
			Write-Host Oops, you died.
		}
	}
	
	[SFML.Graphics.FloatRect]GetBounds () {
		Return $this.sprite.GetGlobalBounds()
	}
}


# Wall
Class Wall : SFML.Graphics.Drawable
{
	[SFML.Graphics.RectangleShape]$top
	[SFML.Graphics.RectangleShape]$bottom
	
	[System.Collections.Generic.List[SFML.Graphics.Sprite]]$sprites
	
	[float]$openingHeight
	[float]$openingY
	
	[float]$x
	
	[bool]$passed
	
	# Constructor
	Wall ($beginX) {
		$this.openingHeight = 150
		$width = 64
		
		$this.x = $beginX
		
		$this.openingY = Get-Random -Maximum 500 -Minimum 100
		
		$this.passed = $FALSE
		
		# Texturing
		
		$tex = New-Object -TypeName SFML.Graphics.Texture -ArgumentList "Sprites/wall.png"
		
		$this.sprites = New-Object -TypeName System.Collections.Generic.List[SFML.Graphics.Sprite]
		
		For ($topSpr = 0; $topSpr -lt 10; $topSpr++) {
			$thisSpr = New-Object -TypeName SFML.Graphics.Sprite -ArgumentList $tex
			$thisSpr.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, ( ($this.openingY - ($this.openingHeight / 2) - 64) - ($topSpr * 64) )
			
			$this.sprites.Add($thisSpr)
		}

		For ($bottomSpr = 0; $bottomSpr -lt 10; $bottomSpr++) {
			$thisSpr = New-Object -TypeName SFML.Graphics.Sprite -ArgumentList $tex
			$thisSpr.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, ( ($this.openingY + ($this.openingHeight / 2)) + ($bottomSpr * 64) )
			
			$this.sprites.Add($thisSpr)
		}
		
		# Old Rectangles
		
		$this.top = New-Object -TypeName SFML.System.Vector2f -ArgumentList $width, ($this.openingY - ($this.openingHeight / 2))
		$this.top.FillColor = [SFML.Graphics.Color]::Red
		
		$this.bottom = New-Object -TypeName SFML.System.Vector2f -ArgumentList $width, 600
		$this.bottom.FillColor = [SFML.Graphics.Color]::Red
	}
	
	# Whether either wall is colliding with the player
	[bool]TestCollision ($player) {
		If ($player.GetBounds().Intersects($this.top.GetGlobalBounds()) -Or $player.GetBounds().Intersects($this.bottom.GetGlobalBounds())) {
			Return $TRUE
		}
		Else {
			Return $FALSE
		}
	}
	
	# SFML.Drawable.Draw() override
	Draw ([SFML.Graphics.RenderTarget]$target, [SFML.Graphics.RenderStates]$states) {
		
		# old rectangles
		$target.Draw($this.top)
		$target.Draw($this.bottom)
		
		# sprites
		ForEach ($spr in $this.sprites) {
			$spr.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, $spr.Position.Y
			$target.Draw($spr)
		}
	}
	
	Update () {	
		$this.x += $Global:xSpeed
		
		$this.top.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, 0
		
		$this.bottom.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList $this.x, ($this.openingY + ($this.openingHeight / 2))
		
		If ($this.x -lt 220 -And $this.passed -eq $FALSE) {
			$this.passed = $TRUE
			$Global:score++
			$Global:window.SetTitle("FlappyPS - Score: " + $Global:score)
			$Global:scoreText.DisplayedString = $Global:score
		}
	}
	
}

# Global Variables -----------------------------------------------------------------------

# Speed at which the walls are moving
$Global:xSpeed = -2

$Global:player = New-Object -TypeName Player

# Create a list of 5 walls, 300px apart
$Global:wallList = New-Object -TypeName System.Collections.Generic.List[Wall]

For ($i = 0; $i -lt 5; $i++) {
	$wallList.Add( (New-Object -TypeName Wall -ArgumentList (600 + (300 * $i))) )
}

$Global:score = 0

$Global:window = New-Object -TypeName SFML.Graphics.RenderWindow -ArgumentList (New-Object SFML.Window.VideoMode -ArgumentList 600, 600, 32), "FlappyPS", ([SFML.Window.Styles]::Close)
$Global:window.SetFramerateLimit(60)

# Score text
$font = New-Object -TypeName SFML.Graphics.Font -ArgumentList "C:\Windows\Fonts\arial.ttf"

$Global:scoreText = New-Object -TypeName SFML.Graphics.Text -ArgumentList $Global:score, $font, 60
$Global:scoreText.Color = [SFML.Graphics.Color]::Black
$Global:scoreText.Position = New-Object -TypeName SFML.System.Vector2f -ArgumentList 240, 10


# Global Functions -------------------------------------------------------------------

# Wall Reset
Function global:WallReset () {
	
	# If the first wall is off the screen, regenerate and move to end of list
	$thisWall = $wallList[0]
	
	If ($thisWall.x -le (-60)) {
		$wallList.Remove($thisWall)
	
		$thisWall = New-Object -TypeName Wall -ArgumentList ($wallList[3].x + 300)
		$wallList.Add($thisWall)
	}
}

# Key Handler
Function global:ProcessKey ($key) {
	Switch ($key)
	{
		Escape	{ $window.Close() }
		Space	{ $player.Flap() }
	}
}

# Events --------------------------------------------------------------------------

Register-ObjectEvent -InputObject $window -EventName Closed -Action { $sender.Close() }
Register-ObjectEvent -InputObject $window -EventName KeyPressed -Action { ProcessKey($EventArgs.Code) }
Register-ObjectEvent -InputObject $window -EventName MouseButtonPressed -Action { $Global:player.Flap() }

# Main Loop -----------------------------------------------------------------------

While ($window.IsOpen -eq $TRUE)
{
	$window.DispatchEvents()
	
	$window.Clear([SFML.Graphics.Color]::Cyan)
	
	$player.Update()
	
	ForEach ($wall in $wallList) {
		$wall.Update()
		$window.Draw($wall)
		
		If ($wall.TestCollision($player) -Or $player.height -gt 630) {
			$player.Die()
			$Global:xSpeed = 0
			$window.SetTitle("FlappyPS - Score: " + $Global:score + " - Dead. Press Esc to close.")
		}
	}

	$window.Draw($player)
	
	$window.Draw($Global:scoreText)
	
	WallReset
	
	$window.Display()
}