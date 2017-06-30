
function send_to_login(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.LOGIN, msg_id, ...)
end

function send_to_router(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.ROUTER, msg_id, ...)
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	if g_loginx_num > 0 then
		g_loginx_num = g_loginx_num - 1
	end
	if g_loginx_num == 0 then
		Log.debug("******* loginx time use time=%d", os.time() - g_loginx_start_time)
	end
end

local function handle_area_list_ret(data, mailbox_id, msg_id)
	Log.debug("handle_area_list_ret: data=%s", Util.TableToString(data))
end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))
end

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.TableToString(data))
end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_RET, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_RET, handle_area_list_ret)
	Net.add_msg_handler(MID.CREATE_ROLE_RET, handle_create_role)
	Net.add_msg_handler(MID.RPC_TEST_RET, handle_rpc_test)
end
