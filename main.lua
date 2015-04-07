-----------------------------------------------------------------------------------------
--
-- main.lua
-- Developed by Julio Rendon
--
-----------------------------------------------------------------------------------------

-- Hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- Set Default Anchor Points
display.setDefault("anchorX", 0)
display.setDefault("anchorY", 0)

-- Random Seed
math.randomseed(os.time())

-- Storyboard
local storyboard = require("storyboard")

-- loading start screen
storyboard.gotoScene("start")

