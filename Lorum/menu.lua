
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local json = require( "json" )

-- global variables
optionsTable = {}		--background, cardback, difficoulty, speed, sound (sound is not implemented)
optionsFilePath = system.pathForFile( "options.json", system.DocumentsDirectory )

-- global functions

function gotoMenu()
    composer.gotoScene( "menu", { time=800, effect="crossFade" } )
end

local function loadOptions()
    local file = io.open( optionsFilePath, "r" )
 
    if file then
        local contents = file:read( "*a" )
        io.close( file )
        optionsTable = json.decode( contents )		
    end
 
    if ( optionsTable == nil or #optionsTable == 0 ) then
        optionsTable = {1,1,false,1000,0}
	end
		
end


local function gotoGame()
    composer.gotoScene( "game", { time=800, effect="crossFade" } )
end
 
local function gotoOptions()
    composer.gotoScene( "options", { time=800, effect="crossFade" } )
end

local function gotoRules()
    composer.gotoScene( "rules", { time=800, effect="crossFade" } )
end

local function gotoWebsite()
	--shellExecute('www.bausoft.hu')

end

function fitImage( displayObject, fitWidth, fitHeight, enlarge )
	--
	-- first determine which edge is out of bounds
	--
	local scaleFactor = fitHeight / displayObject.height 
	local newWidth = displayObject.width * scaleFactor
	if newWidth > fitWidth then
		scaleFactor = fitWidth / displayObject.width 
	end
	if not enlarge and scaleFactor > 1 then
		return
	end
	displayObject:scale( scaleFactor, scaleFactor )
end

function drawBackground( background)

	fitImage( background, display.contentWidth+300, display.contentHeight+200, false )
    background.x = display.contentCenterX
    background.y = display.contentCenterY	
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	local background = display.newImageRect( sceneGroup, "menuback.png", 3000, 2000 )
	drawBackground(background)
	
	--setting default options
	loadOptions()
	
	--[[
	local title = display.newImageRect( sceneGroup, "title.png", 500, 80 )
    title.x = display.contentCenterX
    title.y = 200
	--]]
	
	local playButton = display.newText( sceneGroup, "Játék", display.contentCenterX*1.6, display.contentCenterY*0.4 -50, native.systemFont, 70)
    playButton:setFillColor( 0,0,0 )
 
    local optionsButton = display.newText( sceneGroup, "Beállítások", display.contentCenterX*1.6, display.contentCenterY*0.4 +75, native.systemFont, 70 )
    optionsButton:setFillColor( 0,0,0 )
	
	local rulesButton = display.newText( sceneGroup, "Szabályok", display.contentCenterX*1.6, display.contentCenterY*0.4 +200, native.systemFont, 70 )
    rulesButton:setFillColor( 0,0,0 )
	
	local logo = display.newImageRect( sceneGroup, "bausoft_logo.png", 314, 84 )
    logo.x = display.contentCenterX*1.7
    logo.y = display.contentCenterY*1.9
	
	
	playButton:addEventListener( "tap", gotoGame )
    optionsButton:addEventListener( "tap", gotoOptions )
	rulesButton:addEventListener( "tap", gotoRules )
	logo:addEventListener( "tap", gotoWebsite )
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
