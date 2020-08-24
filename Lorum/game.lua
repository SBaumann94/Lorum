
local composer = require( "composer" )
math.randomseed( os.time() )
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

-- Set up constants
local scene = composer.newScene()
local BackgroundWidth = 3300  -- picture width in px
local BackgroundHeight = 2250 -- picture height in px
local CardBack = "cardback"..optionsTable[2]..".png"
local CardWidth = display.contentWidth/7 -25	-- relative px
local CardHeight = display.contentHeight/4		-- relative px
local GameLoopTimer = optionsTable[4]		--400 or 1000miliseconds
local DifIsHard = optionsTable[3] 			--false = Easy, true = Hard

local mainSceneGroup
local Names = {"Harras Rudolf","Reding Itell", "Fürst Walter" ,"Tell Wilmos"}
local StartCardText = {" ", "hetes ", "nyolcas ", "kilences ", "tizes ", "also ", "felso ", "kiraly ", "asz "}

-- Set up display groups

local backGroup = display.newGroup()  -- Display group for the background image
local mainGroup = display.newGroup()  -- Cards and cardstacks
local uiGroup = display.newGroup()  -- Texts, buttons, scores
local leftGroup = display.newGroup()  -- Left-
local rightGroup = display.newGroup()  -- Right-
local topGroup = display.newGroup()  -- Top-
local playerCardsGroup = display.newGroup() -- Players cards

-- Set up local variables

local DeckX
local DeckY
	
local board
local tmr

local pName
local rName
local tName
local lName
local tblText
local Toast

local deckM
local deckZ
local deckT
local deckP

local passButton
local playerIsActive --Defines if the timer can trigger the computers turn

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- local event handlers
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function passing(tbl,pIndex)			--removes 1 point from indexed player, update related text field, adds 1 point to table, deactivates passButton if player passed
	if (pIndex == 1 and Player.CanPlay(tbl.Players[pIndex] )) or ( tbl.isFirstCard) then
		passButton:setFillColor( 0.4,0.4,0.4 )
		return
	end
	
	if (pIndex == 1) and  playerIsActive == false then
		return
	end
	
	tbl.Players[pIndex].points = tbl.Players[pIndex].points - 1
	tbl.points = tbl.points + 1
	--print ("board.points: " .. tbl.points)
	tblTextField.text ="Kezdőlap: ".. StartCardText[tbl.startValue+1] .. tbl.points
	if tbl.Players[pIndex].side == 1 then
		pName.text = tbl.Players[pIndex].name .. "  " .. tbl.Players[pIndex].points
		passButton:setFillColor( 0.4,0.4,0.4 )
		playerIsActive = false
		
		board.Players[pIndex].playedCard = true
		local function listener( event )
			board.Players[pIndex].playedCard = false
			
			if (Player.CanPlay(board.Players[1]) == false) and( pIndex == 1 )then
				passButton:setFillColor( 0,0,0 )
			end
		end			
		timer.performWithDelay( GameLoopTimer * 3, listener )
	elseif tbl.Players[pIndex].side == 2 then
		rName.text = tbl.Players[pIndex].name .. "  " .. tbl.Players[pIndex].points
	elseif tbl.Players[pIndex].side == 3 then
		tName.text = tbl.Players[pIndex].name .. "  " .. tbl.Players[pIndex].points
	elseif tbl.Players[pIndex].side == 4 then
		lName.text = tbl.Players[pIndex].name .. "  " .. tbl.Players[pIndex].points
	end
end

local function passClickListener(tbl,pIndex)--calls passing, needed for player event handling
	return function (event)
		passing(tbl,pIndex)
	end
end

local function cardClickListener(card,index)--handles card tap events, plays the tapped card if possible
	return function (event)
		print(event.name, card.name)
		if board.Players[1].playedCard == false then 
			if Table.AddCard(board,card) then
				if playerIsActive then
					Player.GetCard(board.Players[1],index)
					playerIsActive = false
					
					board.Players[1].playedCard = true
					local function listener( event )
						board.Players[1].playedCard = false
					end			
					timer.performWithDelay( GameLoopTimer * 3, listener )
					
					if(Table.RoundEnded(board)) then
						Table.EndRound(board,board.Players[1])
					else
						--ComputersTurn(2)
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Card class
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Card = { pic, value, name}
		
function Card:Create (v)					--Creates a new Card class object based on given value - 1 = m7, 8 = z7, 32 = pasz
	local crd = {}
	setmetatable(crd, Card)
	crd.value = v			-- 1 = 7, 2 = 8...
	local x = crd.value / 8
	if x <= 1 then
		crd.name = "m"
	elseif x <= 2 then
		crd.name = "z"
	elseif x <= 3 then
		crd.name = "t"
	else
		crd.name = "p"
	end
	
	x = crd.value % 8
	if x == 0 then
		crd.name = crd.name .. "asz"	
	elseif x <= 4 then
		crd.name = crd.name..(x + 6)
	elseif x <= 5 then
		crd.name = crd.name .. "also"
	elseif x <= 6 then
		crd.name = crd.name .. "felso"
	elseif x <= 7 then
		crd.name = crd.name .. "kiraly"
	end
	--print("v: " .. v .." value: " .. crd.value .. " x: " .. x.. " name: " ..crd.name)
	return crd
end
			
function Card.Draw (self, x, y)				--Draws the cards picture at the give x,y point
	if self == nil then
		return
	end
	if self.name ~= "empty"  then	
		self.pic = display.newImageRect( playerCardsGroup, "cards/" .. self.name .. ".png", CardWidth, CardHeight ) 
		self.pic.x = x
		self.pic.y = y
	else
		self.pic = display.newImageRect( playerCardsGroup, "cards/empty.png", CardWidth, CardHeight ) 
		self.pic.x = x
		self.pic.y = y
	end
end

function Card.GetColor(self)				--returns the color of a card: 1 = makk, 2 = zöld, 3 = tök, 4 = piros
	return math.ceil(self.value / 8)	
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player class
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Player = { cards, numOfCards, name, side, points, playedCard}

function Player:Create (sideNum) 			--Creates a new Player class object with orientation:   sideNum 1 = bottom, 2 = right, 3 = top, 4 = left
	local plyr = {}
	setmetatable(plyr, Player)
	plyr.cards = {}
	plyr.numOfCards = 8
	plyr.points = 100
	plyr.side = sideNum or 1
	plyr.name = Names[plyr.side]
	plyr.playedCard = false
    return plyr

end

function Player.Reset(self)					--resets players cards table and numOfCards
	self.cards = {}
	self.numOfCards = 8
end

function Player.GetCard (self, index)		--gives back self.cards[index], also updates computers and players cards view
	local ret
	if(self.numOfCards > 0) and (self.cards[index].name ~= "empty")then
		ret = Card:Create(self.cards[index].value)
		self.cards[index].name = "empty"
		self.numOfCards = self.numOfCards -1
		if self.side ~=1 then
			if self.side == 2 then
				display.remove(rightGroup)
				rightGroup = display.newGroup()  
				mainSceneGroup:insert( rightGroup )  
			elseif self.side == 3 then
				display.remove(topGroup)
				topGroup = display.newGroup()  
				mainSceneGroup:insert( topGroup )  
			elseif self.side == 4 then
				display.remove(leftGroup)
				leftGroup = display.newGroup()  
				mainSceneGroup:insert( leftGroup )  
			end
			Player.DrawCards(self)
		else
			Card.Draw(self.cards[index],self.cards[index].pic.x,self.cards[index].pic.y)
		end
		return ret
	end
	return "nocard"
end

function Player.HasNoCards(self)			--checks if a player has any cards
	for i=1,8,1 do
		if self.cards[i].name == "empty" then
		else
			return false
		end
	end
	return true
end

function Player.CanPlay(self)				--if has cards and at least one of them is playable returns true
	
	if self.numOfCards > 0 then
		local b = false
		for i=1,8,1 do
			if Table.IsPlayable(board,self.cards[i]) then
				b = true
				break
			end
		end
		if b == false then
			return false
		end
		return true
	end
	return false
end

function Player.SortCards (self) 			--sorts player cards, refresh display as well
	
	display.remove(playerCardsGroup)
	playerCardsGroup = display.newGroup()  
	mainSceneGroup:insert( playerCardsGroup )
	
	
	table.sort(self.cards, 
		function (c1, c2) 
			if c1.value < c2.value then
				return true
			else
				return false
			end
		end
	)
end

function CalcSuiteValue(hasOfColor, card, startvalue)	--return how many passes are needed to get rid of all cards (hasOfColor) of "card"s color based on startvalue
	local count = 1
	local ret
	local i = startvalue							--example: startvalue = 8, 7;9;ace in hand --> ret = pass,9,pass,pass,pass,pass,ace,7 = 5
	ret = 0											--		   same hand, but startvalue = ace --> ret = ace, 7, pass 9 = 1
	
	local numofcards = 0
	for i = 1,8,1 do
		if hasOfColor[i] == true then
			numofcards = numofcards + 1
		end
	end
	while(count <= 8 and numofcards > 0) do		
		if hasOfColor[i] == false then
			ret = ret + 1
		else
			numofcards = numofcards -1
		end
		i=i+1
		if( i>8) then
			i = 1
		end
		count = count + 1
	end
	return ret	
end

function Player.FindSameColor(self,cardindex,clr)		--returns an 8 size table which contains true where the player has a card of self.cards[cardindex] color
	local ret = {}
	local color = clr or Card.GetColor(self.cards[cardindex])	-- 1 = makk, 2 = zöld, 3 = tök, 4 = piros
	for i = 1, 8, 1 do
		table.insert(ret,false)
	end
	local index = 0
	for i = 1, 8, 1 do
		if(Card.GetColor(self.cards[i]) == color) then
			index = self.cards[i].value % 8
			if index == 0 then
				index = 8
			end
			ret[index] = true
		end
	end
	return ret
end

function Player.GetBestCardIndex(self)		--computer intelligence, returns the "best" cards index    
	local best = -1
	local bestindex = 0
	local last 
	if DifIsHard then
		--Gets a relatively good estimation about the game's outcome, not unbeatable, but somewhat of a challenge
		if board.startValue <= 0 then	
			print (self.name.. " kezd. Lapjai: ")
			local sv
			for i = 1,8,1 do
				local act = self.cards[i]
				last = 0
				sv = self.cards[i].value % 8
				if sv == 0 then
					sv = 8
				end
				for j = 1,4,1 do
					last = last + CalcSuiteValue(Player.FindSameColor(self,i,j),act,sv)
				end
				
				if(CalcSuiteValue(Player.FindSameColor(self,i),act,sv) == 1) then		-- in case he has only 1 card of a color, it's not a good starting card
					last = last -1
				end
				last = 100 - last
				if last > best then
					best = last
					bestindex = i
				end
				print(act.name.. " kezdőértéke: ".. last)
			end
		else
			print (self.name.. " köre")
			for i = 1,8,1 do
				local act = self.cards[i]
				if(act.name ~= "empty") and Table.IsPlayable(board,act)then
					last = CalcSuiteValue(Player.FindSameColor(self,i),self.cards[i],board.startValue)
					
					-- in case this is the last card he holds of the color, then it is better to keep it if it holds back other player
					if(CalcSuiteValue(Player.FindSameColor(self,i),act,board.startValue) == 1) then
						local tmp = act.value % 8
						if tmp == 0 then
							tmp = 8
						end
						if last >= 2 then
							last = last - 1
						end
					end
					
					
					if last > best then
						best = last
						bestindex = i
					end					
					
					print(act.name .. " kártyát nézem. Értéke: " ..last)
				end
			end
		end
	else
		--returns with the first playable cards index
		if(board.isFirstCard)then
			return 1
		end
				
		if Player.CanPlay(self) then
			for i=1, 8,1 do
				if(Table.IsPlayable(board,self.cards[i])) then
					bestindex = i
					break
				end
			end
		else
			return 0
		end
	end
	for i = 1, 8, 1 do
		print(self.cards[i].name)
	end
	--print("és vissza is tértem, ezzel: ".. self.cards[bestindex].name)
	return bestindex
end

function Player.CheckEndCards(self) 		--returns true if the player has at least 3 ending cards
	local sv = board.startValue
	
	sv = (sv -1) % 8
	
	local counter = 0
	local v
	for i=1, 8, 1 do
		v = self.cards[i].value % 8
		if(v == sv) then
			counter = counter + 1
		end
		
		if counter >= 3 then
			return true
		end
	end
	return false
end

function Player.DrawCards (self)			--Draw a players hand, or a computers handsize based on its numOfCards
	if self.side == 1 then			--bottom side, player cards
		for i=1, 8, 1 do
			Card.Draw(self.cards[i],display.contentCenterX/4*(i-1)+60, display.contentCenterY * 2 -100)
			if self.cards[i] ~= nil then
				if(self.cards[i].name ~= empty) then
					self.cards[i].pic:addEventListener("tap",cardClickListener(self.cards[i],i))
				end
			end
		end
	elseif self.side == 2 then		-- right side
		for i=1	, self.numOfCards, 1 do
			local back = display.newImageRect( rightGroup, CardBack, CardWidth, CardHeight ) 
			back.x = display.contentCenterX*1.8
			back.y = display.contentCenterY/9*(i-1) + 180
		end
	elseif self.side == 3 then		-- top side
		for i=1, self.numOfCards, 1 do
			local back = display.newImageRect( topGroup, CardBack, CardWidth, CardHeight ) 
			back.x = display.contentCenterX/7*(i-1)+180
			back.y = 100
		end
	elseif self.side == 4 then		-- left side
		for i=1	, self.numOfCards, 1 do
			local back = display.newImageRect( leftGroup, CardBack, CardWidth, CardHeight ) 
			back.x =  60
			back.y = display.contentCenterY/9*(i-1) + 180
		end
	end
end
			
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Table class
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Table = {deck, stack, points, startValue, startPlayer, isFirstCard, Players}

function Table:Create()						--Creates a new Table class object
	local tbl = {}
	setmetatable(tbl, Table)
	tbl.points = 0
	tbl.startPlayer = 1		--Player starts the game
	playerIsActive = true		
	tbl.startValue = 0 		--Can be 1-8, First card will set this to right number
	tbl.deck = {}
	tbl.stack = {}		 -- 1 to 8 makk, 9 to 16 zöld, 17 to 24 tök, 25 to 32 piros 
	
	tbl.Players = {}
	for i = 1,4,1 do
		table.insert(tbl.Players,Player:Create(i))
	end
	
	for i=1,32,1 do
		table.insert(tbl.deck,"tmp")
		table.insert(tbl.stack,false)
	end
	-- setting up the deck based on order
	Table.Shuffle(tbl,NewOrder())	
	
	Table.GiveCards(tbl)	-- table deals the shuffled cards	
	Player.SortCards(tbl.Players[1])
	tbl.isFirstCard = true
	
	
	return tbl
end

function Table.Reset(self)					-- resets stacks display as well
	self.points = 0
	if self.startPlayer == 4 then
		self.startPlayer = 1
	else
		self.startPlayer = self.startPlayer + 1
	end
	self.startValue = 0
	for i=1,32,1 do
		self.stack[i]=false
	end

	for i = 1,4,1 do
		Player.Reset(self.Players[i])
	end
	
	self.isFirstCard = true
	Table.Shuffle(self,NewOrder())
	Table.GiveCards(self)
	Player.SortCards(self.Players[1])
	
	for i = 1,4,1 do
		Player.DrawCards(self.Players[i])
	end
	
	pName.text = self.Players[1].name .. "  " .. self.Players[1].points
	rName.text = self.Players[2].name .. "  " .. self.Players[2].points
	tName.text = self.Players[3].name .. "  " .. self.Players[3].points
	lName.text = self.Players[4].name .. "  " .. self.Players[4].points
	tblTextField.text ="Kezdőlap: ".. StartCardText[self.startValue+1] .. self.points
	
	passButton:setFillColor( 0.4,0.4,0.4 )
	
	DeckDisplayInit()
end

function Table.Shuffle (self,order)			--Shuffles the tables deck based on the given order
	
	for i =1, 32,1 do
		
		self.deck[i] = Card:Create(order[i])  
		
	end
end

function Table.GiveCards(self)				--gives out cards from deck to players
	local tmp
	for i=1, 4,1 do
	self.Players[i].cards = {}
		for j=1,8,1 do
			tmp = (i-1) * 8 + j
			table.insert(self.Players[i].cards,self.deck[tmp])
		end
	end
end

function Table.RoundStarted(self,sValue)	--inits the tables first card at the start of the round, sets up the stack table, check for end cards
	local V = sValue % 8		--pasz = 32 -> V = 0
	self.isFirstCard = false
	if V == 0 then
		V = 8					-- V = 8
	end	
	self.startValue = V 				
	if V == 1 then					
		V = V + 7
	else
		V = V - 1
	end
	for i= 0,3,1 do
		self.stack[(i*8) + V] = true
	end
	tblTextField.text ="Kezdőlap: ".. StartCardText[self.startValue+1] .. self.points

	for i = 1,4,1 do 
		if(Player.CheckEndCards(self.Players[i])) then
			
			Toast.text = self.Players[i].name .. " bedobta 3 zárólappal"
			Toast.alpha = 1
			local function listener( event )
				Toast.alpha = 0
			end			
			timer.performWithDelay( 5000, listener )
			
			
			if self.startPlayer == 1 then  --this makes sure the dealer doesn't change if someone folded
				self.startPlayer = 4
			else
				self.startPlayer = self.startPlayer - 1
			end
			
			Table.EndRound(self,self.Players[1])
			
			return false
		end
	end
	return true
	
end

function Table.AddCard(self,card)			-- adds a TRUE to boards stack at the cards position, updates deck image 
	if self.isFirstCard or Table.IsPlayable(self,card) then 
		if self.isFirstCard then
			if(Table.RoundStarted(self,card.value) == false) then
				return false
			end
		end
		self.stack[card.value] = true;
		if card.value <= 8 then	
			Card.Draw(Card:Create(card.value),DeckX[1],DeckY)
		elseif card.value <= 16 then
			Card.Draw(Card:Create(card.value),DeckX[2],DeckY)
		elseif card.value <= 24 then
			Card.Draw(Card:Create(card.value),DeckX[3],DeckY)
		else
			Card.Draw(Card:Create(card.value),DeckX[4],DeckY)
		end
		return true
	else
		return false
	end
end

function Table.IsPlayable(self,card)		-- returns true if the given card is playable
	if card.name == "empty" then
		return false
	end
	local pos = card.value
	if pos % 8 == 1 then
		pos = pos + 7
	else 
		pos = pos -1
	end
	if(self.stack[pos] == true) then
		return true
	end
	return false
end

function Table.RoundEnded(self)				--checks if the current player has no more cards
	local nocards = true
	for i = 1,4,1 do
		nocards = true
		for j=1,8,1 do
			if(self.Players[i].cards[j].name ~= "empty") then
				nocards = false
			end
		end
		if nocards then 
			return true 
		end
	end
	return false
end

function Table.UpdatePoints(self,winner)	--update the players and the tables points at the end of the round
	local w = self.points
	for i = 1,4, 1 do
		w = w + self.Players[i].numOfCards
		self.Players[i].points = self.Players[i].points - self.Players[i].numOfCards
	end
	winner.points = winner.points + w
	self.points = 0
	
	Toast.text = winner.name .. " " .. w .. " pontot nyert"
	Toast.alpha = 1
	local function listener( event )
		Toast.alpha = 0
	end			
	timer.performWithDelay( 5000, listener )
end

function Table.EndRound(self,winner)		--starts new round, summarizes the end turn points 
	if winner.numOfCards == 0 then
		Table.UpdatePoints(self,winner)	
	end
	
	Table.Reset(self)
	if self.startPlayer > 1 then
		playerIsActive = false
		--ComputersTurn(self.startPlayer)
	else
		playerIsActive = true
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- game related functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DeckDisplayInit()					--inits the 4 cardstack displays
	deckM = display.newImageRect( mainGroup, "cards/empty.png",CardWidth,CardHeight)	
	deckM.x = DeckX[1]
	deckM.y = DeckY
	
	deckZ = display.newImageRect( mainGroup, "cards/empty.png",CardWidth,CardHeight)	
	deckZ.x = DeckX[2]
	deckZ.y = DeckY
	
	deckT = display.newImageRect( mainGroup, "cards/empty.png",CardWidth,CardHeight)	
	deckT.x = DeckX[3]
	deckT.y = DeckY
	
	deckP = display.newImageRect( mainGroup, "cards/empty.png",CardWidth,CardHeight)	
	deckP.x = DeckX[4]
	deckP.y = DeckY
	
end

function TextFieldsInit()					--inits player name-, toast-, and round info textfields
    pName = display.newText( uiGroup, board.Players[1].name .. "  " .. board.Players[1].points, 450,  display.contentCenterY * 1.4, native.systemFont, 30 )
	rName = display.newText( uiGroup, board.Players[2].name .. "  " .. board.Players[2].points, 700,  display.contentCenterY * 0.65, native.systemFont, 30 )
	tName = display.newText( uiGroup, board.Players[3].name .. "  " .. board.Players[3].points, 450,  display.contentCenterY * 0.55, native.systemFont, 30 )
	lName = display.newText( uiGroup, board.Players[4].name .. "  " .. board.Players[4].points, 270,  display.contentCenterY * 1.3, native.systemFont, 30 )
	
	tblTextField = display.newText( uiGroup, "Kezdőlap: " .. StartCardText[board.startValue+1] .. board.points, 210,  display.contentCenterY * 0.65, native.systemFont, 18 )
	tblTextField:setFillColor( 0,0,0 )
	
	pName:setFillColor( 0,0,0 )
	rName:setFillColor( 0,0,0 )
	tName:setFillColor( 0,0,0 )
	lName:setFillColor( 0,0,0 )
	
	Toast = display.newText( uiGroup, " ", display.contentCenterX*1.3,  display.contentCenterY*1.3 , native.systemFont, 18 )
	Toast:setFillColor( 0,0,0 )
	Toast.alpha = 0
end

function NewOrder ()						--returns a table with a random order of the number from 1 to 32
	local ret = {}
	local retSize = 1
	local newItem = math.random(1,32)
	table.insert(ret,math.random(1,32))
	
	while retSize < 32 do
		local has = false
		for i=1, retSize, 1 do
			if ret[i] == newItem then
				has = true
				newItem = math.random(1,32)
				break
			end
		end
		if has == false then
			table.insert(ret,newItem)
			newItem = math.random(1,32)
			retSize = retSize + 1
		end
	end
	return ret
end

function ComputersTurn()  					--Computer players turn will start as soon as the player play a valid card or press the Pass button
	if playerIsActive == false then
		
		local t = {i}
		t.i = 2
		if board.isFirstCard then
			t.i = board.startPlayer
		end
		
		function t:timer( event )
			local count = event.count
			
			local index
			local card

			if self.i <= 4 then
				if board.Players[self.i].playedCard == false then
					index = Player.GetBestCardIndex(board.Players[self.i])
					if index == nil then
					elseif index == 0 then
						passing(board,self.i)	--right --> top --> left --> player
						
						local tmp = self.i
						board.Players[tmp].playedCard = true
							local function listener2( event )
								board.Players[tmp].playedCard = false
							end			
						timer.performWithDelay( GameLoopTimer * 3, listener2 )
						
					else
						card = Player.GetCard(board.Players[self.i],index)
						--print(card.name.." at: ".. index.." from: ".. board.Players[i].name)
						Table.AddCard(board,card)
						if(Table.RoundEnded(board)) then
							Table.EndRound(board,board.Players[self.i])
						end
						
						local tmp = self.i
						board.Players[tmp].playedCard = true
							local function listener2( event )
								board.Players[tmp].playedCard = false
							end			
						timer.performWithDelay( GameLoopTimer * 3, listener2 )
						
					end
					self.i = self.i+1
				end
			end
			if count >= 3 then
				timer.cancel( event.source ) -- after 3rd invocation, cancel timer
				
			end
			
		end
		
		playerIsActive = true  -- shuts off the timer
		-- Register to call t's timer method an infinite number of times
		timer.performWithDelay( GameLoopTimer, t, 3 )
		
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create( event )				-- create()

	mainSceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	-- Set up display groups
    backGroup = display.newGroup()  -- Display group for the background image
    mainSceneGroup:insert( backGroup )  -- Insert into the scene's view group
 
    mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
    mainSceneGroup:insert( mainGroup )  -- Insert into the scene's view group
 
    uiGroup = display.newGroup()    -- Display group for UI objects like the score
    mainSceneGroup:insert( uiGroup )    -- Insert into the scene's view group
	
	rightGroup = display.newGroup()  
    mainSceneGroup:insert( rightGroup )  
	topGroup = display.newGroup()  
    mainSceneGroup:insert( topGroup )  
	leftGroup = display.newGroup()  
    mainSceneGroup:insert( leftGroup )  	
	playerCardsGroup = display.newGroup()  
    mainSceneGroup:insert( playerCardsGroup )  
	
	DeckX = {display.contentCenterX- CardWidth*2 -50, display.contentCenterX - CardWidth, display.contentCenterX + CardWidth -50, display.contentCenterX + CardWidth*2 }
	DeckY = display.contentCenterY
	
	-- Set up Background
	local background = display.newImageRect( backGroup, "background"..optionsTable[1]..".jpg",BackgroundWidth,BackgroundHeight )
	drawBackground(background)
	DeckDisplayInit()
	
	--Set up participants
	board = Table:Create() -- creates a new shuffled deck
	
	TextFieldsInit()
	
	for i= 4, 1, -1 do
		Player.DrawCards(board.Players[i])		-- draws out players hand, draws the clickable cards on top of the other fields
	end
	-- Creates UI buttons, but Pass is not yet usable, due to the fact, the player has to start the first round
	
	passButton = display.newText( uiGroup, "Passz", pName.x + 300, display.contentCenterY * 1.4 , native.systemFont, 35 )
    passButton:setFillColor( 0.4,0.4,0.4 )
	passButton:addEventListener("tap",passClickListener(board,1))
	
	local menuButton = display.newText( uiGroup, "Menü", display.contentCenterX*1.8, 50, native.systemFont, 44 )
    menuButton:setFillColor( 0,0,0 )
    menuButton:addEventListener( "tap", gotoMenu )	
end

function scene:show( event )				-- show()

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		tmr = timer.performWithDelay(100,ComputersTurn,0) --checks every 0.1 second if the player is still active
	end
end

function scene:hide( event )				-- hide()

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

		-- Code here runs when the scene is on screen (but is about to go off screen)
	
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		composer.removeScene( "game" )
		timer.cancel(tmr)
	end
end

function scene:destroy( event )				-- destroy()

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

return scene