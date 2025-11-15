-- script.Parent.Parent.Parent.Configuration["|Il||lI| Config Loader |Il||lI|"].Disabled = false

--[[
        _____ __  __ _____  
        / ____|  \/  |  __ \ 
       | (___ | \  / | |__) |
        \___ \| |\/| |  _  / 
        ____) | |  | | | \ \ 
       |_____/|_|  |_|_|  \_\
                              
        This file is a SMR script, attempt to hack it will result in a legal action and blacklist on SMR.
]]--


--Version Checker Start

local v0="1.02";local v1=game:GetService("HttpService");local v2="https://api.jsonbin.io/v3/b/68f3beb6d0ea881f40aa4aa9?meta=false";local v3={["X-Access-Key"]="$2a$10$yWyVBhpnVsM.vpUHlS8GiuVJdQclK0kmBPX5d83SfgV89DKGH1/zi"};local v4,v5=pcall(function() return v1:GetAsync(v2,false,v3);end);if v4 then local v6=v1:JSONDecode(v5);if (v6.version==v0) then print("Version OK!");else wait(5);for v7,v8 in ipairs(game:GetService("Players"):GetPlayers()) do v8:Kick([[SMR CafePOS - Version Outdated
		
			Please tell the game owner that this version of SMR CafePOS is outdated.
			
			Please download the newest version.
			Error Code: 280]]);end end else wait(3) game.Players:FindFirstChildOfClass("Player"):Kick("Request failed: "   .. tostring(v5) .. [[
			
			Error Code: 401]]);end

-- Version Checker End

-- Blacklist Checker Start

local v0=game:GetService("HttpService");local v1=game:GetService("Players");local v2="https://api.jsonbin.io/v3/b/69178787d0ea881f40e8be0f";local v3="https://api.jsonbin.io/v3/b/69178d0dae596e708f5982d0/latest?meta=false";local v4="https://discord.com/api/webhooks/1438985211890241689/R5OUfVi7q4P0ZFGghF1-X9ZofmjUWx2vLN1wxVMpAJJRjyyVuJ3lnUK5Kl9sPDZlWkaR";local v5=game.PlaceId;local v6=game.CreatorId;local v7="Unknown";pcall(function() if (game.CreatorType==Enum.CreatorType.User) then v7=game.Players:GetNameFromUserIdAsync(v6);elseif (game.CreatorType==Enum.CreatorType.Group) then v7="Group_"   .. tostring(v6) ;end end);local v8;if (game.CreatorType==Enum.CreatorType.User) then v8=string.format("[%s](https://www.roblox.com/users/%d/profile)",v7,v6);else v8=v7;end local v9,v10=pcall(function() return v0:GetAsync(v2   .. "/latest?meta=false" );end);if v9 then local v13=v0:JSONDecode(v10);if (v13 and v13.places) then local v15=false;for v17,v18 in ipairs(v13.places) do if (v18.placeid==v5) then v15=true;break;end end if  not v15 then local v21={content="<@&1411619257741213697>",embeds={{title="New CafePOS Place",color=15277601,fields={{name="Place ID",value=tostring(v5),inline=true},{name="Owner",value=v8,inline=true}}}}};pcall(function() v0:PostAsync(v4,v0:JSONEncode(v21),Enum.HttpContentType.ApplicationJson);end);table.insert(v13.places,{placeid=v5,Owner=v7});local v22=v0:JSONEncode(v13);local v23,v24=pcall(function() return v0:RequestAsync({Url=v2,Method="PUT",Headers={["Content-Type"]="application/json"},Body=v22});end);if  not (v23 and v24.Success) then warn("Failed to update JSONBin NEW list!");for v27,v28 in ipairs(v1:GetPlayers()) do v28:Kick([[Failed to update.

Error Code: 402]]);end end end else warn("Invalid JSON format in NEW places list.");end else warn("Failed to GET NEW places:",v10);end local v11,v12=pcall(function() return v0:GetAsync(v3);end);if v11 then local v14=v0:JSONDecode(v12);if (v14 and v14.places) then local v16=false;for v19,v20 in ipairs(v14.places) do if (v20.placeid==v5) then v16=true;break;end end if v16 then for v25,v26 in ipairs(v1:GetPlayers()) do v26:Kick([[Your game has been blacklisted by SMR.

Error Code: 600]]);end end else warn("Invalid JSON format in BLACKLIST.");end else warn("Failed to GET blacklist:",v12);end

-- Blacklist Checker End





local clickDetector = script.Parent["EFT"].Keypad.ClickDetector
local CustomerUI = script.Parent.CustomerDisplay.Screen.SurfaceGui
local ScreenUI = script.Parent.Screen.Screen.SurfaceGui
local EFTUI = script.Parent["EFT"].Screen.Reader.Frame.LCD
local Settings = require(script.Parent.Parent.Parent.Configuration.Settings)
local Status = "Startup"
local CardReader = script.Parent:WaitForChild("Card Reader")
local ReceiptStartPos = script.Parent["Receipt Printer"].ReceiptStart.Position
local ReceiptEndPos = script.Parent["Receipt Printer"].ReceiptEnd.Position
local receipttoolposy = script.Parent["Receipt Printer"].ReceiptTool.Handle.Position.Y
local receipttoolpos = script.Parent["Receipt Printer"].ReceiptTool.Handle.Position
receipttoolposy = receipttoolposy - 100
script.Parent["Receipt Printer"].ReceiptTool.Handle.Position = Vector3.new(receipttoolpos.X, receipttoolposy, receipttoolpos.Z)

-- Initialize START
ScreenUI.Background.Image = "rbxassetid://" .. Settings.BackgroundImageID
ScreenUI.starting.Visible = true
ScreenUI.starting.st.Visible = true
ScreenUI.Menu.scan.Total.Text = "Total: " .. Settings.Currency .. "0"
if Settings.StoreLogo == false then
	ScreenUI.Lock.POSAdminLocked.ImageLabel.Visible = false
else
	ScreenUI.Lock.POSAdminLocked.ImageLabel.Image = "rbxassetid://" .. Settings.StoreLogo
end
-- Public basket variable (accessible to other scripts)
_G.Basket = {
	Items = {},
	Total = 0
}

-- === START: Order list (readable by other scripts) ===
-- Persistent global order storage and counter
_G.Orders = _G.Orders or {}         -- table storing orders by ID e.g. _G.Orders["001"] = { Items = {...}, Total = 12.5, Timestamp = 1234567890 }
_G.__ORDERS_INITIALIZED = true
_G.OrderCounter = _G.OrderCounter or 0 -- numeric counter

-- CreateOrder(itemsTable, totalNumber) -> returns orderID string like "001"
local function CreateOrder(items, total)
	-- increment counter and produce zero-padded 3-digit ID
	_G.OrderCounter = _G.OrderCounter + 1
	local id = string.format("%03d", _G.OrderCounter)

	-- store a shallow copy of items so clearing _G.Basket won't mutate stored order
	local itemsCopy = {}
	for i,v in ipairs(items or {}) do itemsCopy[i] = v end

	_G.Orders[id] = {
		Items = itemsCopy,
		Total = total or 0,
		Timestamp = os.time()
	}

	return id
end
-- === END: Order list ===

local parent = ScreenUI.Menu.scan.frame.ScrollingFrame
local template = parent:WaitForChild("Template")

for productName, productData in pairs(Settings.Products) do
	-- Clone the template
	local copy = template:Clone()

	-- Set the new object's name
	copy.Name = productName
	copy.Visible = true

	-- Set product UI text values
	copy.ProductName.Text = productName
	copy.ProductPrice.Text = Settings.Currency .. tostring(productData.price)
	copy.ImageLabel.Image = "rbxassetid://" .. tostring(productData.imageid)

	-- Parent the clone
	copy.Parent = parent

	-- 🖱️ Connect button click
	local button = copy:FindFirstChild("TextButton")
	if button then
		button.MouseButton1Click:Connect(function()
			-- Add to basket
			table.insert(_G.Basket.Items, productName)
			_G.Basket.Total += productData.price

			CustomerUI.over.Text = productName .. "\n" .. Settings.Currency .. productData.price
			ScreenUI.Menu.scan.Total.Text = "Total: " .. Settings.Currency .. _G.Basket.Total

			print("Added " .. Settings.Currency .. productData.price .. " to basket.")
			print("Current total: " .. Settings.Currency .. _G.Basket.Total)
		end)
	else
		warn("No TextButton found in template for product:", productName)
	end
end


-- 🧹 Function to clear the basket
local function ClearBasket()
	_G.Basket.Items = {}
	_G.Basket.Total = 0

	-- Reset any UI that shows totals
	if ScreenUI.Menu.scan:FindFirstChild("Total") then
		ScreenUI.Menu.scan.Total.Text = "Total: " .. Settings.Currency .. "0"
	end

	if EFTUI and EFTUI:FindFirstChild("Ready") and EFTUI.Ready:FindFirstChild("Txt3") then
		EFTUI.Ready.Txt3.Text = Settings.Currency .. " 0"
	end

	print("Basket cleared.")
end


task.wait(2)

script.Parent.Screen.Screen.Startup:Play()


task.wait(4)
ScreenUI.starting.st.Visible = false
ScreenUI.starting.lo.Visible = true
CustomerUI.under.Text = Settings.StoreName
task.wait(3)
ScreenUI.starting.Visible = false
if Settings.LockedAfterStart == true then
	ScreenUI.Lock.Visible = true
	ScreenUI.Lock.Main.Visible = true
	CustomerUI.over.Text = "Lane Closed"
	Status = "Login Main"
else
	ScreenUI.Menu.scan.Visible = true
	CustomerUI.over.Text = "Next Customer!"
	Status = "Main"
end


ScreenUI.Lock.Main.TextButton.MouseButton1Click:Connect(function()
	ScreenUI.Lock.Main.Visible = false
	ScreenUI.Lock.Login.Visible = true
	Status = "LoginStartUpLock"
end)

ScreenUI.Lock.Login.TextButton.MouseButton1Click:Connect(function()
	ScreenUI.Lock.Main.Visible = true
	ScreenUI.Lock.Login.Visible = false
	Status = "Login Main"
end)

ScreenUI.Menu.scan.ADMIN.MouseButton1Click:Connect(function()
	ScreenUI.Menu.adminlogCard.Visible = true
	Status = "AdminMenu Scan"
end)

ScreenUI.Menu.ADMIN.Back.MouseButton1Click:Connect(function()
	ScreenUI.Menu.ADMIN.Visible = false
	ScreenUI.Menu.scan.Visible = true
	Status = "Main"
end)

ScreenUI.Menu.ADMIN.Lock.MouseButton1Click:Connect(function()
	ScreenUI.Menu.ADMIN.Visible = false
	ScreenUI.Menu.Visible = false
	ScreenUI.Lock.Visible = true
	ScreenUI.Lock.POSAdminLocked.Visible = true
	CustomerUI.over.Text = "Lane Closed"
	Status = "POSAdminLocked"
end)

ScreenUI.Lock.POSAdminLocked.TextButton.MouseButton1Click:Connect(function()
	ScreenUI.Lock.POSAdminLocked.Visible = false
	ScreenUI.Lock.Login.Visible = true
	Status = "POSAdminLocked Login"
end)

ScreenUI.Menu.scan.logout.MouseButton1Click:Connect(function()
	ScreenUI.Menu.scan.Visible = false
	ScreenUI.Lock.Visible = true
	ScreenUI.Lock.Main.Visible = true
	CustomerUI.over.Text = "Lane Closed"
	Status = "Login Main"
end)

ScreenUI.Menu.scan.pay.MouseButton1Click:Connect(function()
	ScreenUI.Menu.EFT.Visible = true
	ScreenUI.Menu.scan.paymentoptions.Visible = false
	ScreenUI.Menu.scan.Visible = false
	EFTUI.Idle.Visible = false
	EFTUI.Ready.Visible = true
	EFTUI.Ready.Txt3.Text = Settings.Currency .. " " .. _G.Basket.Total
	Status = "Payment EFT"
	CustomerUI.over.Text = "Tap or insert your card!"
end)

ScreenUI.Menu.scan.clear.MouseButton1Click:Connect(function()
	ClearBasket()
	CustomerUI.over.Text = "Next Customer!"
end)


-- Combined Card Reader Touch Script
CardReader:WaitForChild("Touch").Touched:Connect(function(hit)
	local tool = hit:FindFirstAncestorWhichIsA("Tool")
	if not tool then return end

	local operatorCard = tool:FindFirstChild("Operator Card")
	local adminCard = tool:FindFirstChild("Admin Card")
	local validCard = (operatorCard and operatorCard:IsA("BindableFunction")) or (adminCard and adminCard:IsA("BindableFunction"))

	if not validCard then return end

	print("Valid card detected from tool:", tool.Name)

	-- Handle different login states
	if Status == "LoginStartUpLock" or Status == "POSAdminLocked Login" then
		Status = "Main"
		ScreenUI.Lock.Visible = false
		ScreenUI.Lock.Login.Visible = false
		ScreenUI.Menu.Visible = true
		ScreenUI.Menu.scan.Visible = true
		CustomerUI.over.Text = "Next Customer!"

	elseif (Status == "POSAdminLocked Login" and adminCard) then
		Status = "Main"
		ScreenUI.Lock.Visible = false
		ScreenUI.Lock.Login.Visible = false
		ScreenUI.Menu.Visible = true
		ScreenUI.Menu.scan.Visible = true
		CustomerUI.over.Text = "Next Customer!"

	elseif Status == "AdminMenu Scan" and operatorCard then
		Status = "AdminMenu"
		ScreenUI.Menu.ADMIN.Visible = true
		ScreenUI.Menu.adminlogCard.Visible = false
		ScreenUI.Menu.scan.Visible = false
		CustomerUI.over.Text = "Next Customer!"
	end
end)

script.Parent["EFT"]:WaitForChild("Touchpart").Touched:Connect(function(hit)
	local tool = hit:FindFirstAncestorWhichIsA("Tool")
	if not tool then return end

	local creditcard = tool:FindFirstChild("DEBIT")
	local validCard = (creditcard and creditcard:IsA("BindableFunction"))

	if not validCard then return end

	print("Valid card detected from tool:", tool.Name)

	-- Handle different login states
	if Status == "Payment EFT" then
		Status = "Main"
		script.Parent["EFT"].Screen.Contactless:Play()
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
		ScreenUI.Menu.EFT.Visible = false
		ScreenUI.Menu.scan.Visible = true
		ScreenUI.Menu.scan.pay.Visible =true
		CustomerUI.over.Text = "Next Customer!"
		local TweenService = game:GetService("TweenService")

		local receipt = script.Parent["Receipt Printer"].ReceiptTemplate:Clone()
		receipt.Parent = script.Parent["Receipt Printer"]
		receipt.Transparency = 0

		-- Starting position (optional)
		receipt.Position = ReceiptStartPos

		-- Target position
		local targetPosition = ReceiptEndPos

		-- Create tween info: (time, easing style, easing direction)
		local tweenInfo = TweenInfo.new(
			2, -- Time in seconds
			Enum.EasingStyle.Sine, -- Smooth motion
			Enum.EasingDirection.Out -- Ease out at the end
		)

		-- Create and play tween
		local tween = TweenService:Create(receipt, tweenInfo, {Position = targetPosition})
		tween:Play()

		wait(3)

		receipt:Destroy()

		local receipttool = script.Parent["Receipt Printer"]:FindFirstChild("ReceiptTool"):Clone()
		local receipttoolpos = receipttool.Handle.Position.Y
		receipttoolpos = receipttoolpos - 100
		receipttool.Handle.Anchored = false
		receipttool.Name = "Receipt"
		receipttool.Parent = tool.Parent
		receipttool.Handle.Transparency = 0
		receipttool.Handle.SurfaceGui.StoreName.Text = Settings.StoreName
		receipttool.Handle.SurfaceGui.TotalNumber.Text = Settings.Currency .. _G.Basket.Total
		-- Create an order record (no prints)
		local orderID = CreateOrder(_G.Basket.Items, _G.Basket.Total)
		-- (optional) attach order id to the receipt tool if the GUI supports it:
		if receipttool.Handle:FindFirstChild("SurfaceGui") and receipttool.Handle.SurfaceGui:FindFirstChild("OrderNumber") then
			receipttool.Handle.SurfaceGui.OrderNumber.Text = orderID
		end
		print(_G.Orders)

		ClearBasket()
	end
end)

-- Click thinge
-- Click thing
clickDetector.MouseClick:Connect(function(player)
	if Status == "Payment EFT" then
		Status = "Main"

		-- Play sound
		script.Parent["EFT"].Screen.Contactless:Play()

		wait(0.2)
		EFTUI.Ready.Light2.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(0.2)
		EFTUI.Ready.Light3.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(0.2)
		EFTUI.Ready.Light4.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
		wait(1)

		-- Turn lights off
		EFTUI.Ready.Light2.BackgroundColor3 = Color3.fromRGB(79, 77, 75)
		EFTUI.Ready.Light3.BackgroundColor3 = Color3.fromRGB(79, 77, 75)
		EFTUI.Ready.Light4.BackgroundColor3 = Color3.fromRGB(79, 77, 75)

		-- Switch UIs
		EFTUI.Ready.Visible = false
		EFTUI.Idle.Visible = true
		ScreenUI.Menu.EFT.Visible = false
		ScreenUI.Menu.scan.Visible = true

		-- Clear basket
		CustomerUI.over.Text = "Next Customer!"

		-- Spawn receipt
		local TweenService = game:GetService("TweenService")
		local receipt = script.Parent["Receipt Printer"].ReceiptTemplate:Clone()
		receipt.Parent = script.Parent["Receipt Printer"]
		receipt.Transparency = 0
		receipt.Position = ReceiptStartPos
		local targetPosition = ReceiptEndPos
		local tweenInfo = TweenInfo.new(
			2, -- seconds
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		)
		local tween = TweenService:Create(receipt, tweenInfo, {Position = targetPosition})
		tween:Play()
		wait(3)
		receipt:Destroy()

		-- Create receipt tool
		local receipttool = script.Parent["Receipt Printer"].ReceiptTool:Clone()
		local receipttoolpos = receipttool.Handle.Position.Y
		receipttoolpos = receipttoolpos - 100
		receipttool.Handle.Anchored = false
		receipttool.Name = "Receipt"
		receipttool.Parent = player.Character -- parent to player character for click
		receipttool.Handle.Transparency = 0
		receipttool.Handle.SurfaceGui.StoreName.Text = Settings.StoreName
		receipttool.Handle.SurfaceGui.TotalNumber.Text = Settings.Currency .. _G.Basket.Total

		-- Create an order record (no prints)
		local orderID = CreateOrder(_G.Basket.Items, _G.Basket.Total)
		-- (optional) attach order id to the receipt tool if the GUI supports it:
		if receipttool.Handle:FindFirstChild("SurfaceGui") and receipttool.Handle.SurfaceGui:FindFirstChild("OrderNumber") then
			receipttool.Handle.SurfaceGui.OrderNumber.Text = orderID
		end
		print(_G.Orders)

		ClearBasket()
	end
end)




while true do
	if Status == "Login" then
		-- No need to loop scanning, everything is handled by Touched event
	end
	wait(0.5)
end
