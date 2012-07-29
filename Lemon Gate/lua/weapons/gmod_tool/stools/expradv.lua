TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Expression Advanced"
TOOL.Command 		= nil
TOOL.ConfigName 	= nil
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add( "Tool_expradv_name", 	"Expression Advanced" )
	language.Add( "Tool_expradv_desc", 	"Spawns an Expression Advanced chip." )
	language.Add( "Tool_expradv_0", 	"Create/Update Expression, Secondary: Open Expression in Editor,Reload: Reload Expression" )
end


--[[ 
SERVER
ConsoleCommands
	ea_sendcode_begin [entid] [chunks]
	ea_sendcode_chunk [entid] [code]
		Max: 237
		Used: 230

CLIENT
Usermessages 
	ea_getcode [entid]
	ea_chunk_confirm [entid] [bool]

--]]

if SERVER then
	function TOOL:LeftClick(trace)
		if !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		local player = self:GetOwner()

		local pos = trace.HitPos
		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90

		if trace.Entity:IsValid()
		    and trace.Entity:GetClass() == "lemongate"
			and trace.Entity.player == player
			and E2Lib.isFriend(trace.Entity.player, player)
		then
			self:Upload( trace.Entity )
			return true
		end

		local entity = ents.Create("lemongate")
		if !entity or !entity:IsValid() then return false end

		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
		entity:SetPlayer(player)
		entity.player = player
		entity:SetNWEntity( "_player", player )

		undo.Create( "lemongate" )
			undo.AddEntity(entity)
			undo.SetPlayer(player)
		undo.Finish()

		player:AddCleanup( "lemongate", entity )

		self:Upload( entity )
		return true
	end

	function TOOL:RightClick(trace) -- TODO: Add this (when we have a editor :P) /Oskar
	end

	function TOOL:Reload(trace) 
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local player = self:GetOwner()

		if trace.Entity:IsValid()
		    and trace.Entity:GetClass() == "lemongate"
			and trace.Entity.player == player
			and E2Lib.isFriend(trace.Entity.player, player)
		then
			trace.Entity:ReStart()
			return true
		else
			return false
		end
	end

	function TOOL:Upload( ent ) 
		umsg.Start( "ea_getcode", self:GetOwner( ) )
			umsg.Short( ent:EntIndex( ) )
		umsg.End( )
	end

	/*---------------------------------------------------------------------------
	Upload / Download
	---------------------------------------------------------------------------*/

	local downloads = {}
	local function download_begin( ply, cmd, args )
		local id = ply:UniqueID()
		downloads[id] = downloads[id] or {}

		local download = {}
		
		local entid = tonumber( args[1] )
		if !entid then return end
		local ent = Entity( entid )
		if !IsValid( ent ) or ent:GetClass() ~= "lemongate" then
			ply:PrintMessage( HUD_PRINTTALK, "Invalid Expression Advanced chip specified. Upload aborted." )
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_" .. entid )
			return
		end

		if ply ~= ent.player then
			ply:PrintMessage( HUD_PRINTTALK, "You are not allowed to upload to the target Expression Advanced chip. Upload aborted." )
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_" .. entid  )
			return
		end
		
		download.entid = ent		
		
		download.chunks = tonumber( args[2] )
		if !download.chunks then
			ply:PrintMessage( HUD_PRINTTALK, "Error: No chunk number specified. Upload aborted." )
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_" .. entid )
			return
		end
		
		download.data = {}
		
		downloads[id][entid] = download
		
		timer.Create( "ea_upload_timeout_" .. entid, 5, 1, function()
			if ply and ply:IsValid() then ply:PrintMessage( HUD_PRINTTALK, "Expression Advanced upload timed out!" ) end
			downloads[id][entid] = nil
		end)
		
		umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( true ) umsg.End()
	end

	local function download_chunk( ply, cmd, args )
		local id = ply:UniqueID()
		if !downloads[id] then return end
	
		local entid = tonumber(args[1])
		if !entid or !downloads[id][entid] then return end
		ent = Entity(entid)
		if !IsValid(ent) or ent:GetClass() ~= "lemongate" then
			ply:PrintMessage( HUD_PRINTTALK, "Invalid Expression Advanced chip specified. Upload aborted." )
			downloads[id][entid] = nil
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_" .. entid )
			return
		end
		
		local download = downloads[id][entid]
		
		if !IsValid( download.entid ) then
			ply:PrintMessage( HUD_PRINTTALK, "Target Expression chip has been removed since the start of the upload. Upload aborted." )
			downloads[id][entid] = nil
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_" .. entid )
			return
		end
		
		if download.entid ~= ent then
			ply:PrintMessage( HUD_PRINTTALK, "Target Expression chips do not match. Upload aborted." )
			downloads[id][entid] = nil
			umsg.Start( "ea_chunk_confirm", ply ) umsg.Long( entid ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "ea_upload_timeout_"..entid )
			return
		end
	
		download.data[#download.data+1] = args[2]
		
		timer.Start( "ea_upload_timeout_"..entid )

		if #download.data == download.chunks then 
			local code = eaDecode( table.concat( download.data, "" ) )

			download.entid:LoadScript( code )
			download.entid:Execute()
			
			timer.Destroy( "ea_upload_timeout_"..entid )
			downloads[id][entid] = nil
		end
	end

	concommand.Add( "ea_sendcode_begin", download_begin )
	concommand.Add( "ea_sendcode_chunk", download_chunk )
elseif CLIENT then
	
	/*---------------------------------------------------------------------------
	Upload / Download
	---------------------------------------------------------------------------*/
	do 
		local uploads = {}
		local chunks_total, chunks_current = 0, 0

		local prev, sleeptime = 0, 0.1
		local function send( )
			if prev > CurTime() then return end
			prev = CurTime() + sleeptime

			if #uploads == 0 then 
				hook.Remove( "Think", "EA_UploadThink" )
				chunks_total, chunks_current = 0, 0
				return 
			end

			local curr = uploads[1]
			if curr.state > 0 then 
				RunConsoleCommand( "ea_sendcode_chunk", curr.ent, curr.data[curr.state] )
				if curr.state >= #curr.data then
					table.remove( uploads, 1 )
					return
				else
					chunks_current = chunks_current + 1
					curr.state = curr.state + 1
				end
			elseif curr.state == -1 then 
				RunConsoleCommand( "ea_sendcode_begin", curr.ent, #curr.data )
				curr.state = 0
				chunks_current = chunks_current + 1
				timer.Create( "ea_upload_confirm_timeout_" .. curr.ent,5,1,function()
					PrintMessage( "Upload handshake timeout. Server did not respond. Upload aborted." )
					table.remove( uploads, 1 )
				end)
			end
		end

		function LemonGate.Upload( ent, code )
			ent = ent or LocalPlayer( ):GetEyeTrace( ).Entity
			if ltype( ent ) == "entity" then
				if !IsValid( ent ) or ent:GetClass() ~= "lemongate" then
					return PrintMessage( "Invalid Expression entity specified!" )
				end
				ent = ent:EntIndex()
			end
			
			for i = 1, #uploads do
				if uploads[i].ent == ent then
					return PrintMessage( "You're already uploading to that Expression chip. Slow down!" )
				end
			end

			code = code or CODE or "" //TODO: Get editor code ( when we have one )

			if ea_function_data then 
				// TODO: Validate clientside
			end

			local upload = { 
				state = -1, 
				ent = ent, 
				data = string.chop( eaEncode( code ) ) 
			}
			uploads[#uploads + 1] = upload
			chunks_total = chunks_total + #upload.data

			if #uploads == 1 then
				hook.Add( "Think", "EA_UploadThink", send )
			end
		end

		local function ea_getcode( um )
			LemonGate.Upload( um:ReadShort() )
		end

		local function ea_chunk_confirm( um )
			local ent, ok = um:ReadLong(), um:ReadBool()
			for i = 1, #uploads do
				if uploads[i].ent == ent then
					
					if uploads[i].state == 0 then
						uploads[i].state = 1
						timer.Remove( "ea_upload_confirm_timeout_" .. uploads[i].ent )
					end
					
					if bool == false then
						table.remove( uploads, i )
					end
					
					return
				end
			end
		end
		
		usermessage.Hook( "ea_getcode", ea_getcode )
		usermessage.Hook( "ea_chunk_confirm", ea_chunk_confirm )
	end

	/*---------------------------------------------------------------------------
	Tool CPanel
	---------------------------------------------------------------------------*/

	function TOOL.BuildCPanel(panel)
		panel:ClearControls()
		panel:AddControl("Header", { Text = "#Tool_expradv_name", Description = "#Tool_expradv_desc" })

		local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("Lemongate")
		FileBrowser:SetSize(235,400)

		function FileBrowser:OnFileClick()
			print( self.File.FileDir )
			CODE = file.Read( self.File.FileDir )
		end
	end

	function TOOL:RenderToolScreen() end 
end

