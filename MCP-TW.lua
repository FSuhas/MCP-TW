-- 
-- MCP - Master Control Program
--
-- Allows you to control AddOn loading after logging in.
-- 
--  Marc aka Saien on Hyjal
--  WOWSaien@gmail.com
--  http://64.168.251.69/wow
--
-- Changes
--   2006.10.01
--	Update by Fin of Stormrage-EU // fin@instinct.org // http://fin.instinct.org/
--	Made the addon list "pushable"
--	Added colours to tooltip
--	Wrapped tooltip text
--	Added key binding to show MCP
--	Fixed typo in localization.lua preventing deletion of profiles
--   2006.09.09
--     2.2-BD release
--     Made sure MCP doesn't turn itself off when checking disable all addons
--   2006.09.06
--     2.1-BD release
--     Added localization 
--     Added enable/disable all buttons
--     Added tooltip when you mouse over an addon to show the notes
--   2006.09.02
--     2.0-BD release
--     modifications by Bluedragon, alliance Frostwolf server
--     Added slash command /mcp to open the window
--     Added profiles for quickly changing which addons are enabled/disabled
--   2006.01.02
--     1.9 release
--     In game changes to the addon list are limited to changing the currently 
--       logged in character only. You cannot change Addons for other characters. 
--       This is a Blizzard restriction.
--   2005.10.10
--     1.8 release

MCP_SelectedProfile = "NONE";


-- Binding Variables
BINDING_HEADER_MCP = "Master Control Panel (MCP)";
BINDING_NAME_SHOWMCP = "MCP list";
BINDING_NAME_DOOTHERSTUFF = "another name";
BINDING_NAME_DOMORESTUFF = "yet another name";

UIPanelWindows["MCP_AddonList"] = { area = "center", pushable = 1, whileDead = 1 };

StaticPopupDialogs["MCP_RELOADUI"] = {
	text = MCP_RELOAD,
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	OnAccept = function()
		ReloadUI();
	end,
	timeout = 0,
	hideOnEscape = 1
};

function MCP_DeleteDialog()
  StaticPopupDialogs["MCP_DELETEPROFILE"] = {
	text = MCP_DELETE_PROFILE_DIALOG..MCP_SelectedProfile,
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	OnAccept = function()
		MCP_DeleteProfile(MCP_SelectedProfile);
                MCP_SelectedProfile = "NONE";
                UIDropDownMenu_SetText(MCP_SelectedProfile, MCP_AddonList_ProfileSelection);
        end,
	timeout = 0,
	hideOnEscape = 1
  };
  StaticPopup_Show("MCP_DELETEPROFILE");
end

function MCP_SaveDialog()
  StaticPopupDialogs["MCP_SAVEPROFILE"] = {
        text = MCP_PROFILE_NAME_SAVE,
        button1 = TEXT(ACCEPT),
        button2 = TEXT(CANCEL),
        hasEditBox = 1,
        maxLetters = 32,
        hideOnEscape = 1,
        OnLoad = function()
                getglobal(this:GetParent():GetName().."EditBox"):SetText(MCP_SelectedProfile);
        end,
        OnAccept = function()
                MCP_SaveProfile(getglobal(this:GetParent():GetName().."EditBox"):GetText());
        end,
        timeout = 0,
        EditBoxOnEnterPressed = function()
                MCP_SaveProfile(getglobal(this:GetParent():GetName().."EditBox"):GetText());
                this:GetParent():Hide();
        end
  };
  StaticPopup_Show("MCP_SAVEPROFILE");
end


MCP_VERSION = "2006.10.01-fin";
MCP_LINEHEIGHT = 16;
local MCP_MAXADDONS = 20;
local MCP_BLIZZARD_ADDONS = { 
	"Blizzard_AuctionUI",
	"Blizzard_BattlefieldMinimap",
	"Blizzard_BindingUI",
	"Blizzard_CraftUI",
	"Blizzard_InspectUI",
	"Blizzard_MacroUI",
	"Blizzard_RaidUI",
	"Blizzard_TalentUI",
	"Blizzard_TradeSkillUI",
	"Blizzard_TrainerUI",
};
local MCP_BLIZZARD_ADDONS_TITLES = { 
	"Blizzard: Auction",
	"Blizzard: Battlefield Minimap",
	"Blizzard: Binding",
	"Blizzard: Craft",
	"Blizzard: Inspect",
	"Blizzard: Macro",
	"Blizzard: Raid",
	"Blizzard: Talent",
	"Blizzard: Trade Skill",
	"Blizzard: Trainer",
};
local MCP_old_LoadAddOn = nil;


local function MCP_new_LoadAddOn(name)
	if (not IsAddOnLoaded(name) and MCP_Config and MCP_Config.refusetoload and MCP_Config.refusetoload[name]) then
		return nil, "REFUSE_TO_LOAD";
	else
		return MCP_old_LoadAddOn(name);
	end
end

function MCP_OnLoad()
	MCP_old_LoadAddOn = LoadAddOn;
	LoadAddOn = MCP_new_LoadAddOn;

        -- setup /mcp slash command
        SlashCmdList["MCPSLASHCMD"] = MCP_SlashHandler;
        SLASH_MCPSLASHCMD1 = "/mcp";
end

function MCP_SlashHandler(msg)
        ShowUIPanel(MCP_AddonList);
end

function MCP_AddonList_Enable(index,enabled)
	if (type(index) == "number") then
		if (enabled) then
			EnableAddOn(index)
		else
			DisableAddOn(index)
		end
	else
		if (enabled) then
			if (MCP_Config and MCP_Config.refusetoload) then
				MCP_Config.refusetoload[index] = nil;
			end
		else
			if (not MCP_Config) then MCP_Config = {}; end
			if (not MCP_Config.refusetoload) then MCP_Config.refusetoload = {}; end
			MCP_Config.refusetoload[index] = true;
		end
	end
	MCP_AddonList_OnShow();
end

function MCP_AddonList_LoadNow(index)
	UIParentLoadAddOn(index);
	MCP_AddonList_OnShow();
end

function MCP_AddonList_OnShow()
	local function setSecurity (obj, idx)
		local width,height,iconWidth = 64,16,16;
		local increment = iconWidth/width;
		local left = (idx-1)*increment;
		local right = idx*increment;
		obj:SetTexCoord(left, right, 0, 1);
	end

	local numAddons = GetNumAddOns();
	local origNumAddons = numAddons;
	numAddons = numAddons + table.getn(MCP_BLIZZARD_ADDONS);
	FauxScrollFrame_Update(MCP_AddonList_ScrollFrame, numAddons, MCP_MAXADDONS, MCP_LINEHEIGHT, nil, nil, nil);
	local i;
	local offset = FauxScrollFrame_GetOffset(MCP_AddonList_ScrollFrame);
	for i = 1, MCP_MAXADDONS, 1 do
		obj = getglobal("MCP_AddonListEntry"..i);
		local addonIdx = offset+i;
		if (addonIdx > numAddons) then
			obj:Hide();
			obj.addon = nil;
		else
			obj:Show();
			local titleText = getglobal("MCP_AddonListEntry"..i.."Title");
			local status = getglobal("MCP_AddonListEntry"..i.."Status");
			local checkbox = getglobal("MCP_AddonListEntry"..i.."Enabled");
			local securityIcon = getglobal("MCP_AddonListEntry"..i.."SecurityIcon");
			local loadnow = getglobal("MCP_AddonListEntry"..i.."LoadNow");

			local name, title, notes, enabled, loadable, reason, security;
			if (addonIdx > origNumAddons) then
				name = MCP_BLIZZARD_ADDONS[(addonIdx-origNumAddons)];
				obj.addon = name;
				title = MCP_BLIZZARD_ADDONS_TITLES[(addonIdx-origNumAddons)];
				notes = "";
				if (MCP_Config and MCP_Config.refusetoload and MCP_Config.refusetoload[name]) then
					enabled = nil;
					loadable = nil;
					reason = "WILL_NOT_LOAD";
				else
					enabled = 1;
					loadable = 1;
				end
				if (IsAddOnLoaded(name)) then
					reason = "LOADED";
					loadable = 1;
				end
				security = "SECURE";
			else
				name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(addonIdx);
				obj.addon = addonIdx;
			end
			local loaded = IsAddOnLoaded(name);
			local ondemand = IsAddOnLoadOnDemand(name);
			if (loadable) then
				titleText:SetTextColor(1,0.78,0);
			elseif (enabled and reason ~= "DEP_DISABLED") then
				titleText:SetTextColor(1,0.1,0.1);
			else
				titleText:SetTextColor(0.5,0.5,0.5);
			end
			if (title) then
				titleText:SetText(title);
			else
				titleText:SetText(name);
			end
			if (title == "Master Control Program") then
				checkbox:Hide();
			else
				checkbox:Show();
				checkbox:SetChecked(enabled);
			end
			if (security == "SECURE") then
				setSecurity(securityIcon,1);
			elseif (security == "INSECURE") then
				setSecurity(securityIcon,2);
			elseif (security == "BANNED") then
				setSecurity(securityIcon,3);
			end
			if (reason) then
				status:SetText(TEXT(getglobal("MCP_ADDON_"..reason)));
			elseif (loaded) then
				status:SetText(TEXT(MCP_ADDON_LOADED));
			elseif (ondemand) then
				status:SetText(MCP_LOADED_ON_DEMAND);
			else
				status:SetText("");
			end
			if (not loaded and enabled and ondemand) then
				loadnow:Show();
			else
				loadnow:Hide();
			end
		end

	end
end


function MCP_SaveProfile(profile)
  if profile == "NONE" then return end

  local numAddons = GetNumAddOns();
  local i;

  if not MCP_Config then MCP_Config = {} end
  if not MCP_Config.profiles then MCP_Config.profiles = {} end

  MCP_Config.profiles[profile] = {};

  for i = 1, numAddons do
    local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i);
    if enabled then
      MCP_Config.profiles[profile][name] = 1;
    else
      MCP_Config.profiles[profile][name] = 0;
    end
  end

  StaticPopupDialogs["MCP_PROFILESAVED"] = {
    text = MCP_PROFILE_SAVED..profile,
    button1 = TEXT(OK),
    OnAccept = function()
    end,
    timeout = 2,
    hideOnEscape = 1
  };

  StaticPopup_Show("MCP_PROFILESAVED");
end

function MCP_LoadProfile()
  local i;
  local addons;

  MCP_SelectedProfile = this.value;
  if not MCP_SelectedProfile or MCP_SelectedProfile == "" then
    MCP_SelectedProfile = "NONE";
    return;
  end

  for addons in MCP_Config.profiles[MCP_SelectedProfile] do
    if MCP_Config.profiles[MCP_SelectedProfile][addons] == 1 then
      EnableAddOn(addons);
    else
      DisableAddOn(addons);
    end
  end

  if not MCP_Config then MCP_Config = {}; end
  MCP_Config.SelectedProfile = MCP_SelectedProfile;
  UIDropDownMenu_SetText(MCP_SelectedProfile, MCP_AddonList_ProfileSelection);

  MCP_AddonList_OnShow()
end


function MCP_DeleteProfile(profile)
  if not MCP_Config then MCP_Config = {}; end
  if not MCP_Config.profiles then MCP_Config.profiles = {}; end
  local buttontext = MCP_PROFILE_DELETED..profile;

  if profile == "NONE" then
    buttontext = MCP_NO_PROFILE_DELETED;
  else
    MCP_Config.profiles[profile] = nil;
  end

  MCP_DeleteDialog();
end


function MCP_ResetProfiles(param)
  UIDropDownMenu_Initialize(this,  MCP_InitializeProfiles);
  UIDropDownMenu_SetWidth(220, this);

  if MCP_Config and MCP_Config.SelectedProfile then
    MCP_SelectedProfile = MCP_Config.SelectedProfile;
    UIDropDownMenu_SetText(MCP_SelectedProfile, MCP_AddonList_ProfileSelection);
  end
end

function MCP_InitializeProfiles()
  if MCP_Config and MCP_Config.profiles then
    local info = {};
    local profile;

    for profile in MCP_Config.profiles do
      info = {
        ["text"] = profile,
        ["value"] = profile,
        ["func"] = MCP_LoadProfile,
      };
      UIDropDownMenu_AddButton(info);
    end
  end
end


function MCP_EnableAll()
  local numAddons = GetNumAddOns();
  local i;

  for i = 1, numAddons do
    local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i);
    if not enabled then
      EnableAddOn(name);
    end
  end
  MCP_AddonList_OnShow();
end

function MCP_DisableAll()
  local numAddons = GetNumAddOns();
  local i;

  for i = 1, numAddons do
    local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i);
    if enabled then
      DisableAddOn(name);
    end
  end
  MCP_AddonList_OnShow();
end



function MCP_TooltipShow(index)
  local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index);

  color = { r = NORMAL_FONT_COLOR_r, g = NORMAL_FONT_COLOR_g, b = NORMAL_FONT_COLOR_b };
  
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT");
  if title then
    GameTooltip:AddLine(title, 1, 1, 1, 1);
  else
    GameTooltip:AddLine(name, 0.85, 0.85, 0.85, 1);
  end

  if notes then
    GameTooltip:AddLine(notes, color.r, color.g, color.b, 1);
  else
    GameTooltip:AddLine(MCP_NO_NOTES, color.r, color.g, color.b, 1);
  end

  GameTooltip:Show();
end


-- Crée le bouton minimap
local MCP_MinimapButton = CreateFrame("Button", "MCP_MinimapButton", Minimap)
MCP_MinimapButton:SetWidth(32)
MCP_MinimapButton:SetHeight(32)
MCP_MinimapButton:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, 0)
MCP_MinimapButton:SetMovable(true)
MCP_MinimapButton:EnableMouse(true)
MCP_MinimapButton:RegisterForDrag("LeftButton")
MCP_MinimapButton:RegisterForClicks("AnyUp")

-- Texture du bouton
local texture = MCP_MinimapButton:CreateTexture(nil, "BACKGROUND")
texture:SetTexture("Interface\\AddOns\\MCP-TW\\logo.tga") -- chemin vers ton logo
texture:SetAllPoints(MCP_MinimapButton)

-- Drag handlers
MCP_MinimapButton:SetScript("OnDragStart", function(self)
    this:StartMoving()
end)
MCP_MinimapButton:SetScript("OnDragStop", function(self)
    this:StopMovingOrSizing()
end)

-- Tooltip au survol
MCP_MinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:SetText("           |cffffff00MCP|r", 1, 1, 1)
	GameTooltip:AddLine(" ", 1, 1, 1)
	GameTooltip:AddLine("Click to open profiles.", 1, 1, 1)
    GameTooltip:Show()
end)

MCP_MinimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Clique pour ouvrir ton menu ou faire ce que tu veux
MCP_MinimapButton:SetScript("OnClick", function(self)
    -- Remplace par ta fonction d'ouverture de menu
    if MCP_MinimapButton_ShowMenu then
        MCP_MinimapButton_ShowMenu()
    else
        print("MCP menu function not defined")
    end
end)

function MCP_MinimapButton_OnClick()
    if MCP_AddonList:IsVisible() then
        HideUIPanel(MCP_AddonList);
    else
        ShowUIPanel(MCP_AddonList);
    end
end

function MCP_OpenModifyProfileWindow(profile)
    if not profile or profile == "" or profile == "NONE" then
        print("Invalid profile or no profile selected.")
        return
    end

    MCP_SelectedProfile = profile

    -- Met à jour le texte du menu déroulant pour afficher le profil choisi
    UIDropDownMenu_SetText(MCP_SelectedProfile, MCP_AddonList_ProfileSelection)

    -- Met à jour la fenêtre avec les données du profil
    -- Recharge les addons selon le profil pour l'affichage dans la fenêtre
    if MCP_Config and MCP_Config.profiles and MCP_Config.profiles[MCP_SelectedProfile] then
        for addon, enabled in pairs(MCP_Config.profiles[MCP_SelectedProfile]) do
            if enabled == 1 then
                EnableAddOn(addon)
            else
                DisableAddOn(addon)
            end
        end
    end

    MCP_AddonList_OnShow()

    -- Ouvre la fenêtre de la liste d'addons (où on modifie le profil)
    ShowUIPanel(MCP_AddonList)
end

local raidZones = {
    ["Naxxramas"] = true,
    ["Zul'Gurub"] = true,
    ["Ruins of Ahn'Qiraj"] = true,
    ["Molten Core"] = true,
    ["Onyxia's Lair"] = true,
    ["Lower Karazhan Halls"] = true,
    ["Blackwing Lair"] = true,
    ["Emerald Sanctum"] = true,
    ["Temple of Ahn'Qiraj"] = true,
    ["Upper Karazhan Halls"] = true,
}

function MCP_CheckRaidZoneAndPrompt()
    local zone = GetRealZoneText()
    
    if raidZones[zone] then
        if MCP_Config and MCP_Config.profiles and MCP_Config.profiles["raid"] then
            -- Popup pour charger le profil raid
            StaticPopupDialogs["MCP_LOAD_RAID_PROFILE"] = {
                text = "You have entered raid zone '"..zone.."'. Load 'raid' profile?",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    MCP_LoadProfileByName("raid")
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
            }
            StaticPopup_Show("MCP_LOAD_RAID_PROFILE")
        else
            -- Popup pour créer le profil raid
            StaticPopupDialogs["MCP_CREATE_RAID_PROFILE"] = {
			text = "You have entered raid zone '"..zone.."'. 'raid' profile does not exist. Create it now?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				if not MCP_Config.profiles then MCP_Config.profiles = {} end
				MCP_Config.profiles["raid"] = {} -- créer un profil vide
				print("Raid profile created!")

				-- Ouvre la fenêtre de modif du profil raid
				MCP_OpenModifyProfileWindow("raid")
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			}	
            StaticPopup_Show("MCP_CREATE_RAID_PROFILE")
        end
    else

    end
end


local MCP_ZoneCheckFrame = CreateFrame("Frame")
MCP_ZoneCheckFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
MCP_ZoneCheckFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

MCP_ZoneCheckFrame:SetScript("OnEvent", function()
    MCP_CheckRaidZoneAndPrompt()
end)


function MCP_LoadProfileByName(profileName)
    if not MCP_Config.profiles[profileName] then
        print("|cffff0000[MCP]|r The profile '" .. profileName .. "' does not exist.")
        return
    end

    for addon, enabled in pairs(MCP_Config.profiles[profileName]) do
        if enabled == 1 then
            EnableAddOn(addon)
        else
            DisableAddOn(addon)
        end
    end

    MCP_SelectedProfile = profileName
    MCP_Config.SelectedProfile = profileName

    print("|cff00ff00[MCP]|r Profile loaded: |cffffff00" .. profileName .. "|r")
    ReloadUI()
end


function MCP_DeleteProfile(profile)
    if not MCP_Config then MCP_Config = {} end
    if not MCP_Config.profiles then MCP_Config.profiles = {} end

    if profile == "NONE" then return end
    MCP_Config.profiles[profile] = nil

    -- Feedback utilisateur
    StaticPopupDialogs["MCP_PROFILE_DELETED"] = {
        text = "Profile '" .. profile .. "' deleted.",
        button1 = OKAY,
        timeout = 2,
        hideOnEscape = 1
    }
    StaticPopup_Show("MCP_PROFILE_DELETED")
end

function MCP_ShowSaveProfilePopup()
    StaticPopupDialogs["MCP_SAVEPROFILE"] = {
        text = "New profile name:",
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        maxLetters = 32,
        timeout = 0,
        hideOnEscape = 1,
        OnAccept = function()
            local editBox = getglobal(this:GetParent():GetName().."EditBox")
            MCP_SaveProfile(editBox:GetText())
        end,
        EditBoxOnEnterPressed = function()
            local editBox = getglobal(this:GetParent():GetName().."EditBox")
            MCP_SaveProfile(editBox:GetText())
            this:GetParent():Hide()
        end,
        OnShow = function()
            local editBox = getglobal(this:GetName().."EditBox")
            local text = " "
            if text == "NONE" then
                text = ""
            end
            editBox:SetText(text)
            editBox:SetFocus()
        end,
    }
    StaticPopup_Show("MCP_SAVEPROFILE")
end

function MCP_MinimapButton_ShowMenu()
    if not MCP_MinimapDropDown then
        DEFAULT_CHAT_FRAME:AddMessage("Dropdown not found!");
        return;
    end

    UIDropDownMenu_Initialize(MCP_MinimapDropDown, MCP_MinimapDropDown_Initialize, "MENU");
    ToggleDropDownMenu(1, nil, MCP_MinimapDropDown, "cursor", -20, -10);
end




function MCP_MinimapDropDown_Initialize(level)
    level = level or 1
    local info = {}

    if level == 1 then
        -- MCP en jaune centré (espace simulé)
        info.text = "             |cffffff00MCP|r"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Ligne vide (saut de ligne)
        info = {}
        info.text = " "
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Save a new profile (bleu cyan)
        info = {}
        info.text = "|cff00ffffSave a new profile|r"
        info.func = function()
            MCP_ShowSaveProfilePopup()
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Ligne vide
        info = {}
        info.text = " "
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Load Profile >
        info = {}
        info.text = "|cffffffffLoad Profile|r"
        info.hasArrow = true
        info.notCheckable = true
        info.value = "loadProfiles"
        UIDropDownMenu_AddButton(info, level)

    elseif level == 2 then
        if UIDROPDOWNMENU_MENU_VALUE == "loadProfiles" then
            if MCP_Config and MCP_Config.profiles and next(MCP_Config.profiles) then
                for name, _ in pairs(MCP_Config.profiles) do
                    info = {}
                    local isCurrent = (name == MCP_Config.SelectedProfile)
                    if isCurrent then
                        info.text = "|cff00ff00" .. name .. "|r"  -- vert si actif
                    else
                        info.text = "|cffffffff" .. name .. "|r"  -- blanc sinon
                    end
                    info.hasArrow = true
                    info.value = name
                    info.notCheckable = true
                    UIDropDownMenu_AddButton(info, level)
                end
            else
                info = {}
                info.text = "No profiles available"
                info.isTitle = true
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
            end
        end

    elseif level == 3 then
        local profile = UIDROPDOWNMENU_MENU_VALUE
        if not profile then return end

        -- Load
        info = {}
        info.text = "Load"
        info.func = function()
            MCP_LoadProfileByName(profile)
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Modify (placé avant Delete)
        info = {}
        info.text = "Modify"
        info.func = function()
            MCP_SelectedProfile = profile
            MCP_Config.SelectedProfile = profile

            for addon, enabled in pairs(MCP_Config.profiles[profile]) do
                if enabled == 1 then
                    EnableAddOn(addon)
                else
                    DisableAddOn(addon)
                end
            end

            UIDropDownMenu_SetText(profile, MCP_AddonList_ProfileSelection)
            MCP_AddonList_OnShow()
            ShowUIPanel(MCP_AddonList)
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Delete
        info = {}
        info.text = "Delete"
        info.func = function()
            StaticPopupDialogs["MCP_CONFIRM_DELETE"] = {
                text = "Are you sure you want to delete profile '" .. profile .. "'?",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    MCP_DeleteProfile(profile)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("MCP_CONFIRM_DELETE")
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    end
end
