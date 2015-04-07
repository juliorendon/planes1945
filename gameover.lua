-----------------------------------------------------------------------------------------
--
-- gameover.lua
-- Developed by Julio Rendon
--
-----------------------------------------------------------------------------------------
local storyboard = require("storyboard")
local scene = storyboard.newScene()
local gameOverText
local newGameButton

function scene:createScene(event)
    local group = self.view
    local background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
    background:setFillColor( 0, .39, .75)
    group:insert(background)
    gameOverText = display.newText("Game Over", display.contentWidth/2,400, native.systemFont, 16)
    gameOverText:setFillColor(1, 1, 0)
    gameOverText.anchorX = .5
    gameOverText.anchorY = .5
    group:insert(gameOverText)
    newGameButton = display.newImage("newgamebutton.png", 264, 670)
    group:insert(newGameButton)
    newGameButton.isVisible = false
 end

--In enterScene, we remove the previous scene from the storyboard. 
-- We use the convenience method scaleTo from the Transition Library 
-- to scale the gameOverText by a factor of 4. We add an onComplete 
-- listener to the transition that calls the showButton function once 
-- the transition has completed. Lastly, we add a tap event listener 
-- to the game button that invokes the startNewGame function.
function scene:enterScene( event )
    local group = self.view
    storyboard.removeScene("gamelevel")
    transition.scaleTo(gameOverText, { xScale=4.0, yScale=4.0, time=2000, onComplete=showButton} )
    newGameButton:addEventListener("tap", startNewGame)
end

-- The showButton function hides the gameOverText and shows the 
-- newGameButton.
function showButton()
   gameOverText.isVisible = false
   newGameButton.isVisible= true
end

-- The startNewGame function tells the storyboard to transition to 
-- the gamelevel scene.
function startNewGame()
    storyboard.gotoScene("gamelevel")
end
 
 -- We need to do some cleanup when we leave the gameover scene. 
 -- We remove the tap event listener we added earlier to the 
 -- newGameButton
 function scene:exitScene( event )
    local group = self.view
    newGameButton:removeEventListener("tap",startNewGame)
end

-- registering scene event method listeners
scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )


return scene