if(chat.IsActive) then return; end
local CHAT_HISTORY 		= "history";
local CHAT_FILTER_BUTTON	= "filters";
local CHAT_INPUT_LINE		= "input_main";
local CHAT_INPUT			= "input";
local CHAT_MAIN			= "main";

local CHAT_MOD = {
	--[[ stores children in CHAT_MOD[value] (by name) ]]--
	children = {
		["HudChatHistory"] 		= CHAT_HISTORY;
		["ChatFiltersButton"] 	= CHAT_FILTER_BUTTON;
		["ChatInputLine"]		= CHAT_INPUT_LINE;
	};
	panels = {};
	
	old = {};
};

hook.Add("StartChat", "TrackChat", function()
	if(not IsValid(CHAT_MOD:Get(CHAT_MAIN))) then
		hook.Add("Think", "TrackChat", function()
			if(not IsValid(vgui.GetKeyboardFocus())) then return; end
			CHAT_MOD:Init(vgui.GetKeyboardFocus():GetParent():GetParent());
			hook.Remove("Think", "TrackChat");
		end);
	end
	CHAT_MOD.open = true;
end);

hook.Add("FinishChat", "TrackChat", function()
	CHAT_MOD.open = false;
end);

local sustain = GetConVar("hud_saytext_time");

function chat.InsertStandardFade()
	chat.GetHistory():InsertFade(sustain:GetFloat(), 2.5);
end

function chat.Append(text)
	chat.GetHistory():AppendText(text);
end

function chat.InsertClickableText(value)
	chat.GetHistory():InsertClickableTextStart(value);
end

function chat.EndClickableText()
	chat.GetHistory():InsertClickableTextEnd();
end

function chat.SetColor(col)
	chat.GetHistory():InsertColorChange(col.r, col.g, col.b, col.a);
end

function chat.IsOpen()
	return CHAT_MOD.open;
end

function chat.IsActive()
	chat.GetInput():IsKeyboardInputEnabled();
end

function chat.IsTyping()
	return vgui.GetKeyboardFocus() == chat.GetInput();
end

function CHAT_MOD:Resize(w,h)
	
	local main = self:Get(CHAT_MAIN);
	local filter = self:Get(CHAT_FILTER_BUTTON);
	local input = self:Get(CHAT_INPUT);
	local input_main = self:Get(CHAT_INPUT_LINE);
	local history = self:Get(CHAT_HISTORY);
	
	local wdif = w - main:GetWide();
	local hdif = h - main:GetTall();
	
	main:SetTall(h);
	main:SetWide(w);
	
	history:SetWide(history:GetWide() + wdif);
	history:SetTall(history:GetTall() + hdif);
	
	input_main:SetWide(input_main:GetWide() + wdif);
	input:SetWide(input:GetWide() + wdif);
	
	local x,y = filter:GetPos();
	filter:SetPos(x + wdif, y);
	
	hook.Call("ChatResized");
end

function chat.Resize(w,h)
	CHAT_MOD:Resize(w,h);
end

--[[ please don't use this! ]]--
function CHAT_MOD:Save(panel)
	local old = self.old;
	local x,y = panel:GetPos();
	old[panel] = old[panel] or {
		x = x;
		y = y;
		w = panel:GetWide();
		h = panel:GetTall();
		font = panel:GetFont();
	};
end

function CHAT_MOD:SetFont(font)
	if(not IsValid(self:Get(CHAT_INPUT))) then 
		return false;
	end
	if(not IsValid(self:Get(CHAT_FILTER_BUTTON))) then
		return false;
	end
	if(not IsValid(self:Get(CHAT_HISTORY))) then
		return false;
	end
	
	self:Get(CHAT_FILTER_BUTTON):SetFontInternal(font);
	self:Get(CHAT_INPUT):SetFontInternal(font);
	self:Get(CHAT_HISTORY):SetFontInternal(font);
	return true;
end

function chat.SetFont(font)
	CHAT_MOD:SetFont(font);
end

function CHAT_MOD:Get(name)
	return self.panels[name];
end

function chat.GetInput()		return CHAT_MOD:Get(CHAT_INPUT); 			end
function chat.GetInputLine() 	return CHAT_MOD:Get(CHAT_INPUT_LINE); 		end
function chat.GetHistory() 		return CHAT_MOD:Get(CHAT_HISTORY); 			end
function chat.GetPanel() 		return CHAT_MOD:Get(CHAT_MAIN); 			end
function chat.GetFilterButton()	return CHAT_MOD:Get(CHAT_FILTER_BUTTON);	end

function CHAT_MOD:ForChildren(pnl, fn)
	if(not pnl:HasChildren()) then return; end
	for k,v in pairs(pnl:GetChildren()) do
		fn(v);
		self:ForChildren(v, fn);
	end
end

function CHAT_MOD:Init(chat)
	self.panels[CHAT_MAIN] = chat;
	
	local searching = self.children;
	
	for i,v in pairs(chat:GetChildren()) do
		local index = searching[v:GetName()];
		if(index) then
			self.panels[index] = v;
		end
	end
	
	local input_main = self:Get(CHAT_INPUT_LINE);
	
	for i,v in pairs(input_main:GetChildren()) do
		if(v:GetName() == "ChatInput") then
			self.panels[CHAT_INPUT] = v;
		end
	end
	
	self:ForChildren(chat, function(v)
		self:Save(v);
	end);
	self:Save(chat);
	
	hook.Run("ChatModInitialize", chat);
end

hook.Add("ShutDown", "ChatMod", function()
	local self = CHAT_MOD;
	for k,v in pairs(self.old) do
		print(tostring(k));
		k:SetPos(v.x, v.y);
		k:SetTall(v.h);
		k:SetWide(v.w);
		k:SetFontInternal(v.font or "");
	end
end);