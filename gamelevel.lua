-----------------------------------------------------------------------------------------
--
-- gamelevel.lua
-- Developed by Julio Rendon
--
-----------------------------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()

-- Variables
local playerSpeedY = 0
local playerSpeedX = 0
local playerMoveSpeed = 7
local playerWidth = 60
local playerHeight = 48
local bulletWidth = 8
local bulletHeight = 19
local islandHeight = 81
local islandWidth = 100
local numberofEnemysToGenerate = 0
local numberofEnemysGenerated = 0
local playerBullets = {} -- All the bullets the player fires
local enemyBullets = {} -- Bullets for all enemy planes
local islands = {} -- All the islands
local planeGrid = {} -- Holds 0 or 1  (11 of them for making a grid system)
local enemyPlanes = {} -- All enemy planes
local livesImages = {} -- All the free life images
local numberOfLives = 3
local freeLifes  = {} -- All the ingame free lives
local playerIsInvincible = false
local gameOver = false
local numberOfTicks = 0 -- A number that is incremented each frame of the game
local islandGroup -- Group that holds all the island
local planeGroup -- Group that holds all the planes, bullets, etc
local player
local planeSoundChannel -- SoundChannel for the plane sound
local firePlayerBulletTimer
local generateIslandTimer
local fireEnemyBulletsTimer
local rectUp -- The Up control o the DPAD
local rectDown -- The Down control o the DPAD
local rectLeft -- The Left control o the DPAD
local rectRight -- The Right control o the DPAD

function scene:createScene(event)
	local group = self.view
	setupBackground()
	setupGroups()
	setupDisplay()
	setupPlayer()
	setupLivesImages()
	setupDPad()
	resetPlaneGrid()
end
scene:addEventListener("createScene", scene) -- registering createScene event method	

function setupBackground()
	local background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	background:setFillColor(0, 0, 1) -- Color Blue. RGB Values as percentages
	scene.view:insert(background)
end	

-- Its important to add first the islandGroup and then the planeGroup to make sure
-- the islands are below the planes
function setupGroups()
	islandGroup = display.newGroup()
	planeGroup = display.newGroup()
	scene.view:insert(islandGroup) 
	scene.view:insert(planeGroup)
end	

-- Draws a black rectangle at the bottom of the screen and inserts dpad and plane images into the view.
function setupDisplay()
	local tempRect = display.newRect(0, display.contentHeight - 100, display.contentWidth, 124)
	tempRect:setFillColor(0, 0, 0)
	scene.view:insert(tempRect)
	local logo = display.newImage("logo.png", display.contentWidth - 139, display.contentHeight - 100)
	scene.view:insert(logo)
	local dpad = display.newImage("dpad.png", 10, display.contentHeight - 70)
	scene.view:insert(dpad)
end	

-- The setupPlayer function simply adds the player image to the screen
function setupPlayer()
	player = display.newImage("player.png", (display.contentWidth / 2) - (playerWidth / 2), (display.contentHeight - 100) - playerHeight)
	player.name = "Player"
	scene.view:insert(player)
end	

-- The setupLivesImages function sets up six life images and positions them at the top left of the screen
-- Only the first three images are visible.
function setupLivesImages()
	for i = 1, 6 do
		local tempLifeImage = display.newImage("life.png", 40 * i - 20, 10)
		table.insert(livesImages, tempLifeImage)
		scene.view:insert(tempLifeImage)
		if (i > 3) then
			tempLifeImage.isVisible = false
		end	
	end	
end	

-- he setupDPad function sets up the four rectangles rectUp, rectDown, rectLeft, and rectRight
function setupDPad()
	rectUp = display.newRect(83, display.contentHeight-74, 70, 70)
	rectUp:setFillColor(1, 0, 0)
	rectUp.id = "up"
	rectUp.isVisible = false
	rectUp.isHitTestable = true
	scene.view:insert(rectUp)

	rectDown = display.newRect(85, display.contentHeight+61, 70,70)
    rectDown:setFillColor(1,0,0)
    rectDown.id ="down"
  	rectDown.isVisible = false;
    rectDown.isHitTestable = true;
    scene.view:insert(rectDown)
 
    rectLeft = display.newRect(10, display.contentHeight -8, 70, 70)
    rectLeft:setFillColor(1,0,0)
    rectLeft.id ="left"
    rectLeft.isVisible = false;
    rectLeft.isHitTestable = true;
    scene.view:insert(rectLeft)
 
    rectRight= display.newRect(155, display.contentHeight-8, 70,70)
    rectRight:setFillColor(1,0,0)
    rectRight.id ="right"
    rectRight.isVisible = false;
    rectRight.isHitTestable = true;
    scene.view:insert(rectRight)
end	

-- The resetPlaneGrid function resets the planeGrid table and inserts eleven zeros. The planeGrid table imitates eleven spots across the x axis, in which an enemy plane can be positioned.
function resetPlaneGrid()
	planeGrid = {}
	for i = 1, 11 do
		table.insert(planeGrid, 0)
	end	
end	

-- The enterScene function is a good place to set up the event listeners, timers, etc
function scene:enterScene(event)
	local group = self.view

	-- When we enter this scene, we need to remove the previous scene
	local previousScene = storyboard.getPrevious()
	storyboard.removeScene(previousScene)

	-- Adding touch listener to the dpad rectangles
	rectUp:addEventListener("touch", movePlane)
	rectDown:addEventListener( "touch", movePlane)
	rectLeft:addEventListener( "touch", movePlane)
	rectRight:addEventListener( "touch", movePlane)

	-- plane sound loop forever
	local planeSound = audio.loadStream("planesound.wav")
	planeSoundChannel = audio.play(planeSound, {channel = 1, loops = -1})

	-- Runtime event listener enterFrame that calls gameLoop function
	-- The frequency with which the enterFrame event occurs depends on the frames
	-- per second (FPS) value you set in config.lua
	Runtime:addEventListener("enterFrame", gameLoop)

	-- timers
	startTimers()

	genereteEnemies()
end
scene:addEventListener("enterScene", scene)  -- Registering enterScene event method	

-- The movePlane function is responsible for setting the planes speed. 
-- We check if the touch event's phase is equal to began, which means 
-- the player has touched down but not lifted their finger back up. 
-- If this is true, we set the speed and direction according to which 
-- rectangle was touched. If the touch event's phase is equal to ended, 
-- then we know the player has lifted their finger, which means 
-- we set the speed to 0.
function movePlane(event)
	if event.phase == "began" then
		
		if (event.target.id == "up") then
			playerSpeedY = -playerMoveSpeed
		end	

		if (event.target.id == "down") then
			playerSpeedY = playerMoveSpeed
		end	

		if (event.target.id == "left") then
			playerSpeedX = -playerMoveSpeed
		end	

		if (event.target.id == "right") then
			playerSpeedX = playerMoveSpeed
		end	

	elseif event.phase == "ended" then
		playerSpeedX = 0
		playerSpeedY = 0
	end	

end	

-- In the gameLoop function we update the sprite positions and perform 
-- any other logic that needs to take place every frame
function gameLoop()
	numberOfTicks = numberOfTicks + 1
	movePlayer()
	movePlayerBullets()
	checkPlayerBulletsOutOfBounds()
	moveIslands()
	checkIslandsOutOfBounds()
	moveFreeLifes()
	checkFreeLifesOutOfBounds()
	checkPlayerCollidesWithFreeLife()
	moveEnemyPlanes()
	moveEnemyBullets()
	checkEnemyPlanesOutOfBounds()
	checkEnemyBulletsOutOfBounds()
	checkPlayerBulletCollidesWithEnemyPlanes()
	checkEnemyBulletsCollideWithPlayer()

end	

-- The movePlayer function manages the moving of the player's plane.
-- We move the plane according to the playerSpeedX and playerSpeedY values
function movePlayer()
	player.x = player.x + playerSpeedX
	player.y = player.y + playerSpeedY

	-- Making sure the plane cannot move off-screen.
	if(player.x < 0) then
		player.x = 0
	end	

	if(player.x > display.contentWidth - playerWidth) then
		player.x = display.contentWidth - playerWidth
	end

	if (player.y < 0) then
		player.y = 0
	end	

	if(player.y > display.contentHeight - 100 -playerHeight) then
		player.y = display.contentHeight - 100 - playerHeight
	end	
end	

-- Starts the timers
function startTimers()
	firePlayerBulletTimer = timer.performWithDelay(2000, firePlayerBullet, -1) -- fire a bullet every 2 seconds, do it forever (-1)
	generateIslandTimer = timer.performWithDelay(5000, generateIsland, -1)
	genetateFreeLifeTimer = timer.performWithDelay(15000, generateFreeLife, -1)
	fireEnemyBulletsTimer = timer.performWithDelay(2000, fireEnemyBullets, -1)
end	

-- Creates a bullet for the player
function firePlayerBullet()
	local tempBullet = display.newImage("bullet.png",(player.x+playerWidth/2) - bulletWidth,player.y-bulletHeight)
	table.insert(playerBullets, tempBullet)
	planeGroup:insert(tempBullet)
end	

-- we loop through the playerBullets table and change the 
-- y coordinate of every bullet. We first check to make sure 
-- the playerBullets table has bullets in it
function movePlayerBullets()
	if(#playerBullets > 0) then -- the '#'' returns the lenght of the object
		for i=1, #playerBullets do
			playerBullets[i].y = playerBullets[i].y - 7 -- moving every bullet one by one
		end
	end
end			

-- Once the bullets move off-screen, we remove them from the 
-- playerBullets table as well as from from the display
function checkPlayerBulletsOutOfBounds()
	if(#playerBullets > 0) then
		for i=#playerBullets, 1, -1 do
			if(playerBullets[i].y < -10) then
				playerBullets[i]:removeSelf()  -- removing the bullet display object
				playerBullets[i] = nil
				table.remove(playerBullets, i) -- removing bullet from the playerBullets table
			end	
		end	
	end	
end

-- generate islands
function generateIsland()
	local tempIsland = display.newImage("island1.png", math.random(0,display.contentWidth - islandWidth), islandHeight)
	table.insert(islands, tempIsland) 
	islandGroup:insert(tempIsland) 
end

-- moving islands
function moveIslands()
	if(#islands > 0) then
		for i=1, #islands do
			islands[i].y = islands[i].y + 3
		end		
	end	
end

-- cheking islands out of bounds
function checkIslandsOutOfBounds()
	if(#islands > 0) then
		for i=#islands, 1, -1 do
			if(islands[i].y > display.contentHeight - islandHeight) then
				islands[i]:removeSelf()
				islands[i] = nil
				table.remove(islands, i)
			end	
		end	
	end	
end	

-- Every so often, the player has a chance to get a free life.
-- We first generate a free life image and if the player collides
-- with the image they get an extra life. The player can have a 
--maximum of six lives

function generateFreeLife()
	if(numberOfLives >= 6) then
		return
	end	

	local freeLife = display.newImage("newlife.png", math.random(0,display.contentWidth - 40), 0)
	table.insert(freeLifes, freeLife)
	planeGroup:insert(freeLife)
end	

-- Function to move free lifes
function moveFreeLifes()
	if(#freeLifes > 0) then
		for i=1, #freeLifes do
			freeLifes[i].y = freeLifes[i].y + 5
		end
	end
end

-- freelifes out of bounds check
function checkFreeLifesOutOfBounds()
	if(#freeLifes > 0) then
		for i=#freeLifes, 1, -1 do
			if(freeLifes[i].y > display.contentHeight - 15) then
				freeLifes[i]:removeSelf()
				freeLifes[i] = nil
				table.remove(freeLifes, i)
			end
		end
	end	
end	

-- Simple bounding box collision detection system
function hasCollided(obj1, obj2)
	if(obj1 == nil) then
		return false
	end
	
	if(obj2 == nil) then
		return false
	end	

	local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
   	local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
   	local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
   	local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax
 
   	return (left or right) and (up or down)
end	


-- PLayer collided with free life
function checkPlayerCollidesWithFreeLife()
	if(#freeLifes > 0) then
		for i=#freeLifes, 1, -1 do
			if(hasCollided(freeLifes[i], player)) then
				freeLifes[i]:removeSelf()
				freeLifes[i] = nil
				table.remove(freeLifes, i)	
				numberOfLives = numberOfLives + 1
				hideLives()
				showLives()
			end	
		end	
	end	
end

-- This function loops through the livesImages table and sets the 
-- isVisible property of each life image to false
function hideLives()
	for i=1, 6 do
		livesImages[i].isVisible = false
	end
end		

-- This function loops through the livesImages table and sets the 
-- isVisible property of each life image to true
function showLives()
	for i=1, numberOfLives do
		livesImages[i].isVisible = true
	end
end		

-- The generateEnemys function generates a number between three and 
--seven, and calls the generateEnemyPlane function every two seconds
function genereteEnemies()
	numberofEnemysToGenerate = math.random(3, 7)
	timer.performWithDelay(3000, generateEnemyPlane, -1)
end	

-- The generateEnemyPlane function generates one enemy plane. 
--There are three types of enemy planes in this game.
-- Regular , moves down the screen in a straight line
-- Waver, moves in a wave pattern on the x axis
-- Chaser, chases the player's plane
function generateEnemyPlane()
	if(gameOver ~= true) then
		local randomGridSpace = math.random(11)
		local randomEnemyNumber = math.random(3)
		local tempEnemy
		
		if(planeGrid[randomGridSpace] ~= 0) then
			generateEnemyPlane()
			return
		else
			if(randomEnemyNumber == 1) then
				tempEnemy =  display.newImage("enemy1.png", (randomGridSpace*65)-28,-20)
            	tempEnemy.type = "regular"
        	elseif(randomEnemyNumber == 2) then
             	tempEnemy =  display.newImage("enemy2.png", display.contentWidth/2 -playerWidth/2,-20)
       	 		tempEnemy.type = "waver"
        	else
        		tempEnemy =  display.newImage("enemy3.png", (randomGridSpace*65)-28,-20)
        		tempEnemy.type = "chaser"
       		end

       		planeGrid[randomGridSpace] = 1
       		table.insert(enemyPlanes, tempEnemy)
       		planeGroup:insert(tempEnemy)
       		numberofEnemysGenerated = numberofEnemysGenerated + 1
		end	
		if (numberofEnemysGenerated == numberofEnemysToGenerate) then
			numberofEnemysGenerated = 0
			resetPlaneGrid()
			timer.performWithDelay(2000, generateEnemies, 1)
			print "ok"
		end	
	end	
end	

-- moveEnemyPlanes function is responsible for moving the enemy planes. 
-- Depending on the plane's type, the appropriate function is called.
function moveEnemyPlanes()
    if(#enemyPlanes > 0) then
        for i=1, #enemyPlanes do
            if(enemyPlanes[i].type ==  "regular") then
            	moveRegularPlane(enemyPlanes[i])
        	elseif(enemyPlanes[i].type == "waver") then
           		moveWaverPlane(enemyPlanes[i])
            else
           		moveChaserPlane(enemyPlanes[i])
        	end
    	end
    end
end

-- Simply moves the plane down the screen across the y axis.
function moveRegularPlane(plane)
	plane.y = plane.y + 4
end	

function moveWaverPlane()

end	

-- The moveWaverPlane function moves the plane down the screen across 
-- the y axis and, in a wave pattern, across the x axis. 
-- This is achieved by using the cos function of Lua's math library.
-- You should think sine when dealing with the y axis and cosine 
-- when dealing with the x axis
function moveWaverPlane(plane)
	plane.y =plane.y + 4 
	plane.x = (display.contentWidth/2)+ 250 * math.cos(numberOfTicks * 0.5 * math.pi/30)
end

-- The moveChaserPlane function has the plane chasing the player
function moveChaserPlane(plane)
    if(plane.x < player.x) then
    	plane.x = plane.x + 4
    end
    
    if(plane.x  > player.x)then
    	plane.x = plane.x - 4
   	end
   
   	plane.y = plane.y + 4
end

-- enemy planes out of bounds
function checkEnemyPlanesOutOfBounds()
	if(#enemyPlanes > 0) then
	  	for i=#enemyPlanes,1,-1 do
	       	if(enemyPlanes[i].y > display.contentHeight - 70) then
	      		enemyPlanes[i]:removeSelf()
	       		enemyPlanes[i] = nil
	       		table.remove(enemyPlanes, i) 
	        end
	 	end
	end
end

function fireEnemyBullets()
	if(#enemyPlanes >= 2) then
		local numberOfEnemyPlanesToFire = math.floor(#enemyPlanes/2)
		local tempEnemyPlanes = table.copy(enemyPlanes)
		
		local function fireBullet()
			local randIndex = math.random(#tempEnemyPlanes)
			local tempBullet = display.newImage("bullet.png",  (tempEnemyPlanes[randIndex].x+playerWidth/2) + bulletWidth,tempEnemyPlanes[randIndex].y+playerHeight+bulletHeight)
			tempBullet.rotation = 180
        	planeGroup:insert(tempBullet)
        	table.insert(enemyBullets,tempBullet);
    		table.remove(tempEnemyPlanes,randIndex)
    	end

    	for i = 0, numberOfEnemyPlanesToFire do
        	fireBullet()
    	end

    end	
end	

function moveEnemyBullets()
    if(#enemyBullets > 0) then
	    for i=1,#enemyBullets do
	           enemyBullets[i]. y = enemyBullets[i].y + 7
	    end
    end
end

function checkEnemyBulletsOutOfBounds() 
    if(#enemyBullets > 0) then
	    for i=#enemyBullets,1,-1 do
	        if(enemyBullets[i].y > display.contentHeight) then
	        	enemyBullets[i]:removeSelf()
	        	enemyBullets[i] = nil
	        	table.remove(enemyBullets,i)
	        end             
	    end
    end
end

-- The checkPlayerBulletCollidesWithEnemyPlanes function uses the 
-- hasCollided function to check whether any of the player's bullets 
-- has collided with any of the enemy planes.
function checkPlayerBulletCollidesWithEnemyPlanes()
	if(#playerBullets > 0 and #enemyPlanes > 0) then
		for i=#playerBullets, 1, -1 do
			for j=#enemyPlanes, 1, -1 do
				if(hasCollided(playerBullets[i], enemyPlanes[j])) then
					playerBullets[i]:removeSelf()
					playerBullets[i] = nil
					table.remove(playerBullets, i)
					generateExplosion(enemyPlanes[j].x, enemyPlanes[j].y)
					enemyPlanes[j]:removeSelf()
					enemyPlanes[j] = nil
					table.remove(enemyPlanes, j)
					local explosion = audio.loadStream("explosion.mp3")
					local backgroundMusicChannel = audio.play(explosion, {fadein=1000 })
				end	
			end
		end		
	end	
end

-- The generateExplosion function uses Corona's SpriteObject class. 
-- Sprites allow for animated sequences of frames that reside on Image 
-- or Sprite Sheets. By grouping images into a single image, you can 
-- pull certain frames from that image and create an animation sequence
function generateExplosion(xPosition, yPosition)
	local options = {width = 60, height = 49, numFrames = 6}
    local explosionSheet = graphics.newImageSheet("explosion.png", options)
   
    local sequenceData = {
     	{ name = "explosion", start=1, count=6, time=400, loopCount=1 }
    }
   
    local explosionSprite = display.newSprite(explosionSheet, sequenceData)
    explosionSprite.x = xPosition
    explosionSprite.y = yPosition
    explosionSprite:addEventListener("sprite", explosionListener)
    explosionSprite:play()	
end 

-- The explosionListener function is used to remove the sprite. 
-- If the event's phase property is equal to ended, then we know 
-- the sprite has finished its animation and we can remove it
function explosionListener(event)
	if(event.phase == "ended") then
		local explosion = event.target
		explosion:removeSelf()
		explosion = nil
	end
end	

function checkEnemyBulletsCollideWithPlayer()
    if(#enemyBullets > 0) then
        for i=#enemyBullets,1,-1 do
        	if(hasCollided(enemyBullets[i], player)) then
           		enemyBullets[i]:removeSelf()
             	enemyBullets[i] = nil
         		table.remove(enemyBullets,i)
         		if(playerIsInvincible == false) then
            		killPlayer()
        		end
       		end
        end
    end
end

-- The killPlayer function is responsible for checking whether the 
-- game is over and spawning a new player if it isn't.
function killPlayer()
	numberOfLives = numberOfLives - 1
	if(numberOfLives == 0) then
		gameOver = true
		doGameOver()
	else
		spawnNewPlayer()
		hideLives()
		showLives()
		playerIsInvincible = true	
	end	
end	

-- The doGameOver function tells the storyboard to go to 
-- the gameover scene.
function  doGameOver()
    storyboard.gotoScene("gameover")
end

-- The spawnNewPlayer function is responsible for spawning a 
-- new player after it has died. The player's plane blinks for a 
-- few seconds to show that it's temporarily invincible.
function spawnNewPlayer()
	local numberOfTimesToFadePlayer = 5
	local numberOfTimesPlayerHasFaded = 0
	
	local function fadePlayer()
		player.alpha = 0;
		transition.to(player, {time=200, alpha=1})
        numberOfTimesPlayerHasFaded = numberOfTimesPlayerHasFaded + 1
        if(numberOfTimesPlayerHasFaded == numberOfTimesToFadePlayer) then
             playerIsInvincible = false
    	end
    end
    
    timer.performWithDelay(400, fadePlayer, numberOfTimesToFadePlayer)
end	

function checkEnemyPlaneCollidesWithPlayer()
    if(#enemyPlanes > 0) then
    	for i=#enemyPlanes,1,-1 do
    		if(hasCollided(enemyPlanes[i], player)) then
    			generateExplosion(enemyPlanes[i].x, enemyPlanes[i].y)
    			local explosion = audio.loadStream("explosion.mp3")
				local backgroundMusicChannel = audio.play(explosion, {fadein=1000 })
        		
        		enemyPlanes[i]:removeSelf()
    			enemyPlanes[i] = nil
    			table.remove(enemyPlanes,i)
    			
    			if(playerIsInvincible == false) then
        			killPlayer()
    			end
  			end
		end
	end
end	

-- In this function is where you remove any event listeners, 
--stop timers, and stop audio that's playing
function scene:exitScene( event )
    local group = self.view
    rectUp:removeEventListener("touch", movePlane)
    rectDown:removeEventListener("touch", movePlane)
    rectLeft:removeEventListener("touch", movePlane)
    rectRight:removeEventListener("touch", movePlane)
    audio.stop(planeSoundChannel)
    audio.dispose(planeSoundChannel)
    Runtime:removeEventListener("enterFrame", gameLoop)
    cancelTimers()
end
scene:addEventListener("exitScene", scene)

-- It does the opposite of  startTimers, it cancels all the timers
function cancelTimers()
    timer.cancel(firePlayerBulletTimer)
    timer.cancel(generateIslandTimer)
    timer.cancel(fireEnemyBulletsTimer)
    timer.cancel(genetateFreeLifeTimer)
end

return scene