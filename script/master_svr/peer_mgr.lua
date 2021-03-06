
local server_conf = require "global.server_conf"
local net_mgr = require "net.net_mgr"
local server_mgr = require "server.server_mgr"
local Log = require "log.logger"
local Util = require "util.util"
local class = require "util.class"
local msg_def = require "global.net_msg_def"
local MID = msg_def.MID
local ErrorCode = require "global.error_code"
local global_define = require "global.global_define"
local ServerType = global_define.ServerType
local ServerTypeName = global_define.ServerTypeName
local MAILBOX_ID_NIL = global_define.MAILBOX_ID_NIL

local PeerMgr = class()

function PeerMgr:ctor()
	--[[
	{[1] = {
		mailbox_id=x,
		server_id=x,
		server_type=x,
		single_scene_list=x,
		from_to_scene_list=x,
		ip=x,
		port=x,
	--]]
	self._register_peer_list = {} 

end

-- when new peer connect to master server, send s2s_shake_hand_req, will call this function
-- this function will invite new peer connect to forward other peer. and new peer will push back into peer list
-- if peer disconnect, will not remove from peer list, just set mailbox_id invalid
function PeerMgr:shake_hand(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = server_conf._server_id,
		server_type = server_conf._server_type,
		single_scene_list = server_conf._single_scene_list,
		from_to_scene_list = server_conf._from_to_scene_list,
	}

	-- add server
	local new_server_info = server_mgr:add_server(mailbox_id, server_id, server_type
	, single_scene_list, from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.SHAKE_HAND_FAIL
		net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)
		return false
	end

	-- check if exists same server_id
	local reconn_peer_index = 0
	local front_peer_list = {}
	for index, peer in ipairs(self._register_peer_list) do
		if peer.server_id ~= server_id then
			if peer.mailbox_id ~= MAILBOX_ID_NIL then
				table.insert(front_peer_list, 
				{
					ip = peer.ip,
					port = peer.port,
				})
			end
			goto continue
		end

		-- duplicate server_id
		if peer.mailbox_id ~= 0 then
			Log.err("PeerMgr:shake_hand duplicate server_id register %d", server_id)
			msg.result = ErrorCode.SHAKE_HAND_FAIL
			net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)
			return false
		end

		-- peer reconnect
		peer.mailbox_id = mailbox_id
		peer.server_id = server_id
		peer.server_type = server_type
		peer.single_scene_list = single_scene_list
		peer.from_to_scene_list = from_to_scene_list
		peer.ip = ip
		peer.port = port

		reconn_peer_index = index
		break

		::continue::
	end

	net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)

	-- in peer is reconnect peer
	if reconn_peer_index > 0 then
		-- send front_peer_list to in peer
		if next(front_peer_list) then
			local msg2 =
			{
				peer_list = front_peer_list
			}
			net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_invite, msg2)
		end

		-- send new peer addr to back peer
		local msg2 = 
		{
			peer_list =
			{
				{
					ip = ip,
					port = port,
				}
			}
		}
		for i=reconn_peer_index+1, #self._register_peer_list do
			local peer = self._register_peer_list[i]
			if peer.mailbox_id ~= MAILBOX_ID_NIL then
				net_mgr:send_msg(peer.mailbox_id, MID.s2s_shake_hand_invite, msg2)
			end
		end
		self:print()
		return true
	end

	-- shake hand peer is new peer
	-- invite new peer to connect them
	if #self._register_peer_list > 0 then
		local msg2 = 
		{
			peer_list = {}
		}
		for _, peer in ipairs(self._register_peer_list) do
			if peer.mailbox_id ~= MAILBOX_ID_NIL then
				table.insert(msg2.peer_list, 
				{
					ip = peer.ip,
					port = peer.port,
				})
			end
		end
		net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_invite, msg2)
	end

	-- push back into peer list
	local peer = 
	{
		mailbox_id = mailbox_id,
		server_id = server_id, 
		server_type = server_type,
		single_scene_list = single_scene_list,
		from_to_scene_list = from_to_scene_list,
		ip = ip,
		port = port,
	}
	table.insert(self._register_peer_list, peer)
	
	self:print()
	self:save_peer_list()
	return true
end

function PeerMgr:server_disconnect(server_id)
	local target_peer
	for _, peer in ipairs(self._register_peer_list) do
		if peer.server_id == server_id then
			peer.mailbox_id = 0
			target_peer = peer
			break
		end
	end
	if not target_peer then
		return
	end

	for _, peer in ipairs(self._register_peer_list) do
		if peer.mailbox_id ~= 0 then
			net_mgr:send_msg(peer.mailbox_id, MID.s2s_shake_hand_cancel, target_peer)
		end
	end

	self:print()
end

-- write current peer into file
-- NOTE: DO NOT DELETE peer data file when server is running!
function PeerMgr:save_peer_list()
	local peer_list = {}
	for _, v in ipairs(self._register_peer_list) do
		table.insert(peer_list,
		{
			server_id = v.server_id,
		})
	end

	local str = Util.serialize(peer_list)
	-- Log.debug("PeerMgr:save_peer_list str=%s", str)
	local file_name = string.format("dat/peer%d.dat", server_conf._server_id)
	local file = io.open(file_name, "w")
	file:write(str)
	file:close()
end

function PeerMgr:load_peer_list()
	local file_name = string.format("dat/peer%d.dat", server_conf._server_id)
	local file = io.open(file_name, "r")
	if not file then
		Log.warn("PeerMgr:load_peer_list peer data not exists")
		return
	end

	local str = file:read("*all")
	Log.debug("PeerMgr:load_peer_list str=%s", str)
	file:close()
	local peer_list = Util.unserialize(str)
	if type(peer_list) ~= "table" then
		Log.warn("PeerMgr:load_peer_list peer_list error")
		return
	end

	for _, v in ipairs(peer_list) do
		table.insert(self._register_peer_list,
		{
			mailbox_id = MAILBOX_ID_NIL,
			server_id = v.server_id,
			server_type = ServerType.NULL,
			single_scene_list = {},
			from_to_scene_list = {},
			ip = "",
			port = 0,
		})
	end

end

function PeerMgr:print()
	Log.info("\n####### PeerMgr:print #######")
	for k, v in ipairs(self._register_peer_list) do
		Log.info("[%d] mailbox_id=%d server_id=%d server_type=[%d:%s] single_scene_list=[%s] from_to_scene_list=[%s] ip=%s port=%d"
		, k, v.mailbox_id, v.server_id, v.server_type, ServerTypeName[v.server_type]
		, table.concat(v.single_scene_list, ","), table.concat(v.from_to_scene_list, ","), v.ip, v.port)
	end
	Log.info("#######\n")
end

return PeerMgr
