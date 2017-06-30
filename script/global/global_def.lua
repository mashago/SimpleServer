
ServerType =
{
	NULL 			= 0,
	ROUTER 			= 1,
	SCENE 			= 2,
	DB 				= 3,
	BRIDGE 			= 4,
	LOGIN 			= 5,
	PUBLIC 			= 6,
	CROSS 			= 7,
	PAY 			= 8,
	CHAT 			= 9,
}

ConnType =
{
	NULL 	= 0,
	UNTRUST = 1,
	TRUST 	= 2,
}

ErrorCode =
{
	SUCCESS 						= 1,
	SYS_ERROR 						= 2,

	USER_LOGIN_FAIL 				= 3,
	USER_LOGIN_PASSWORD_MISMATCH 	= 4,
	USER_LOGIN_DUPLICATE_LOGIN 		= 5,
	CREATE_ROLE_FAIL 				= 6,

	REGISTER_SERVER_FAIL 			= 600001,
	REGISTER_SERVER_UNTRUST 		= 600002,
	RPC_FAIL 						= 600003,
	REGISTER_AREA_DUPLICATE			= 600004,
}

