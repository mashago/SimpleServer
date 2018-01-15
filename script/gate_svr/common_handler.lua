
local CommonHandler = class()

function CommonHandler:ctor()
	self._sync_conn_num_timer_index = 0
end

function CommonHandler:sync_conn_num()
	local rpc_data =
	{
		num = 0
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.BRIDGE, "bridge_sync_gate_conn_num", rpc_data)
end

function CommonHandler:add_sync_conn_num_timer()
	if self._sync_conn_num_timer_index > 0 then
		return
	end

	local timer_interval_ms = 5 * 1000
	local timer_cb = function()
		self:sync_conn_num()
	end

	self._sync_conn_num_timer_index = g_timer:add_timer(timer_interval_ms, timer_cb, 0, true)

end

function CommonHandler:del_sync_conn_num_timer()
	if self._sync_conn_num_timer_index == 0 then
		return
	end

	g_timer:del_timer(self._sync_conn_num_timer_index)
	self._sync_conn_num_timer_index = 0
end

return CommonHandler
