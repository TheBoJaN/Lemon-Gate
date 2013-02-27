/*============================================================================================================================================
	Expression-Advanced Derma
==============================================================================================================================================
	Name: EA_EditorPanel
	Author: Oskar 
============================================================================================================================================*/

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )

local PANEL = {}

local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
	[":"] = "",
	[","] = "",
}

local function sort( a, b )
	if a.IsFile == b.IsFile then 
		return string.lower( a.Name ) < string.lower( b.Name )
	end 
	return not a.IsFile 
end

local function InvalidateLayout( panel ) 
	if panel.ChildNodes then panel.ChildNodes:InvalidateLayout( true ) end
	panel:InvalidateLayout( true ) 
	if panel.GetParentNode then InvalidateLayout( panel:GetParentNode( ) ) end 
end

function PANEL:Update( )
	if self.LemonNode.ChildNodes then 
		self.LemonNode.ChildNodes:Remove( )
		self.LemonNode.ChildNodes = nil
	end 
	self.LemonNode:CreateChildNodes( )
	self.LemonNode:SetNeedsPopulating( true )
	self.LemonNode:PopulateChildrenAndSelf( true )
end

function PANEL:Init( ) 
	self:SetKeyBoardInputEnabled( true )
	self:SetMouseInputEnabled( true )
	self:SetSizable( true )
	self:SetMinWidth( 600 )
	self:SetMinHeight( 300 )
	self:SetText( "Expression Advanced Editor" )
	
	
	self.TabHolder = self:Add( "DPropertySheet" ) 
	self.TabHolder:Dock( FILL )
	self.TabHolder:DockMargin( 5, 5, 5, 5 )
	self.TabHolder:SetFadeTime( 0 )
	-- self.TabHolder.Paint = function( self, w, h ) end 
	timer.Simple( 0.1, function( ) 
		if self:OpenOldTabs( ) then return end 
		self:NewTab( ) 
	end ) 
	-- self.TabHolder.DoRightClick = function( ) print":D" end 
	
	
	self.Browser = self:Add( "DTree" )
	self.Browser:Dock( LEFT )
	self.Browser:DockMargin( 5, 5, 0, 40 )
	self.Browser:SetWide( 200 ) 
	
	self.Browser.Paint = function( _, w, h )
		surface.SetDrawColor( 100, 100, 100, 255 )
		surface.DrawRect( 0, 0, w, h )
		
		surface.SetDrawColor( 75, 75, 75 )
		surface.SetMaterial( gradient_down )
		surface.DrawTexturedRect( 0, 0, w, h )
		return true 
	end 
	
	self.Browser.DoClick = function( _, Node ) 
		local Dir = Node:GetFileName( ) or ""
		
		if !string.EndsWith( Dir, ".txt" ) then return end 
		
		if Node.LastClick and CurTime( ) - Node.LastClick < 0.5 then 
			self:LoadFile( Dir )
			Node.LastClick = 0
			return true 
		end 
		
		Node.LastClick = CurTime( ) 
	end 
	
	-- [[
	self.Browser.DoRightClick = function( _, Node ) 
		if Node then 
			if IsValid( self.Browser.m_pSelectedItem ) then
				self.Browser.m_pSelectedItem:SetSelected( false )
			end
			
			self.Browser.m_pSelectedItem = Node
			Node:SetSelected( true )
			
			local Dir = Node:GetFileName( ) or ""
			if string.EndsWith( Dir, ".txt" ) then 
				// File 
				local Menu = DermaMenu( ) 
				
				-- Menu:AddOption( "Open", function( ) end ) 
				
				-- Menu:AddSpacer( ) 
				
				-- Menu:AddOption( "Copy", function( ) end ) 
				-- Menu:AddOption( "Move", function( ) end ) 
				-- Menu:AddOption( "Rename", function( ) end ) 
				
				-- Menu:AddSpacer( ) 
				
				Menu:AddOption( "New File", function( ) self:NewTab( ) end ) 
				Menu:AddOption( "New Folder", function( ) 
					Derma_StringRequest( "Create new folder", "", "new folder",
					function( result ) 
						file.CreateDir( "lemongate/" .. result )
					end )
				end ) 
				-- Menu:AddOption( "Delete", function( ) end ) 
				
				Menu:Open( ) 
			else 
				// Folder 
				local Menu = DermaMenu( ) 
				
				// Keep or not to keep, that's the question
				if Node.m_bExpanded then 
					Menu:AddOption( "Close", function( ) Node:SetExpanded( false ) end ) 
				else 
					Menu:AddOption( "Open", function( ) Node:SetExpanded( true ) end ) 
				end 
				Menu:AddSpacer( ) 
				
				Menu:AddOption( "New File", function( ) self:NewTab( ) end ) 
				Menu:AddOption( "New Folder", function( ) 
					Derma_StringRequest( "Create new folder", "", "new folder",
					function( result ) 
						file.CreateDir( "lemongate/" .. result )
					end )
				end ) 
				
				Menu:Open( ) 
			end 
		else // TODO: Make this actually happen
			// Panel 
			local Menu = DermaMenu( ) 
			
			Menu:AddOption( "New File", function( ) self:NewTab( ) end ) 
			Menu:AddOption( "New Folder", function( ) end ) 
			
			Menu:Open( )
		end 
	end 
	-- ]]
	
	
	self.LemonNode = vgui.Create( "EA_FileNode" )
	self.Browser.RootNode:InsertNode( self.LemonNode )
	self.LemonNode:SetText( "Lemongate" ) 
	self.LemonNode:MakeFolder( "lemongate", "DATA", true, false, false, "fugue/script-text.png" ) 
	self.LemonNode:SetExpanded( true ) 
	
	
	self.BrowserRefresh = self:Add( "EA_Button" )
	self.BrowserRefresh:SetWide( 200 )
	self.BrowserRefresh:SetTall( 30 )
	self.BrowserRefresh:SetText( "Update" ) 
	self.BrowserRefresh:SetTextCentered( true ) 
	self.BrowserRefresh.DoClick = function( ) self:Update( ) end
	
	self.Browser:DockMargin( 5, self.BrowserRefresh:GetTall( ) + 10, 0, 5 )
	
	
	self.BrowserFolding = self:Add( "EA_ImageButton" ) 
	self.BrowserFolding:SetMaterial( Material( "oskar/arrow-left.png" ) ) 
	self.BrowserFolding.Expanded = true 
	
	self.BrowserFolding.Think = function( btn ) 
		btn:SetPos( self.ToolBar.x - 35, 30 )
	end 
	
	self.BrowserFolding.DoClick = function( btn ) 
		if btn.Expanded then 
			btn.Expanded = false 
			btn:SetMaterial( Material( "oskar/arrow-right.png" ) ) 
			self.Browser:SizeTo( 0, -1, 1, 0, 1 )
			self.BrowserRefresh:SizeTo( 0, -1, 1, 0, 1 )
			self.Browser:DockMargin( 0, self.BrowserRefresh:GetTall( ) + 10, 0, 5 )
		else 
			btn.Expanded = true 
			btn:SetMaterial( Material( "oskar/arrow-left.png" ) ) 
			self.BrowserRefresh:SizeTo( 200, -1, 1, 0, 1 )
			self.Browser:SizeTo( 200, -1, 1, 0, 1 )
			self.Browser:DockMargin( 5, self.BrowserRefresh:GetTall( ) + 10, 0, 5 )
		end 
	end 
	
	self.ToolBar = self:Add( "EA_ToolBar" )
	self.ToolBar:Dock( TOP )
	self.ToolBar:DockMargin( 5 + 35, 5, 5, 0 )
	self.ToolBar:SetTall( 30 ) 
	
	
	self.ValidateButton = self:Add( "EA_Button" )
	self.ValidateButton:Dock( BOTTOM )
	self.ValidateButton:DockMargin( 5, 0, 5, 5 )
	self.ValidateButton:SetTextCentered( true )
	self.ValidateButton:SetFading( false )
	self.ValidateButton:SetColor( Color( 0, 0, 255 ) ) 
	self.ValidateButton:SetTextColor( Color( 0, 0, 0 ) ) 
	self.ValidateButton:SetText( "Click to validate." )
	self.ValidateButton:SetFont( "Trebuchet20")
	
	self.ValidateButton.DoClick = function( )
		self:DoValidate( true )
	end
	
	file.CreateDir( "Lemongate" )
end

function PANEL:DoValidate( Goto )
	local Error = self:Validate( self:GetCode( ), nil )
		
	if !LemonGate.TypeTable or !LemonGate.FunctionTable or !LemonGate.OperatorTable or !LemonGate.EventsTable then
		self.ValidateButton:SetText( "Downloading Validation Files, Please wait..." )
		return RunConsoleCommand("lemon_sync")
		
	elseif Error then 
		self.ValidateButton:SetColor( Color( 255, 0, 0 ) )
		self.ValidateButton:SetText( Error )
		
		if Goto then
			local Row, Col = Error:match("at line ([0-9]+), char ([0-9]+)$")
			
			if !Row then
				Row, Col = Error:match("at line ([0-9]+)$"), 1
			end
			
			if Row then
				self:SetCaret( Vector2( tonumber( Row ), tonumber( Col ) ) )
			end
		end
	else 
		self.ValidateButton:SetColor( Color( 0, 255, 0 ) )
		self.ValidateButton:SetText( "Validation Successful!" )
	end
end

local Tokenizer = LemonGate.Tokenizer
local Parser = LemonGate.Parser
local Compiler = LemonGate.Compiler

function PANEL:Validate( Script )
	local Check, Tokens, Rows = Tokenizer.Execute( Script, true )
	if !Check then return Tokens end
	-- PrintTable( Tokens )
	local Check, Instructions = Parser.Execute( Tokens )
	if !Check then return Instructions end
	
	local Check, Executable, Instance = Compiler.Execute( Instructions )
	if !Check then return Executable end
	
	local Types = Instance.VarTypes
	
	for Cell, Name in pairs( Instance.Inputs ) do
		local Type = LemonGate.TypeShorts[ Types[Cell] ]
		
		if !Type[4] or !Type[5] then
			return "Type '" .. Type[1] .. "' may not be used as input."
		end
	end
	
	for Cell, Name in pairs( Instance.Outputs ) do
		local Type = LemonGate.TypeShorts[ Types[Cell] ]
		
		if !Type[4] or !Type[6] then
			return "Type '" .. Type[1] .. "' may not be used as output."
		end
	end
end

function PANEL:SetCode( Code ) 
	self.TabHolder:GetActiveTab( ):GetPanel( ):SetCode( Code )
end

function PANEL:GetCode( )
	return self.TabHolder:GetActiveTab( ):GetPanel( ):GetCode( )
end

function PANEL:SetCaret( Pos )
	self.TabHolder:GetActiveTab( ):GetPanel( ):SetCaret( Pos )
end

local function MakeFolders( Path )
	local folder, filename, ext = string.match( Path, "^(.+)/([^%.]+)%.(.+)$" ) 
	file.CreateDir( folder )
end

function PANEL:SaveFile( Path, SaveAs )
	Path = Path or self.TabHolder:GetActiveTab( ).FilePath
	if !Path or SaveAs then 
		Derma_StringRequest( "Save to New File", "", "generic",
		function( result )
			result = string.gsub( result, ".", invalid_filename_chars )
			self:SaveFile( result .. ".txt" )
		end )
		return
	end
	
	if !string.StartWith( Path, "lemongate/" ) then Path = "lemongate/" .. Path end 
	
	MakeFolders( Path )
	
	file.Write( Path , self:GetCode( ) )
	surface.PlaySound( "ambient/water/drip3.wav" )
	self.ValidateButton:SetText( "Saved as " .. Path )
	if !self.TabHolder:GetActiveTab().FilePath then 
		self.TabHolder:GetActiveTab().FilePath = Path 
	end 
end

function PANEL:LoadFile( Path )
	if !Path or file.IsDir( Path, "DATA" ) then return end
	local Code = file.Read( Path )
	if Code then 
		self:NewTab( Code, Path:sub( 11 ) )
	end
end

function PANEL:SetSyntaxColorLine( func )
	self.SyntaxColorLine = func
	for i = 1, #self.TabHolder.Items do
		self.TabHolder.Items[i].Panel.SyntaxColorLine = func
	end
end
function PANEL:GetSyntaxColorLine( ) return self.SyntaxColorLine end 

// Override 
function PANEL:OnTabCreated( Tab, Code, Path ) 
	return false 
end

local function DoRightClick( self )
	local Menu = DermaMenu( ) 
	
	Menu:AddOption( "Close", function( ) end ) 
	Menu:AddOption( "Close others", function( ) end ) 
	Menu:AddOption( "Close tabs to the right", function( ) end ) 
	
	Menu:AddSpacer( ) 
	
	Menu:AddOption( "Save", function( ) end ) 
	Menu:AddOption( "Save As", function( ) end ) 
	
	Menu:AddSpacer( ) 
	
	Menu:AddOption( "New File", function( ) self:NewTab( ) end ) 
	
	Menu:Open( ) 
end

function PANEL:NewTab( Code, Path )
	local Sheet = self.TabHolder:AddSheet( Path or "generic", vgui.Create( "EA_Editor" ), "fugue/script-text.png" ) 
	self.TabHolder:SetActiveTab( Sheet.Tab ) 
	Sheet.Panel:RequestFocus( )
	
	local func = self:GetSyntaxColorLine( )
	if func != nil then 
		Sheet.Panel.SyntaxColorLine = func
	end
	
	-- Sheet.Tab.DoRightClick = DoRightClick 
	-- Sheet.Tab.Editor = self 
	
	if Path then Sheet.Tab.FilePath = Path end 
	if self:OnTabCreated( Sheet.Tab, Code, Path ) then return end 
	if Code and Code ~= "" then self:SetCode( Code ) end 
end

function PANEL:CloseTab( bSave ) 
	local Tab = self.TabHolder:GetActiveTab( ) 
	local Editor = Tab:GetPanel( )
	 
	if #self.TabHolder.Items == 1 then 
		self:NewTab( ) 
	end 
	
	if bSave and Tab.FilePath then // Ask about this?
		self:SaveFile( Tab.FilePath )
	end 
	
	self.TabHolder:CloseTab( Tab, true )
	
	self.TabHolder.Items[#self.TabHolder.Items].Tab:GetPanel( ):RequestFocus( )
end 

function PANEL:CloseAll( bSave )
	// TODO!!
end

function PANEL:SaveTabs( )
	local strtabs = ""
	for i = 1, #self.TabHolder.Items do
		local FilePath = self.TabHolder.Items[i].Tab.FilePath
		if FilePath and FilePath != "" then
			strtabs = strtabs .. FilePath .. ";"
		end
	end

	strtabs = strtabs:sub( 1, -2 )

	file.Write( "lemongate/_tabs_.txt", strtabs )
end

function PANEL:OpenOldTabs( ) 
	if !file.Exists( "lemongate/_tabs_.txt", "DATA" ) then return end 
	
	local tabs = file.Read( "lemongate/_tabs_.txt" )
	if !tabs or tabs == "" then return end
	
	tabs = string.Explode( ";", tabs )
	if !tabs or #tabs == 0 then return end
	
	local opentabs = false
	for k, v in pairs( tabs ) do 
		v = "lemongate/" .. v
		if v and v != "" then
			if file.Exists( v, "DATA" ) then
				self:LoadFile( v, true )
				opentabs = true
			end
		end
	end
	
	return opentabs 
end

function PANEL:Open( Code, NewTab )
	self:SetVisible( true )
	self:MakePopup( )
	
	if NewTab then 
		self:NewTab( Code ) 
	elseif Code then 
		self:SetCode( Code ) 
	end 
end

function PANEL:GetCode( ) 
	return self.TabHolder:GetActiveTab():GetPanel():GetCode() 
end 

function PANEL:Close( )
	self:SaveTabs( ) 
	
	if GLOBALDERMAPANEL and GLOBALDERMAPANEL == self then 
		self:Remove( ) 
	else 
		self:SetVisible( false ) 
	end 
end

function PANEL:PerformLayout( )
	self.BrowserRefresh:SetPos( 5, 30 )
end

vgui.Register( "EA_EditorPanel", PANEL, "EA_Frame" )
