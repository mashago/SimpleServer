
local Log = require "core.log.logger"
local Util = require "core.util.util"
-- NOTE:
-- 1. should set by coder handly
-- 2. field position will be random, you have to accept this
-- 3. if default is '_Null' means no default value
-- 4. if key=1, will set a index for the field

DataStructDef = {}
DataStructDef.data = {}
DataStructDef.func = {}

DataStructDef.data.role_info = 
{
	[1] = {id=1, field='role_id', type=_Int64, default='_Null', save=1, sync=1, key=1},
	[2] = {id=2, field='role_name', type=_String, default='_Null', save=1, sync=1},
	[3] = {id=3, field='user_id', type=_Int64, default='_Null', save=1, sync=1},
	[4] = {id=4, field='channel_id', type=_Int, default='_Null', save=1, sync=1},
	[5] = {id=5, field='area_id', type=_Int, default='_Null', save=1, sync=1},
	[6] = {id=6, field='server_id', type=_Int, default='0', save=1, sync=0},
	[7] = {id=7, field='is_delete', type=_Bool, default='0', save=1, sync=0},
	[8] = {id=8, field='lv', type=_Int, default='1', save=1, sync=1},
	[9] = {id=9, field='exp', type=_Int, default='0', save=1, sync=1},
	[10] = {id=10, field='scene_id', type=_Int, default='1', save=1, sync=1},
	[11] = {id=11, field='pos_x', type=_Int, default='0', save=1, sync=1},
	[12] = {id=12, field='pos_y', type=_Int, default='0', save=1, sync=1},
	[13] = {id=13, field='cur_hp', type=_Int, default='0', save=0, sync=1},

	[14] = {id=14, field='attr_byte', type=_Byte, default='0', save=1, sync=1},
	[15] = {id=15, field='attr_bool', type=_Bool, default='1', save=1, sync=1},
	[16] = {id=16, field='attr_int', type=_Int, default='0', save=1, sync=1},
	[17] = {id=17, field='attr_float', type=_Float, default='0', save=1, sync=1},
	[18] = {id=18, field='attr_short', type=_Short, default='0', save=1, sync=1},
	[19] = {id=19, field='attr_int64', type=_Int64, default='0', save=1, sync=1},
	[20] = {id=20, field='attr_string', type=_String, default='', save=1, sync=1},
	[21] = {id=21, field='attr_struct', type=_Struct, default='_Null', save=1, sync=1},
}

-- FOR TEST
DataStructDef.data.test_role = 
{
	[1] = {id=1, field='role_id', type=_Int64, default='_Null', save=1, sync=1, key=1},
	[2] = {id=2, field='sync_attr', type=_Int, default='0', save=0, sync=1},
	[3] = {id=3, field='save_attr', type=_Int, default='0', save=1, sync=0},
	[4] = {id=4, field='sync_save_attr', type=_Int, default='0', save=1, sync=1},
	[5] = {id=5, field='tmp_attr', type=_Int, default='0', save=0, sync=0},
}

DataStructDef.data.test_bag = 
{
	[1] = {id=1, field='role_id', type=_Int64, default='_Null', save=1, sync=1, key=1},
	[2] = {id=2, field='item_id', type=_Int, default='_Null', save=1, sync=1, key=2},
	[3] = {id=3, field='num', type=_Int, default='0', save=1, sync=1},
	[4] = {id=4, field='sync_attr', type=_Int, default='0', save=0, sync=1},
	[5] = {id=5, field='save_attr', type=_Int, default='0', save=1, sync=0},
	[6] = {id=6, field='sync_save_attr', type=_Int, default='0', save=1, sync=1},
	[7] = {id=7, field='tmp_attr', type=_Int, default='0', save=0, sync=0},
}

function DataStructDef.func.init_cfg()
	for table_name, table_def in pairs(DataStructDef.data) do
		for k, field_def in ipairs(table_def) do
			table_def[field_def.field] = field_def
		end
	end
end

DataStructDef.func.init_cfg()

function DataStructDef.func.convert_type_str2mem(table_name, field_name, value)
	local table_def = DataStructDef.data[table_name]
	if not table_def then
		return nil
	end

	local field_def = table_def[field_name]
	if not field_def then
		return nil
	end

	local field_type = field_def.type
	-- type cast
	if field_type == _String then
		return value
	end

	if field_type == _Bool then
		return value == "1"
	end

	if field_type == _Byte or field_type == _Int
	or field_type == _Float or field_type == _Short
	or field_type == _Int64 then
		return tonumber(value)
	end

	if field_type == _Struct then
		return Util.unserialize(value)
	end

	Log.warn("DataStructDef.convert_type_str2mem unknow type table_name=%s field_name=%s field_type=%d", field_type)
	return nil

end

return DataStructDef
