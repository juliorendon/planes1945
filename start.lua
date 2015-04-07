-----------------------------------------------------------------------------------------
--
-- start.lua
-- Developed by Julio Rendon
--
-----------------------------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()

local startbutton

-- Event methods for scenes createScene, enterScene, and exitScene

-- The createScene method is called when the scene's view doesn't exist yet
-- This is where you should initialize the display objects and add them to the scene 
function scene:createScene(event)
	local group = self.view
	local background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	background:setFillColor(0, .39, .75)
	group:insert(background)
	local bigplane = display.newImage("bigplane.png", 0, 0)
	group:insert(bigplane)
	startbutton = display.newImage("startbutton.png", 264, 670)
	group:insert(startbutton)
end	

-- The enterScene method is called immediately after the scene has moved 
-- onscreen. This is where you can add event listeners, start timers, load 
-- audio, etc
function scene:enterScene(event)
	startbutton:addEventListener("tap", startGame)
end	

-- The exitScene method is called when the scene is about to move 
-- off-screen. This is where you want to undo whatever you set up in 
-- the enterScene method, such as removing event listeners, stop 
-- timers, unload audio, etc
function scene:exitScene(event)
	startbutton:removeEventListener("tap", startGame)
end

function startGame()
	storyboard.gotoScene("gamelevel")
end	

-- Registering createScene, enterScene, and exitScene event methods
scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)

-- The last thing you must make sure you do in a storyboard is returning the scene, because it's a module
return scene
