-- === START: Order list (readable by other scripts) ===
_G.Orders = _G.Orders or {}
local Orders = _G.Orders
_G.__ORDERS_INITIALIZED = true
_G.OrderCounter = _G.OrderCounter or 0

-- Converts dictionary {Test2 = 2} → list {"Test2","Test2"}
local function ConvertBasketToList(basketDict)
	local list = {}
	for name, count in pairs(basketDict) do
		for i = 1, count do
			table.insert(list, name)
		end
	end
	return list
end

-- Create order in correct list format
local function CreateOrder(itemDict, total)
	_G.OrderCounter = _G.OrderCounter + 1
	local id = string.format("%03d", _G.OrderCounter)

	-- Convert count-dictionary → item list
	local itemsList = ConvertBasketToList(itemDict)

	_G.Orders[id] = {
		Items = itemsList,
		Total = total or 0,
		Timestamp = os.time()
	}

	print(_G.Orders)
	return id
end

-- === END: Order list ===


-- === SHOP SCRIPT ===
local Basket = {
	Items = {},
	Total = 0
}

local Settings = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Configuration.Settings)

local parent = script.Parent
local template = parent:WaitForChild("Template")
local orderUI = script.Parent.Parent.Parent.MyOrder
local orderFrame = orderUI.ScrollingFrame
local orderTemplate = orderFrame.Template
local confirmButton = orderUI.TextButton
local Status = "Normal"
local EFTUI = script.Parent.Parent.Parent.Parent.Parent.EFT.Screen.Reader.Frame.LCD
local ReceiptStartPos = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptStart.Position
local ReceiptEndPos = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptEnd.Position
local receipttoolposy = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptTool.Handle.Position.Y
local receipttoolpos = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptTool.Handle.Position
receipttoolposy = receipttoolposy - 100
script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptTool.Handle.Position = Vector3.new(receipttoolpos.X, receipttoolposy, receipttoolpos.Z)


-- Format total with 2 decimals, avoid -0.00
local function updateTotalUI()
	local t = Basket.Total
	if t <= 0.001 then t = 0 end
	orderUI.Total.Text = Settings.Currency .. string.format("%.2f", t)
end


for productName, productData in pairs(Settings.Products) do
	local copy = template:Clone()
	copy.Name = productName
	copy.Visible = true

	copy.ProductName.Text = productName
	copy.ProductPrice.Text = Settings.Currency .. tostring(productData.price)
	copy.ImageLabel.Image = "rbxassetid://" .. tostring(productData.imageid)

	copy.Parent = parent

	copy.MouseButton1Click:Connect(function()

		Basket.Items[productName] = (Basket.Items[productName] or 0) + 1
		Basket.Total += productData.price
		updateTotalUI()

		local existing = orderFrame:FindFirstChild(productName)

		if existing then
			existing.Count.Text = "x" .. Basket.Items[productName]

		else
			local entry = orderTemplate:Clone()
			entry.Name = productName
			entry.Visible = true

			entry.ProductImage.Image = "rbxassetid://" .. tostring(productData.imageid)
			entry.ProductPrice.Text = Settings.Currency .. tostring(productData.price)
			entry.ProductName.Text = productName
			entry.Count.Text = "x1"

			entry.Parent = orderFrame

			entry["+Button"].MouseButton1Click:Connect(function()
				Basket.Items[productName] += 1
				Basket.Total += productData.price

				entry.Count.Text = "x" .. Basket.Items[productName]
				updateTotalUI()
			end)

			entry["-Button"].MouseButton1Click:Connect(function()
				Basket.Items[productName] -= 1
				Basket.Total -= productData.price

				if Basket.Items[productName] <= 0 then
					Basket.Items[productName] = nil
					entry:Destroy()
				else
					entry.Count.Text = "x" .. Basket.Items[productName]
				end

				updateTotalUI()
			end)
		end
	end)
end


-- === CONFIRM ORDER BUTTON ===
confirmButton.MouseButton1Click:Connect(function()
	Status = "Payment"
	script.Parent.Parent.Parent.MyOrder["EFT Payment"].Visible = true
	script.Parent.Parent.Parent.MyOrder.Frame.Visible = true
	EFTUI.Idle.Visible = false
	EFTUI.Ready.Visible = true
	EFTUI.Ready.Txt3.Text = Settings.Currency .. " " .. Basket.Total
end)

script.Parent.Parent.Parent.ImageButton.MouseButton1Click:Connect(function()
	if Status ~= "Locked" then
		Status = "AdminMenu Scan"
		script.Parent.Parent.Parent.Frame.Visible = true
		script.Parent.Parent.Parent.AdminScan.Visible = true
	else
		Status = "AdminMenu Scan LOCKED"
		script.Parent.Parent.Parent.Frame.Visible = true
		script.Parent.Parent.Parent.AdminScan.Visible = true
	end
end)


script.Parent.Parent.Parent.MyOrder.Back.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.MyOrder.Visible = false
	script.Parent.Parent.Visible = true
end)

script.Parent.Parent.Parent.Parent.Parent["EFT"]:WaitForChild("Touchpart").Touched:Connect(function(hit)
	local tool = hit:FindFirstAncestorWhichIsA("Tool")
	if not tool then return end

	local creditcard = tool:FindFirstChild("DEBIT")
	local validCard = (creditcard and creditcard:IsA("BindableFunction"))

	if not validCard then return end

	print("Valid card detected from tool:", tool.Name)

	-- Handle different login states
	if Status == "Payment" then
		Status = "Normal"
		script.Parent.Parent.Parent.Parent.Parent["EFT"].Screen.Contactless:Play()
		wait(0.2)
		EFTUI.Ready.Light2.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(0.2)
		EFTUI.Ready.Light3.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(0.2)
		EFTUI.Ready.Light4.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(1)
		EFTUI.Ready.Light2.BackgroundColor3 = Color3.fromRGB(79, 77, 75)
		EFTUI.Ready.Light3.BackgroundColor3 = Color3.fromRGB(79, 77, 75)
		EFTUI.Ready.Light4.BackgroundColor3 = Color3.fromRGB(79, 77, 75)
		EFTUI.Ready.Visible = false
		EFTUI.Idle.Visible = true
		local TweenService = game:GetService("TweenService")

		local receipt = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"].ReceiptTemplate:Clone()
		receipt.Parent = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"]
		receipt.Transparency = 0

		-- Starting position (optional)
		receipt.Position = ReceiptStartPos

		-- Target position
		local targetPosition = ReceiptEndPos

		-- Create tween info: (time, easing style, easing direction)
		local tweenInfo = TweenInfo.new(
			5, -- Time in seconds
			Enum.EasingStyle.Sine, -- Smooth motion
			Enum.EasingDirection.Out -- Ease out at the end
		)

		-- Create and play tween
		local tween = TweenService:Create(receipt, tweenInfo, {Position = targetPosition})
		script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"]["Main Body"].Printer:Play()
		tween:Play()

		wait(3)

		receipt:Destroy()

		local receipttool = script.Parent.Parent.Parent.Parent.Parent["Receipt Printer"]:FindFirstChild("ReceiptTool"):Clone()
		local receipttoolpos = receipttool.Handle.Position.Y
		receipttoolpos = receipttoolpos - 100
		receipttool.Handle.Anchored = false
		receipttool.Name = "Receipt"
		receipttool.Parent = tool.Parent
		receipttool.Handle.Transparency = 0
		receipttool.Handle.SurfaceGui.StoreName.Text = Settings.StoreName
		receipttool.Handle.SurfaceGui.TotalNumber.Text = Settings.Currency .. string.format("%.2f", Basket.Total)
		if not next(Basket.Items) then
			warn("Cannot create order: basket is empty.")
			return
		end

		-- Save order IN LIST FORMAT
		local orderID = CreateOrder(Basket.Items, Basket.Total)
		print("Created Order ID:", orderID)

		receipttool.Handle.SurfaceGui.OrderNumber.Text = orderID

		-- Reset basket
		Basket.Items = {}
		Basket.Total = 0

		-- Remove UI entries
		for _, child in pairs(orderFrame:GetChildren()) do
			if child:IsA("Frame") and child ~= orderTemplate then
				child:Destroy()
			end
		end

		updateTotalUI()
		script.Parent.Parent.Parent.MyOrder["EFT Payment"].Visible = false
		script.Parent.Parent.Parent.MyOrder.Frame.Visible = false
		script.Parent.Parent.Parent.MyOrder.Visible = false
		script.Parent.Parent.Parent.Start.Visible = true
	end
end)

local Scanner = script.Parent.Parent.Parent.Parent.Parent.Scanner

-- Combined Card Reader Touch Script
Scanner:WaitForChild("Touch").Touched:Connect(function(hit)
	local tool = hit:FindFirstAncestorWhichIsA("Tool")
	if not tool then return end

	local operatorCard = tool:FindFirstChild("Operator Card")
	local adminCard = tool:FindFirstChild("Admin Card")
	local validCard = (operatorCard and operatorCard:IsA("BindableFunction")) or (adminCard and adminCard:IsA("BindableFunction"))

	if not validCard then return end

	print("Valid card detected from tool:", tool.Name)

	if (Status == "AdminMenu Scan" and adminCard) then
		Status = "AdminMenu"
		script.Parent.Parent.Parent.Admin.Visible = true
		-- Reset basket
		Basket.Items = {}
		Basket.Total = 0

		-- Remove UI entries
		for _, child in pairs(orderFrame:GetChildren()) do
			if child:IsA("Frame") and child ~= orderTemplate then
				child:Destroy()
			end
		end
		updateTotalUI()
		script.Parent.Parent.Parent.AdminScan.Visible = false
		script.Parent.Parent.Parent.Frame.Visible = false
	elseif (Status == "AdminMenu Scan LOCKED" and adminCard) then
		Status = "Locked"
		script.Parent.Parent.Parent.Admin.Visible = true
		-- Reset basket
		Basket.Items = {}
		Basket.Total = 0
		-- Remove UI entries
		for _, child in pairs(orderFrame:GetChildren()) do
			if child:IsA("Frame") and child ~= orderTemplate then
				child:Destroy()
			end
		end
		updateTotalUI()
		script.Parent.Parent.Parent.AdminScan.Visible = false
		script.Parent.Parent.Parent.Frame.Visible = false
	end
end)

script.Parent.Parent.Parent.Admin.Lock.MouseButton1Click:Connect(function()
	if Status ~= "Locked" then
		Status = "Locked"
		script.Parent.Parent.Parent.Admin.Visible = false
		script.Parent.Parent.Parent.Closed.Visible = true
	elseif Status == "Locked" then
		local Status = "Normal"
		script.Parent.Parent.Parent.Admin.Visible = false
		script.Parent.Parent.Parent.Closed.Visible = false
	end
end)

script.Parent.Parent.Parent.Admin.Back.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.Admin.Visible = false
end)

script.Parent.Parent.Parent.AdminScan.TextButton.MouseButton1Click:Connect(function()
	if Status ~= "AdminMenu Scan LOCKED" then
		Status = "Normal"
		script.Parent.Parent.Parent.AdminScan.Visible = false
		script.Parent.Parent.Parent.Frame.Visible = false
	else
		Status = "Locked"
		script.Parent.Parent.Parent.AdminScan.Visible = false
		script.Parent.Parent.Parent.Frame.Visible = false
	end
end)
