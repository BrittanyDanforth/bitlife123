local TweenService = game:GetService("TweenService")

local UI = {}

UI.Colors = {
	Blue        = Color3.fromRGB(37, 99, 235),
	BlueDark    = Color3.fromRGB(29, 78, 216),
	BlueLight   = Color3.fromRGB(96, 165, 250),
	BluePale    = Color3.fromRGB(219, 234, 254),

	Green       = Color3.fromRGB(34, 197, 94),
	GreenDark   = Color3.fromRGB(22, 163, 74),
	GreenRing   = Color3.fromRGB(21, 128, 61),
	GreenPale   = Color3.fromRGB(220, 252, 231),

	Red         = Color3.fromRGB(239, 68, 68),
	RedDark     = Color3.fromRGB(220, 38, 38),
	RedPale     = Color3.fromRGB(254, 226, 226),

	Amber       = Color3.fromRGB(245, 158, 11),
	AmberDark   = Color3.fromRGB(217, 119, 6),
	AmberPale   = Color3.fromRGB(253, 230, 138),

	Pink        = Color3.fromRGB(244, 114, 182),
	PinkPale    = Color3.fromRGB(252, 231, 243),

	Purple      = Color3.fromRGB(168, 85, 247),
	PurpleDark  = Color3.fromRGB(126, 34, 206),
	PurplePale  = Color3.fromRGB(237, 233, 254),

	Cyan        = Color3.fromRGB(56, 189, 248),
	CyanPale    = Color3.fromRGB(224, 242, 254),

	Gray50      = Color3.fromRGB(249, 250, 251),
	Gray100     = Color3.fromRGB(243, 244, 246),
	Gray200     = Color3.fromRGB(229, 231, 235),
	Gray300     = Color3.fromRGB(209, 213, 219),
	Gray400     = Color3.fromRGB(156, 163, 175),
	Gray500     = Color3.fromRGB(107, 114, 128),
	Gray600     = Color3.fromRGB(75, 85, 99),
	Gray700     = Color3.fromRGB(55, 65, 81),
	Gray800     = Color3.fromRGB(31, 41, 55),
	Gray900     = Color3.fromRGB(17, 24, 39),

	White       = Color3.fromRGB(255, 255, 255),
	OffWhite    = Color3.fromRGB(250, 250, 250),
	Black       = Color3.fromRGB(0, 0, 0),

	Gold        = Color3.fromRGB(251, 191, 36),
	GoldDark    = Color3.fromRGB(217, 119, 6),
	Teal        = Color3.fromRGB(16, 185, 129),
	TealDark    = Color3.fromRGB(13, 148, 136),
	TealPale    = Color3.fromRGB(204, 251, 241),

	Bg          = Color3.fromRGB(245, 246, 250),
}

UI.Fonts = {
	Title  = Enum.Font.GothamBold,
	Body   = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Button = Enum.Font.GothamBold,
}

-- Basic helpers --------------------------------------------------------------
local function createInstance(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

function UI.tween(object, info, props)
	local tween = TweenService:Create(object, info, props)
	tween:Play()
	return tween
end

function UI.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

function UI.pill(parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = parent
	return c
end

function UI.stroke(parent, thickness, transparency, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Color = color or UI.Colors.White
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UI.pad(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, left or 0)
	padding.PaddingRight  = UDim.new(0, right or 0)
	padding.PaddingTop    = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.Parent = parent
	return padding
end

function UI.createShadow(parent, offset, blur, color, transparency)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = (parent.Name or "Object") .. "Shadow"
	shadow.Image = "rbxassetid://148970562"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(20, 20, 236, 236)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Size = UDim2.new(1, (blur or 16) * 2, 1, (blur or 16) * 2)
	shadow.Position = UDim2.new(0.5, (offset or 0), 0.5, (offset or 4))
	shadow.BackgroundTransparency = 1
	shadow.ImageTransparency = transparency or 0.85
	shadow.ImageColor3 = color or UI.Colors.Black
	shadow.ZIndex = (parent.ZIndex or 1) - 1
	shadow.Parent = parent
	return shadow
end

function UI.gradient(parent, fromColor, toColor, rotation)
	local gradient = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, fromColor or UI.Colors.White),
		ColorSequenceKeypoint.new(1, toColor or UI.Colors.White)
	})
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	return gradient
end

function UI.formatMoney(amount)
	amount = amount or 0
	if amount >= 1_000_000 then
		return string.format("$%.1fM", amount / 1_000_000)
	elseif amount >= 1_000 then
		return string.format("$%.1fK", amount / 1_000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

-- Info bar / chips ----------------------------------------------------------
function UI.createInfoBar(parent, opts)
	opts = opts or {}
	local bar = Instance.new("Frame")
	bar.Name = opts.name or "InfoBar"
	bar.Size = UDim2.new(1, -16, 0, opts.height or 52)
	bar.Position = UDim2.new(0, 8, 0, opts.topOffset or 110)
	bar.BackgroundColor3 = opts.backgroundColor or UI.Colors.White
	bar.ZIndex = opts.zIndex or 80
	bar.Parent = parent
	UI.corner(bar, opts.cornerRadius or 14)
	UI.stroke(bar, 1, 0.9, UI.Colors.Gray200)
	UI.pad(bar, 10, 10, 6, 6)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = bar

	return bar
end

function UI.createInfoChip(parent, opts)
	opts = opts or {}
	local chip = Instance.new("Frame")
	chip.Name = opts.name or "InfoChip"
	chip.Size = UDim2.new(0, opts.width or 90, 1, 0)
	chip.BackgroundColor3 = opts.bgColor or UI.Colors.Gray100
	chip.ZIndex = (parent.ZIndex or 0) + 1
	chip.Parent = parent
	UI.corner(chip, 12)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 22, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Font = UI.Fonts.Body
	icon.TextSize = 16
	icon.TextColor3 = opts.iconColor or UI.Colors.Gray600
	icon.Text = opts.icon or ""
	icon.ZIndex = chip.ZIndex + 1
	icon.Parent = chip

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -28, 1, 0)
	text.Position = UDim2.new(0, 26, 0, 0)
	text.BackgroundTransparency = 1
	text.Font = UI.Fonts.Medium
	text.TextSize = 14
	text.TextColor3 = opts.textColor or UI.Colors.Gray800
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = opts.text or ""
	text.ZIndex = chip.ZIndex + 1
	text.Parent = chip

	return {
		chip = chip,
		icon = icon,
		text = text,
	}
end

-- Scroll / section helpers --------------------------------------------------
function UI.createScrollArea(parent, opts)
	opts = opts or {}
	local topOffset = opts.topOffset or 240
	local bottomOffset = opts.bottomOffset or 16

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = opts.name or "ContentScroll"
	scroll.Size = UDim2.new(1, -16, 1, -(topOffset + bottomOffset))
	scroll.Position = UDim2.new(0, 8, 0, topOffset)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = opts.scrollThickness or 4
	scroll.ScrollBarImageColor3 = opts.scrollColor or UI.Colors.Gray300
	scroll.ZIndex = opts.zIndex or 80
	scroll.Parent = parent
	return scroll
end

function UI.createSectionCard(parent, opts)
	opts = opts or {}
	local colors = UI.Colors
	local frame = Instance.new("Frame")
	frame.Name = opts.name or "Section"
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = opts.backgroundColor or colors.White
	frame.ZIndex = opts.zIndex or 80
	frame.LayoutOrder = opts.order or 1
	frame.Parent = parent
	UI.corner(frame, opts.cornerRadius or 18)
	UI.stroke(frame, 1, 0.88, colors.Gray200)
	UI.pad(frame, 14, 14, 14, 16)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	if opts.title then
		local header = Instance.new("Frame")
		header.Name = "Header"
		header.Size = UDim2.new(1, 0, 0, 36)
		header.BackgroundTransparency = 1
		header.LayoutOrder = 0
		header.ZIndex = (opts.zIndex or 80) + 1
		header.Parent = frame

		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(0, opts.badgeWidth or 120, 0, 32)
		badge.BackgroundColor3 = opts.accentColor or colors.Blue
		badge.ZIndex = header.ZIndex + 1
		badge.Parent = header
		UI.pill(badge)

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.fromScale(1, 1)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = UI.Fonts.Button
		badgeLabel.TextSize = 14
		badgeLabel.TextColor3 = colors.White
		badgeLabel.Text = opts.title
		badgeLabel.ZIndex = badge.ZIndex + 1
		badgeLabel.Parent = badge

		if opts.subtitle then
			local subtitle = Instance.new("TextLabel")
			subtitle.Size = UDim2.new(0, opts.subtitleWidth or 200, 1, 0)
			subtitle.Position = UDim2.new(0, (opts.badgeWidth or 120) + 10, 0, 0)
			subtitle.BackgroundTransparency = 1
			subtitle.Font = UI.Fonts.Medium
			subtitle.TextSize = 13
			subtitle.TextColor3 = colors.Gray500
			subtitle.TextXAlignment = Enum.TextXAlignment.Left
			subtitle.Text = opts.subtitle
			subtitle.ZIndex = header.ZIndex + 1
			subtitle.Parent = header
		end
	end

	return frame
end

-- Tab helpers ---------------------------------------------------------------
function UI.createTabBar(parent, opts)
	opts = opts or {}
	local bar = Instance.new("Frame")
	bar.Name = opts.name or "TabBar"
	bar.Size = UDim2.new(1, -16, 0, opts.height or 52)
	bar.Position = UDim2.new(0, 8, 0, opts.topOffset or 200)
	bar.BackgroundColor3 = opts.backgroundColor or UI.Colors.Gray100
	bar.ZIndex = opts.zIndex or 80
	bar.Parent = parent
	UI.corner(bar, 14)
	UI.pad(bar, 6, 6, 6, 6)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = bar

	return bar
end

function UI.createTabButton(parent, opts)
	opts = opts or {}
	local colors = UI.Colors
	local selected = opts.selected
	local button = Instance.new("TextButton")
	button.Name = opts.id or (opts.text or "Tab")
	button.Size = UDim2.new(opts.width or 0.25, 0, 1, 0)
	button.BackgroundColor3 = selected and (opts.color or colors.Blue) or colors.White
	button.AutoButtonColor = false
	button.Font = UI.Fonts.Button
	button.TextSize = 14
	button.TextColor3 = selected and colors.White or colors.Gray600
	button.Text = (opts.icon or "") .. (opts.icon and " " or "") .. (opts.text or "Tab")
	button.ZIndex = opts.zIndex or (parent.ZIndex or 0) + 1
	button.Parent = parent
	UI.corner(button, 10)

	return button
end

-- Screen headers / modals ---------------------------------------------------
function UI.createScreenHeader(parent, opts)
	opts = opts or {}
	local colors = UI.Colors
	local header = Instance.new("Frame")
	header.Name = opts.name or "Header"
	header.Size = UDim2.new(1, -16, 0, 80)
	header.Position = UDim2.new(0, 8, 0, opts.topOffset or 44)
	header.BackgroundColor3 = colors.White
	header.ZIndex = opts.zIndex or 80
	header.Parent = parent
	UI.corner(header, 18)
	UI.createShadow(header, 4, 14, colors.Black, 0.94)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0, 30)
	title.Position = UDim2.new(0, 24, 0, 18)
	title.BackgroundTransparency = 1
	title.Font = UI.Fonts.Title
	title.TextSize = 20
	title.TextColor3 = colors.Gray900
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = opts.title or "Screen"
	title.ZIndex = header.ZIndex + 1
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.6, 0, 0, 20)
	subtitle.Position = UDim2.new(0, 24, 0, 48)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = UI.Fonts.Body
	subtitle.TextSize = 14
	subtitle.TextColor3 = colors.Gray500
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = opts.subtitle or ""
	subtitle.ZIndex = header.ZIndex + 1
	subtitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 44, 0, 44)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
	closeBtn.BackgroundColor3 = colors.Gray100
	closeBtn.Text = "✕"
	closeBtn.Font = UI.Fonts.Button
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = colors.Gray600
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = header.ZIndex + 1
	closeBtn.Parent = header
	UI.corner(closeBtn, 14)

	return {
		frame = header,
		title = title,
		subtitle = subtitle,
		closeButton = closeBtn,
	}
end

-- Modal + transitions -------------------------------------------------------
function UI.createModalCard(parent, opts)
	opts = opts or {}
	local colors = UI.Colors
	local overlay = Instance.new("Frame")
	overlay.Name = (opts.name or "Modal") .. "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = colors.Black
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.ZIndex = opts.zIndex or 95
	overlay.Parent = parent

	local card = Instance.new("Frame")
	card.Name = (opts.name or "Modal") .. "Card"
	card.Size = UDim2.new(0, 320, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = colors.White
	card.ZIndex = overlay.ZIndex + 1
	card.Parent = overlay
	UI.corner(card, 22)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = card

	local emojiFrame = Instance.new("Frame")
	emojiFrame.Size = UDim2.new(0, 70, 0, 70)
	emojiFrame.BackgroundColor3 = opts.accentPale or colors.GreenPale
	emojiFrame.ZIndex = card.ZIndex + 1
	emojiFrame.Parent = card
	UI.corner(emojiFrame, 18)

	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Size = UDim2.fromScale(1, 1)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Font = UI.Fonts.Body
	emojiLabel.TextSize = 38
	emojiLabel.TextColor3 = opts.accentDark or colors.GreenDark
	emojiLabel.Text = opts.emoji or "✨"
	emojiLabel.ZIndex = emojiFrame.ZIndex + 1
	emojiLabel.Parent = emojiFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 32)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UI.Fonts.Title
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = colors.Gray900
	titleLabel.Text = opts.title or "Result"
	titleLabel.ZIndex = card.ZIndex + 1
	titleLabel.Parent = card

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -50, 0, 0)
	messageLabel.AutomaticSize = Enum.AutomaticSize.Y
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = UI.Fonts.Body
	messageLabel.TextSize = 15
	messageLabel.TextColor3 = colors.Gray600
	messageLabel.TextWrapped = true
	messageLabel.Text = opts.message or ""
	messageLabel.ZIndex = card.ZIndex + 1
	messageLabel.Parent = card

	local okButton = Instance.new("TextButton")
	okButton.Size = UDim2.new(1, -40, 0, 46)
	okButton.BackgroundColor3 = opts.accentColor or colors.Green
	okButton.Font = UI.Fonts.Button
	okButton.TextSize = 16
	okButton.TextColor3 = colors.White
	okButton.Text = "OK"
	okButton.AutoButtonColor = false
	okButton.ZIndex = card.ZIndex + 1
	okButton.Parent = card
	UI.corner(okButton, 14)

	local closeArea = Instance.new("TextButton")
	closeArea.BackgroundTransparency = 1
	closeArea.Size = UDim2.fromScale(1, 1)
	closeArea.Text = ""
	closeArea.ZIndex = overlay.ZIndex
	closeArea.Parent = overlay

	return {
		overlay = overlay,
		card = card,
		emojiFrame = emojiFrame,
		emojiLabel = emojiLabel,
		titleLabel = titleLabel,
		messageLabel = messageLabel,
		okButton = okButton,
		closeArea = closeArea,
		shell = okButton,
		shellStroke = UI.stroke(card, 2, 0.4, opts.accentDark or colors.GreenDark)
	}
end

function UI.showModal(modal)
	modal.overlay.Visible = true
	modal.card.Position = UDim2.new(0.5, 0, 0.5, 40)
	modal.card.BackgroundTransparency = 1
	UI.tween(modal.card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0,
	})
end

function UI.hideModal(modal, callback)
	UI.tween(modal.card, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, 0, 0.5, 40),
		BackgroundTransparency = 1,
	}).Completed:Connect(function()
		modal.overlay.Visible = false
		if callback then callback() end
	end)
end

function UI.slideInScreen(frame, direction)
	direction = direction or "right"
	frame.Visible = true
	local start
	if direction == "right" then
		start = UDim2.new(1, 0, 0, 0)
	elseif direction == "left" then
		start = UDim2.new(-1, 0, 0, 0)
	else
		start = UDim2.new(0, 0, 1, 0)
	end
	frame.Position = start
	UI.tween(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
end

function UI.slideOutScreen(frame, direction, callback)
	direction = direction or "right"
	local finish
	if direction == "right" then
		finish = UDim2.new(1, 0, 0, 0)
	elseif direction == "left" then
		finish = UDim2.new(-1, 0, 0, 0)
	else
		finish = UDim2.new(0, 0, 1, 0)
	end
	UI.tween(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = finish,
	}).Completed:Connect(function()
		frame.Visible = false
		if callback then callback() end
	end)
end

return UI
