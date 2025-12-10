--[[
	PremiumUI.lua
	
	Client-side premium store and gamepass UI components.
	Handles:
	- Premium Store screen
	- Gamepass purchase prompts
	- Time Machine death screen
	- God Mode stat editor
	- Mob family selection UI
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local UI = require(ReplicatedStorage:WaitForChild("UIComponents"))
local C = UI.Colors
local F = UI.Fonts

-- ═══════════════════════════════════════════════════════════════════════════════
-- COLOR SAFETY
-- ═══════════════════════════════════════════════════════════════════════════════

C.Gold = C.Gold or Color3.fromRGB(255, 215, 0)
C.GoldDark = C.GoldDark or Color3.fromRGB(218, 165, 32)
C.GoldPale = C.GoldPale or Color3.fromRGB(255, 248, 220)
C.Pink = C.Pink or Color3.fromRGB(236, 72, 153)
C.PinkDark = C.PinkDark or Color3.fromRGB(190, 24, 93)
C.Green = C.Green or Color3.fromRGB(34, 197, 94)
C.GreenDark = C.GreenDark or Color3.fromRGB(22, 163, 74)
C.Red = C.Red or Color3.fromRGB(239, 68, 68)
C.RedDark = C.RedDark or Color3.fromRGB(185, 28, 28)
C.Purple = C.Purple or Color3.fromRGB(139, 92, 246)
C.PurpleDark = C.PurpleDark or Color3.fromRGB(109, 40, 217)
C.Blue = C.Blue or Color3.fromRGB(59, 130, 246)
C.BlueDark = C.BlueDark or Color3.fromRGB(29, 78, 216)
C.Orange = C.Orange or Color3.fromRGB(249, 115, 22)
C.OrangeDark = C.OrangeDark or Color3.fromRGB(194, 65, 12)
C.Amber = C.Amber or Color3.fromRGB(245, 158, 11)
C.AmberDark = C.AmberDark or Color3.fromRGB(217, 119, 6)
C.White = C.White or Color3.fromRGB(255, 255, 255)
C.Black = C.Black or Color3.fromRGB(0, 0, 0)
C.Gray100 = C.Gray100 or Color3.fromRGB(243, 244, 246)
C.Gray200 = C.Gray200 or Color3.fromRGB(229, 231, 235)
C.Gray500 = C.Gray500 or Color3.fromRGB(107, 114, 128)
C.Gray700 = C.Gray700 or Color3.fromRGB(55, 65, 81)
C.Gray900 = C.Gray900 or Color3.fromRGB(17, 24, 39)

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOBILE RESPONSIVE
-- ═══════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_TABLET = IS_MOBILE and (Camera.ViewportSize.X >= 768 or Camera.ViewportSize.Y >= 768)
local IS_SMALL_PHONE = IS_MOBILE and not IS_TABLET and (Camera.ViewportSize.X < 400 or Camera.ViewportSize.Y < 700)
local IS_TINY_PHONE = IS_MOBILE and not IS_TABLET and (Camera.ViewportSize.X <= 380 or Camera.ViewportSize.Y <= 680)
local ViewportSize = Camera.ViewportSize

-- ═══════════════════════════════════════════════════════════════════════════════
-- MODULE
-- ═══════════════════════════════════════════════════════════════════════════════

local PremiumUI = {}
PremiumUI.__index = PremiumUI

-- Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("LifeRemotes") or ReplicatedStorage:WaitForChild("LifeRemotes", 3)
local function getRemote(name)
	return remotesFolder and (remotesFolder:FindFirstChild(name) or remotesFolder:WaitForChild(name, 1))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAMEPASS DEFINITIONS (client copy for display)
-- ═══════════════════════════════════════════════════════════════════════════════

PremiumUI.Gamepasses = {
	{
		key = "BITIZENSHIP",
		name = "Bitizenship",
		emoji = "👑",
		description = "Unlock premium features! Ad-free, special careers, and more.",
		price = 299,
		color = C.Gold,
		colorDark = C.GoldDark,
		features = {
			"Ad-free experience",
			"Access to Royalty careers",
			"Special character customization",
			"Exclusive random events",
			"Start with bonus money",
		},
	},
	{
		key = "GOD_MODE",
		name = "God Mode",
		emoji = "⚡",
		description = "Edit your stats anytime! Become the perfect person.",
		price = 499,
		color = C.Purple,
		colorDark = C.PurpleDark,
		features = {
			"Edit Happiness, Health, Smarts, Looks",
			"Set any stat from 0-100",
			"Change your appearance",
			"Modify relationships",
			"Instant skill boosts",
		},
	},
	{
		key = "TIME_MACHINE",
		name = "Time Machine",
		emoji = "⏰",
		description = "Go back in time when you die! Fix your mistakes.",
		price = 399,
		color = C.Blue,
		colorDark = C.BlueDark,
		features = {
			"Go back 5 years",
			"Go back 10 years",
			"Go back 20 years",
			"Go back 30 years",
			"Restart as baby",
		},
	},
	{
		key = "MAFIA",
		name = "Organized Crime",
		emoji = "🔫",
		description = "Join the criminal underworld. Rise through the Mafia ranks.",
		price = 499,
		color = C.Red,
		colorDark = C.RedDark,
		features = {
			"Join 5 crime families",
			"Rise from Associate to Boss",
			"Run criminal operations",
			"Territory wars",
			"Special mafia events",
		},
	},
	{
		key = "BOSS_MODE",
		name = "Boss Mode",
		emoji = "💼",
		description = "Start your own business empire! Become a tycoon.",
		price = 399,
		color = C.Green,
		colorDark = C.GreenDark,
		features = {
			"Start any business",
			"Hire employees",
			"Expand locations",
			"Go public with IPO",
			"Franchise empire",
		},
	},
	{
		key = "ROYALTY",
		name = "Royalty",
		emoji = "👸",
		description = "Be born into royalty! Live as a prince or princess.",
		price = 299,
		color = C.Pink,
		colorDark = C.PinkDark,
		features = {
			"Born as royalty",
			"Inherit the throne",
			"Royal duties",
			"Massive wealth",
			"Royal scandals",
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI.new(screenGui)
	local self = setmetatable({}, PremiumUI)
	self.screenGui = screenGui
	self.premiumStatus = {}
	return self
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PREMIUM STORE MODAL
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI:createPremiumStore()
	if self.storeOverlay then return end
	
	local modalWidth = IS_TINY_PHONE and 320 or (IS_SMALL_PHONE and 360 or 420)
	local modalHeight = IS_TINY_PHONE and 500 or (IS_SMALL_PHONE and 560 or 620)
	
	-- Overlay
	self.storeOverlay = Instance.new("Frame")
	self.storeOverlay.Name = "PremiumStoreOverlay"
	self.storeOverlay.Size = UDim2.fromScale(1, 1)
	self.storeOverlay.BackgroundColor3 = C.Black
	self.storeOverlay.BackgroundTransparency = 0.4
	self.storeOverlay.Visible = false
	self.storeOverlay.ZIndex = 200
	self.storeOverlay.Parent = self.screenGui
	
	-- Close area
	local closeArea = Instance.new("TextButton")
	closeArea.Size = UDim2.fromScale(1, 1)
	closeArea.BackgroundTransparency = 1
	closeArea.Text = ""
	closeArea.ZIndex = 200
	closeArea.Parent = self.storeOverlay
	closeArea.MouseButton1Click:Connect(function()
		self:hidePremiumStore()
	end)
	
	-- Container
	local container = Instance.new("Frame")
	container.Name = "StoreContainer"
	container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = C.White
	container.ZIndex = 201
	container.Parent = self.storeOverlay
	UI.corner(container, 24)
	self.storeContainer = container
	
	-- Header gradient
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 70)
	header.BackgroundColor3 = C.Gold
	header.ZIndex = 202
	header.Parent = container
	UI.corner(header, 24)
	
	-- Fix bottom corners
	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0, 30)
	headerFix.Position = UDim2.new(0, 0, 1, -30)
	headerFix.BackgroundColor3 = C.Gold
	headerFix.BorderSizePixel = 0
	headerFix.ZIndex = 202
	headerFix.Parent = header
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = F.Title
	titleLabel.TextSize = IS_TINY_PHONE and 20 or 26
	titleLabel.TextColor3 = C.White
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "👑 Premium Store"
	titleLabel.ZIndex = 203
	titleLabel.Parent = header
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -15, 0.5, 0)
	closeBtn.BackgroundColor3 = C.White
	closeBtn.BackgroundTransparency = 0.8
	closeBtn.Font = F.Body
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = C.White
	closeBtn.Text = "✕"
	closeBtn.ZIndex = 203
	closeBtn.Parent = header
	UI.corner(closeBtn, 18)
	closeBtn.MouseButton1Click:Connect(function()
		self:hidePremiumStore()
	end)
	
	-- Scroll frame for gamepasses
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "GamepassList"
	scrollFrame.Size = UDim2.new(1, -20, 1, -90)
	scrollFrame.Position = UDim2.new(0, 10, 0, 80)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = C.Gray400
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 202
	scrollFrame.Parent = container
	self.gamepassList = scrollFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 12)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = scrollFrame
	
	-- Create gamepass cards
	for _, gamepass in ipairs(self.Gamepasses) do
		self:createGamepassCard(gamepass, scrollFrame)
	end
end

function PremiumUI:createGamepassCard(gamepass, parent)
	local cardHeight = IS_TINY_PHONE and 100 or 120
	
	local card = Instance.new("Frame")
	card.Name = "Card_" .. gamepass.key
	card.Size = UDim2.new(1, -10, 0, cardHeight)
	card.BackgroundColor3 = gamepass.color
	card.ZIndex = 203
	card.Parent = parent
	UI.corner(card, 16)
	
	-- Inner card
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -6, 1, -6)
	inner.Position = UDim2.new(0, 3, 0, 3)
	inner.BackgroundColor3 = C.White
	inner.ZIndex = 204
	inner.Parent = card
	UI.corner(inner, 14)
	
	-- Emoji
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(0, 50, 0, 50)
	emoji.Position = UDim2.new(0, 10, 0.5, -25)
	emoji.BackgroundColor3 = gamepass.color
	emoji.BackgroundTransparency = 0.8
	emoji.Font = F.Body
	emoji.TextSize = 28
	emoji.Text = gamepass.emoji
	emoji.ZIndex = 205
	emoji.Parent = inner
	UI.corner(emoji, 12)
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -150, 0, 24)
	nameLabel.Position = UDim2.new(0, 70, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = F.Title
	nameLabel.TextSize = IS_TINY_PHONE and 14 or 16
	nameLabel.TextColor3 = C.Gray900
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = gamepass.name
	nameLabel.ZIndex = 205
	nameLabel.Parent = inner
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -150, 0, 40)
	descLabel.Position = UDim2.new(0, 70, 0, 32)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = F.Body
	descLabel.TextSize = IS_TINY_PHONE and 10 or 12
	descLabel.TextColor3 = C.Gray500
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.Text = gamepass.description
	descLabel.ZIndex = 205
	descLabel.Parent = inner
	
	-- Price button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, IS_TINY_PHONE and 65 or 75, 0, 36)
	buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
	buyBtn.BackgroundColor3 = gamepass.color
	buyBtn.Font = F.Button
	buyBtn.TextSize = IS_TINY_PHONE and 12 or 14
	buyBtn.TextColor3 = C.White
	buyBtn.Text = "R$ " .. gamepass.price
	buyBtn.AutoButtonColor = false
	buyBtn.ZIndex = 205
	buyBtn.Parent = inner
	UI.corner(buyBtn, 10)
	
	-- Check if owned
	if self.premiumStatus[gamepass.key] then
		buyBtn.Text = "✓ Owned"
		buyBtn.BackgroundColor3 = C.Green
	end
	
	buyBtn.MouseButton1Click:Connect(function()
		self:promptPurchase(gamepass.key)
	end)
	
	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		UI.tween(buyBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = gamepass.colorDark
		})
	end)
	buyBtn.MouseLeave:Connect(function()
		local color = self.premiumStatus[gamepass.key] and C.Green or gamepass.color
		UI.tween(buyBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = color
		})
	end)
end

function PremiumUI:showPremiumStore()
	if not self.storeOverlay then
		self:createPremiumStore()
	end
	
	self.storeOverlay.Visible = true
	self.storeOverlay.BackgroundTransparency = 1
	self.storeContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
	
	UI.tween(self.storeOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 })
	UI.tween(self.storeContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
end

function PremiumUI:hidePremiumStore()
	if not self.storeOverlay then return end
	
	UI.tween(self.storeOverlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
	UI.tween(self.storeContainer, TweenInfo.new(0.15), {
		Position = UDim2.new(0.5, 0, 0.5, 30)
	})
	
	task.delay(0.15, function()
		self.storeOverlay.Visible = false
	end)
end

function PremiumUI:promptPurchase(gamepassKey)
	-- Send to server to prompt purchase
	local remote = getRemote("PurchaseGamepass")
	if remote then
		remote:FireServer(gamepassKey)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TIME MACHINE (DEATH SCREEN)
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI:createTimeMachineModal()
	if self.timeMachineOverlay then return end
	
	local modalWidth = IS_TINY_PHONE and 300 or 360
	local modalHeight = IS_TINY_PHONE and 450 or 520
	
	-- Overlay
	self.timeMachineOverlay = Instance.new("Frame")
	self.timeMachineOverlay.Name = "TimeMachineOverlay"
	self.timeMachineOverlay.Size = UDim2.fromScale(1, 1)
	self.timeMachineOverlay.BackgroundColor3 = C.Black
	self.timeMachineOverlay.BackgroundTransparency = 0.3
	self.timeMachineOverlay.Visible = false
	self.timeMachineOverlay.ZIndex = 250
	self.timeMachineOverlay.Parent = self.screenGui
	
	-- Container
	local container = Instance.new("Frame")
	container.Name = "TimeMachineContainer"
	container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = C.Blue
	container.ZIndex = 251
	container.Parent = self.timeMachineOverlay
	UI.corner(container, 24)
	self.timeMachineContainer = container
	
	-- Inner white card
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.new(0, 4, 0, 4)
	inner.BackgroundColor3 = C.White
	inner.ZIndex = 252
	inner.Parent = container
	UI.corner(inner, 22)
	
	-- Clock emoji
	local clockFrame = Instance.new("Frame")
	clockFrame.Size = UDim2.new(0, 80, 0, 80)
	clockFrame.AnchorPoint = Vector2.new(0.5, 0)
	clockFrame.Position = UDim2.new(0.5, 0, 0, 20)
	clockFrame.BackgroundColor3 = C.BluePale or C.Blue:Lerp(C.White, 0.8)
	clockFrame.ZIndex = 253
	clockFrame.Parent = inner
	UI.corner(clockFrame, 40)
	
	local clockEmoji = Instance.new("TextLabel")
	clockEmoji.Size = UDim2.fromScale(1, 1)
	clockEmoji.BackgroundTransparency = 1
	clockEmoji.Font = F.Body
	clockEmoji.TextSize = 44
	clockEmoji.Text = "⏰"
	clockEmoji.ZIndex = 254
	clockEmoji.Parent = clockFrame
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0, 110)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = F.Title
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = C.BlueDark
	titleLabel.Text = "Time Machine"
	titleLabel.ZIndex = 253
	titleLabel.Parent = inner
	
	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, -30, 0, 40)
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
	subtitleLabel.Position = UDim2.new(0.5, 0, 0, 140)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = F.Body
	subtitleLabel.TextSize = 14
	subtitleLabel.TextColor3 = C.Gray500
	subtitleLabel.TextWrapped = true
	subtitleLabel.Text = "Go back in time and change your fate!"
	subtitleLabel.ZIndex = 253
	subtitleLabel.Parent = inner
	self.timeMachineSubtitle = subtitleLabel
	
	-- Options scroll
	local optionsFrame = Instance.new("ScrollingFrame")
	optionsFrame.Name = "OptionsFrame"
	optionsFrame.Size = UDim2.new(1, -30, 0, 220)
	optionsFrame.Position = UDim2.new(0, 15, 0, 185)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.ScrollBarThickness = 3
	optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	optionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	optionsFrame.ZIndex = 253
	optionsFrame.Parent = inner
	self.timeMachineOptions = optionsFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = optionsFrame
	
	-- Close/New Life button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, -30, 0, 44)
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -15)
	closeBtn.BackgroundColor3 = C.Gray200
	closeBtn.Font = F.Button
	closeBtn.TextSize = 15
	closeBtn.TextColor3 = C.Gray700
	closeBtn.Text = "Start New Life"
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 253
	closeBtn.Parent = inner
	UI.corner(closeBtn, 12)
	self.timeMachineCloseBtn = closeBtn
end

function PremiumUI:showTimeMachine(currentAge, hasGamepass, onSelect, onNewLife)
	if not self.timeMachineOverlay then
		self:createTimeMachineModal()
	end
	
	-- Clear old options
	for _, child in ipairs(self.timeMachineOptions:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	self.timeMachineSubtitle.Text = string.format(
		"You died at age %d. Go back and change your fate!",
		currentAge
	)
	
	-- Create time options
	local timeOptions = {
		{ years = 5, label = "5 Years Ago", targetAge = currentAge - 5 },
		{ years = 10, label = "10 Years Ago", targetAge = currentAge - 10 },
		{ years = 20, label = "20 Years Ago", targetAge = currentAge - 20 },
		{ years = 30, label = "30 Years Ago", targetAge = currentAge - 30 },
		{ years = -1, label = "Back to Baby", targetAge = 0 },
	}
	
	for i, opt in ipairs(timeOptions) do
		local available = opt.targetAge >= 0
		local btnColor = available and C.Blue or C.Gray300
		
		local optBtn = Instance.new("TextButton")
		optBtn.Name = "TimeOption_" .. i
		optBtn.Size = UDim2.new(1, 0, 0, 40)
		optBtn.BackgroundColor3 = btnColor
		optBtn.Font = F.Button
		optBtn.TextSize = 14
		optBtn.TextColor3 = C.White
		optBtn.AutoButtonColor = false
		optBtn.ZIndex = 254
		optBtn.LayoutOrder = i
		optBtn.Parent = self.timeMachineOptions
		UI.corner(optBtn, 10)
		
		if available then
			if hasGamepass then
				optBtn.Text = string.format("⏰ %s (Age %d)", opt.label, opt.targetAge)
			else
				optBtn.Text = string.format("🔒 %s (Age %d)", opt.label, opt.targetAge)
				optBtn.BackgroundColor3 = C.Amber
			end
			
			optBtn.MouseButton1Click:Connect(function()
				if hasGamepass then
					if onSelect then onSelect(opt.years) end
				else
					-- Prompt purchase
					self:promptPurchase("TIME_MACHINE")
				end
			end)
		else
			optBtn.Text = "⏰ " .. opt.label .. " (N/A)"
			optBtn.BackgroundColor3 = C.Gray300
		end
	end
	
	-- Close button
	self.timeMachineCloseBtn.MouseButton1Click:Connect(function()
		self:hideTimeMachine()
		if onNewLife then onNewLife() end
	end)
	
	-- Show
	self.timeMachineOverlay.Visible = true
	self.timeMachineOverlay.BackgroundTransparency = 1
	self.timeMachineContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
	
	UI.tween(self.timeMachineOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.3 })
	UI.tween(self.timeMachineContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
end

function PremiumUI:hideTimeMachine()
	if not self.timeMachineOverlay then return end
	
	UI.tween(self.timeMachineOverlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
	UI.tween(self.timeMachineContainer, TweenInfo.new(0.15), {
		Position = UDim2.new(0.5, 0, 0.5, 30)
	})
	
	task.delay(0.15, function()
		self.timeMachineOverlay.Visible = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOB FAMILY SELECTION UI
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI:createMobModal()
	if self.mobOverlay then return end
	
	local modalWidth = IS_TINY_PHONE and 320 or 400
	local modalHeight = IS_TINY_PHONE and 500 or 580
	
	-- Overlay
	self.mobOverlay = Instance.new("Frame")
	self.mobOverlay.Name = "MobOverlay"
	self.mobOverlay.Size = UDim2.fromScale(1, 1)
	self.mobOverlay.BackgroundColor3 = C.Black
	self.mobOverlay.BackgroundTransparency = 0.4
	self.mobOverlay.Visible = false
	self.mobOverlay.ZIndex = 200
	self.mobOverlay.Parent = self.screenGui
	
	-- Close area
	local closeArea = Instance.new("TextButton")
	closeArea.Size = UDim2.fromScale(1, 1)
	closeArea.BackgroundTransparency = 1
	closeArea.Text = ""
	closeArea.ZIndex = 200
	closeArea.Parent = self.mobOverlay
	closeArea.MouseButton1Click:Connect(function()
		self:hideMobModal()
	end)
	
	-- Container
	local container = Instance.new("Frame")
	container.Name = "MobContainer"
	container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = C.Red
	container.ZIndex = 201
	container.Parent = self.mobOverlay
	UI.corner(container, 24)
	self.mobContainer = container
	
	-- Inner white card
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.new(0, 4, 0, 4)
	inner.BackgroundColor3 = C.White
	inner.ZIndex = 202
	inner.Parent = container
	UI.corner(inner, 22)
	
	-- Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(1, -20, 0, 60)
	headerLabel.Position = UDim2.new(0, 10, 0, 10)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = F.Title
	headerLabel.TextSize = IS_TINY_PHONE and 18 or 22
	headerLabel.TextColor3 = C.RedDark
	headerLabel.Text = "🔫 Join the Underworld"
	headerLabel.ZIndex = 203
	headerLabel.Parent = inner
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, -20, 0, 20)
	subtitleLabel.Position = UDim2.new(0, 10, 0, 40)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = F.Body
	subtitleLabel.TextSize = 12
	subtitleLabel.TextColor3 = C.Gray500
	subtitleLabel.Text = "Choose your crime family wisely..."
	subtitleLabel.ZIndex = 203
	subtitleLabel.Parent = inner
	
	-- Family scroll
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "FamilyList"
	scrollFrame.Size = UDim2.new(1, -20, 1, -130)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 203
	scrollFrame.Parent = inner
	self.mobFamilyList = scrollFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = scrollFrame
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, -30, 0, 44)
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -15)
	closeBtn.BackgroundColor3 = C.Gray200
	closeBtn.Font = F.Button
	closeBtn.TextSize = 15
	closeBtn.TextColor3 = C.Gray700
	closeBtn.Text = "Maybe Later"
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 203
	closeBtn.Parent = inner
	UI.corner(closeBtn, 12)
	closeBtn.MouseButton1Click:Connect(function()
		self:hideMobModal()
	end)
end

function PremiumUI:showMobModal(families, hasGamepass, onSelect)
	if not self.mobOverlay then
		self:createMobModal()
	end
	
	-- Clear old families
	for _, child in ipairs(self.mobFamilyList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Create family cards
	for i, family in ipairs(families) do
		local familyColor = Color3.new(family.color[1], family.color[2], family.color[3])
		local familyColorDark = Color3.new(family.colorDark[1], family.colorDark[2], family.colorDark[3])
		
		local card = Instance.new("Frame")
		card.Name = "Family_" .. family.id
		card.Size = UDim2.new(1, 0, 0, IS_TINY_PHONE and 75 or 85)
		card.BackgroundColor3 = familyColor
		card.LayoutOrder = i
		card.ZIndex = 204
		card.Parent = self.mobFamilyList
		UI.corner(card, 14)
		
		-- Inner
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(1, -4, 1, -4)
		inner.Position = UDim2.new(0, 2, 0, 2)
		inner.BackgroundColor3 = C.White
		inner.ZIndex = 205
		inner.Parent = card
		UI.corner(inner, 12)
		
		-- Emoji
		local emoji = Instance.new("TextLabel")
		emoji.Size = UDim2.new(0, 45, 0, 45)
		emoji.Position = UDim2.new(0, 10, 0.5, -22)
		emoji.BackgroundColor3 = familyColor
		emoji.BackgroundTransparency = 0.85
		emoji.Font = F.Body
		emoji.TextSize = 24
		emoji.Text = family.emoji
		emoji.ZIndex = 206
		emoji.Parent = inner
		UI.corner(emoji, 10)
		
		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -130, 0, 22)
		nameLabel.Position = UDim2.new(0, 65, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = F.Title
		nameLabel.TextSize = IS_TINY_PHONE and 13 or 15
		nameLabel.TextColor3 = C.Gray900
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = family.name
		nameLabel.ZIndex = 206
		nameLabel.Parent = inner
		
		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -130, 0, 35)
		descLabel.Position = UDim2.new(0, 65, 0, 32)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = F.Body
		descLabel.TextSize = IS_TINY_PHONE and 9 or 11
		descLabel.TextColor3 = C.Gray500
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.TextWrapped = true
		descLabel.Text = family.description
		descLabel.ZIndex = 206
		descLabel.Parent = inner
		
		-- Join button
		local joinBtn = Instance.new("TextButton")
		joinBtn.Size = UDim2.new(0, 55, 0, 32)
		joinBtn.AnchorPoint = Vector2.new(1, 0.5)
		joinBtn.Position = UDim2.new(1, -10, 0.5, 0)
		joinBtn.BackgroundColor3 = hasGamepass and familyColor or C.Amber
		joinBtn.Font = F.Button
		joinBtn.TextSize = 12
		joinBtn.TextColor3 = C.White
		joinBtn.Text = hasGamepass and "Join" or "🔒"
		joinBtn.AutoButtonColor = false
		joinBtn.ZIndex = 206
		joinBtn.Parent = inner
		UI.corner(joinBtn, 8)
		
		joinBtn.MouseButton1Click:Connect(function()
			if hasGamepass then
				if onSelect then onSelect(family.id) end
				self:hideMobModal()
			else
				self:promptPurchase("MAFIA")
			end
		end)
		
		joinBtn.MouseEnter:Connect(function()
			UI.tween(joinBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = hasGamepass and familyColorDark or C.AmberDark
			})
		end)
		joinBtn.MouseLeave:Connect(function()
			UI.tween(joinBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = hasGamepass and familyColor or C.Amber
			})
		end)
	end
	
	-- Show
	self.mobOverlay.Visible = true
	self.mobOverlay.BackgroundTransparency = 1
	self.mobContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
	
	UI.tween(self.mobOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 })
	UI.tween(self.mobContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
end

function PremiumUI:hideMobModal()
	if not self.mobOverlay then return end
	
	UI.tween(self.mobOverlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
	UI.tween(self.mobContainer, TweenInfo.new(0.15), {
		Position = UDim2.new(0.5, 0, 0.5, 30)
	})
	
	task.delay(0.15, function()
		self.mobOverlay.Visible = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GOD MODE (STAT EDITOR)
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI:createGodModeModal()
	if self.godModeOverlay then return end
	
	local modalWidth = IS_TINY_PHONE and 300 or 360
	local modalHeight = IS_TINY_PHONE and 420 or 480
	
	-- Overlay
	self.godModeOverlay = Instance.new("Frame")
	self.godModeOverlay.Name = "GodModeOverlay"
	self.godModeOverlay.Size = UDim2.fromScale(1, 1)
	self.godModeOverlay.BackgroundColor3 = C.Black
	self.godModeOverlay.BackgroundTransparency = 0.4
	self.godModeOverlay.Visible = false
	self.godModeOverlay.ZIndex = 200
	self.godModeOverlay.Parent = self.screenGui
	
	-- Close area
	local closeArea = Instance.new("TextButton")
	closeArea.Size = UDim2.fromScale(1, 1)
	closeArea.BackgroundTransparency = 1
	closeArea.Text = ""
	closeArea.ZIndex = 200
	closeArea.Parent = self.godModeOverlay
	closeArea.MouseButton1Click:Connect(function()
		self:hideGodMode()
	end)
	
	-- Container
	local container = Instance.new("Frame")
	container.Name = "GodModeContainer"
	container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = C.Purple
	container.ZIndex = 201
	container.Parent = self.godModeOverlay
	UI.corner(container, 24)
	self.godModeContainer = container
	
	-- Inner white card
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.new(0, 4, 0, 4)
	inner.BackgroundColor3 = C.White
	inner.ZIndex = 202
	inner.Parent = container
	UI.corner(inner, 22)
	self.godModeInner = inner
	
	-- Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(1, -20, 0, 40)
	headerLabel.Position = UDim2.new(0, 10, 0, 15)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = F.Title
	headerLabel.TextSize = IS_TINY_PHONE and 18 or 22
	headerLabel.TextColor3 = C.PurpleDark
	headerLabel.Text = "⚡ God Mode"
	headerLabel.ZIndex = 203
	headerLabel.Parent = inner
	
	-- Stats container
	self.godModeStats = {}
	local stats = {
		{ key = "Happiness", emoji = "😊", color = C.Yellow },
		{ key = "Health", emoji = "❤️", color = C.Red },
		{ key = "Smarts", emoji = "🧠", color = C.Blue },
		{ key = "Looks", emoji = "✨", color = C.Pink },
	}
	
	local startY = 65
	local rowHeight = 70
	
	for i, stat in ipairs(stats) do
		local row = Instance.new("Frame")
		row.Name = "StatRow_" .. stat.key
		row.Size = UDim2.new(1, -30, 0, rowHeight - 10)
		row.Position = UDim2.new(0, 15, 0, startY + (i-1) * rowHeight)
		row.BackgroundColor3 = C.Gray100
		row.ZIndex = 203
		row.Parent = inner
		UI.corner(row, 12)
		
		-- Emoji
		local emojiLabel = Instance.new("TextLabel")
		emojiLabel.Size = UDim2.new(0, 40, 0, 40)
		emojiLabel.Position = UDim2.new(0, 8, 0.5, -20)
		emojiLabel.BackgroundTransparency = 1
		emojiLabel.Font = F.Body
		emojiLabel.TextSize = 24
		emojiLabel.Text = stat.emoji
		emojiLabel.ZIndex = 204
		emojiLabel.Parent = row
		
		-- Label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, 80, 0, 20)
		nameLabel.Position = UDim2.new(0, 50, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = F.Medium
		nameLabel.TextSize = 13
		nameLabel.TextColor3 = C.Gray700
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = stat.key
		nameLabel.ZIndex = 204
		nameLabel.Parent = row
		
		-- Value label
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(0, 40, 0, 20)
		valueLabel.AnchorPoint = Vector2.new(1, 0)
		valueLabel.Position = UDim2.new(1, -10, 0, 8)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Font = F.Title
		valueLabel.TextSize = 15
		valueLabel.TextColor3 = stat.color
		valueLabel.Text = "50"
		valueLabel.ZIndex = 204
		valueLabel.Parent = row
		
		-- Slider track
		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(1, -70, 0, 8)
		track.Position = UDim2.new(0, 55, 0, 38)
		track.BackgroundColor3 = C.Gray200
		track.ZIndex = 204
		track.Parent = row
		UI.corner(track, 4)
		
		-- Slider fill
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(0.5, 0, 1, 0)
		fill.BackgroundColor3 = stat.color
		fill.ZIndex = 205
		fill.Parent = track
		UI.corner(fill, 4)
		
		-- Slider handle (draggable)
		local handle = Instance.new("TextButton")
		handle.Name = "Handle"
		handle.Size = UDim2.new(0, 20, 0, 20)
		handle.AnchorPoint = Vector2.new(0.5, 0.5)
		handle.Position = UDim2.new(0.5, 0, 0.5, 0)
		handle.BackgroundColor3 = C.White
		handle.BorderSizePixel = 0
		handle.Text = ""
		handle.ZIndex = 206
		handle.Parent = track
		UI.corner(handle, 10)
		
		local handleStroke = Instance.new("UIStroke")
		handleStroke.Color = stat.color
		handleStroke.Thickness = 2
		handleStroke.Parent = handle
		
		-- Store references
		self.godModeStats[stat.key] = {
			valueLabel = valueLabel,
			fill = fill,
			handle = handle,
			track = track,
			color = stat.color,
			value = 50,
		}
		
		-- Slider interaction
		local dragging = false
		
		handle.MouseButton1Down:Connect(function()
			dragging = true
		end)
		
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				self:updateGodModeStat(stat.key, math.floor(relX * 100))
			end
		end)
		
		game:GetService("UserInputService").InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
			                 input.UserInputType == Enum.UserInputType.Touch) then
				local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				self:updateGodModeStat(stat.key, math.floor(relX * 100))
			end
		end)
		
		game:GetService("UserInputService").InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or
			   input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	
	-- Apply button
	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(1, -30, 0, 44)
	applyBtn.AnchorPoint = Vector2.new(0.5, 1)
	applyBtn.Position = UDim2.new(0.5, 0, 1, -15)
	applyBtn.BackgroundColor3 = C.Purple
	applyBtn.Font = F.Button
	applyBtn.TextSize = 16
	applyBtn.TextColor3 = C.White
	applyBtn.Text = "⚡ Apply Changes"
	applyBtn.AutoButtonColor = false
	applyBtn.ZIndex = 203
	applyBtn.Parent = inner
	UI.corner(applyBtn, 12)
	self.godModeApplyBtn = applyBtn
end

function PremiumUI:updateGodModeStat(statKey, value)
	local statData = self.godModeStats[statKey]
	if not statData then return end
	
	value = math.clamp(value, 0, 100)
	statData.value = value
	statData.valueLabel.Text = tostring(value)
	statData.fill.Size = UDim2.new(value / 100, 0, 1, 0)
	statData.handle.Position = UDim2.new(value / 100, 0, 0.5, 0)
end

function PremiumUI:showGodMode(currentStats, hasGamepass, onApply)
	if not hasGamepass then
		self:promptPurchase("GOD_MODE")
		return
	end
	
	if not self.godModeOverlay then
		self:createGodModeModal()
	end
	
	-- Set current stats
	for statKey, value in pairs(currentStats) do
		if self.godModeStats[statKey] then
			self:updateGodModeStat(statKey, value)
		end
	end
	
	-- Apply button
	self.godModeApplyBtn.MouseButton1Click:Connect(function()
		local newStats = {}
		for key, data in pairs(self.godModeStats) do
			newStats[key] = data.value
		end
		if onApply then onApply(newStats) end
		self:hideGodMode()
	end)
	
	-- Show
	self.godModeOverlay.Visible = true
	self.godModeOverlay.BackgroundTransparency = 1
	self.godModeContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
	
	UI.tween(self.godModeOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 })
	UI.tween(self.godModeContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
end

function PremiumUI:hideGodMode()
	if not self.godModeOverlay then return end
	
	UI.tween(self.godModeOverlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
	UI.tween(self.godModeContainer, TweenInfo.new(0.15), {
		Position = UDim2.new(0.5, 0, 0.5, 30)
	})
	
	task.delay(0.15, function()
		self.godModeOverlay.Visible = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PREMIUM STATUS
-- ═══════════════════════════════════════════════════════════════════════════════

function PremiumUI:updatePremiumStatus(status)
	self.premiumStatus = status or {}
end

return PremiumUI
