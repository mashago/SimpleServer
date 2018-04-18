
function send_to_login(msg_id, msg)
	g_service_mgr:send_to_type_server(ServerType.LOGIN, msg_id, msg)
end

function send_to_gate(msg_id, msg)
	g_service_mgr:send_to_type_server(ServerType.GATE, msg_id, msg)
end

------------------------------------------------

g_x_test_num = g_x_test_num or -1 -- x test end
g_x_test_total_num = g_x_test_total_num or 0
g_x_test_start_time = g_x_test_start_time or 0
g_x_test_total_time = g_x_test_total_time or 0
g_x_test_min_time = g_x_test_min_time or 0

function x_test_start(num)
	g_x_test_num = num
	g_x_test_total_num = num
	g_x_test_start_time = get_time_ms_c()
	g_x_test_total_time = 0
	g_x_test_min_time = 0
end

function x_test_end()
	local time_ms = get_time_ms_c()
	if g_x_test_num > 0 then
		g_x_test_num = g_x_test_num - 1
		local time_ms_offset = time_ms - g_x_test_start_time
		g_x_test_total_time = g_x_test_total_time + time_ms_offset
		if g_x_test_min_time == 0 then
			g_x_test_min_time = time_ms_offset
		end
	end
	if g_x_test_num == 0 then
		Log.debug("******* x test time use time=%fms", time_ms - g_x_test_start_time)
		Log.debug("******* g_x_test_total_num=%d", g_x_test_total_num)
		Log.debug("******* g_x_test_total_time=%fms", g_x_test_total_time)
		Log.debug("******* average time=%fms", g_x_test_total_time/ g_x_test_total_num)
		Log.debug("******* min time=%fms", g_x_test_min_time)
		g_x_test_num = -1  -- x test end
	end
end

------------------------------------------------

function g_msg_handler.s2c_rpc_test_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_rpc_test_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_rpc_test_ret: result=%s", ErrorCodeText[data.result])
	end
	x_test_end()
end

function g_msg_handler.s2c_user_login_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_user_login_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_user_login_ret: result=%s", ErrorCodeText[data.result])
	end
	x_test_end()
end

function g_msg_handler.s2c_area_list_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_area_list_ret: data=%s", Util.table_to_string(data))

	g_time_counter:print()
end

function g_msg_handler.s2c_role_list_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_list_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_role_list_ret: result=%s", ErrorCodeText[data.result])
	end

	g_client._area_role_list = data.area_role_list
	g_time_counter:print()
end

function g_msg_handler.s2c_create_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_create_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_create_role_ret: result=%s", ErrorCodeText[data.result])
	end

	g_time_counter:print()
end

function g_msg_handler.s2c_delete_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_delete_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_delete_role_ret: result=%s", ErrorCodeText[data.result])
	end

	g_time_counter:print()
end

function g_msg_handler.s2c_select_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_select_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_select_role_ret: result=%s", ErrorCodeText[data.result])
		return
	end

	g_client._server_list[ServerType.GATE] =
	{
		ip = data.ip,
		port = data.port,
		server_id = 1, -- no same with login is ok
	}

	g_client._user_id = data.user_id
	g_client._user_token = data.token

	g_time_counter:print()
end

function g_msg_handler.s2c_role_enter_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_enter_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_role_enter_ret: result=%s", ErrorCodeText[data.result])
	end

	g_time_counter:print()
end

function g_msg_handler.s2c_role_attr_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_attr_ret: data=%s", Util.table_to_string(data))

	local role_id = data.role_id
	local attr_table = data.attr_table

	local Role = require "client.role"
	g_role = Role.new(role_id)
	g_role:init_data(attr_table)
	g_role:print()
end

function g_msg_handler.s2c_role_attr_change_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_attr_change_ret: data=%s", Util.table_to_string(data))
	
	local attr_table = data.attr_table
	if g_role then
		g_role:update_data(attr_table)
		g_role:print()
	end
end

function g_msg_handler.s2c_attr_info_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_info_ret: data=%s", Util.table_to_string(data))

	local sheet_name = data.sheet_name
	if sheet_name == "role_info" then
		if not g_role then
			local Role = require "client.role"
			g_role = Role.new()
		end
		g_role:init_data(data.rows[1])
		g_role:print()
	end
end

function g_msg_handler.s2c_attr_insert_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_insert_ret: data=%s", Util.table_to_string(data))
end

function g_msg_handler.s2c_attr_delete_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_delete_ret: data=%s", Util.table_to_string(data))
end

function g_msg_handler.s2c_attr_modify_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_modify_ret: data=%s", Util.table_to_string(data))

	local sheet_name = data.sheet_name
	if sheet_name == "role_info" then
		if not g_role then
			return
		end
		g_role:update_data(data.rows[1].attrs)
		g_role:print()
	end
end

function g_msg_handler.s2c_role_kick(data, mailbox_id, msg_id)
	g_service_mgr:close_connection_by_type(ServerType.LOGIN, true)
	g_service_mgr:close_connection_by_type(ServerType.GATE, true)
end
