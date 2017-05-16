#include "logger.h"
#include "pluto.h"
#include "net_service.h"
#include "luanetwork.h"

LuaNetwork* LuaNetwork::Instance()
{
	static LuaNetwork *instance = new LuaNetwork();
	return instance;
}

/*
bool LuaNetwork::connect_to(const char* ip, int port, unsigned& out_session_id)
{
	out_session_id = INT_MAX;

	if (Engine::Net* net = NetMgr::get_single_instance()->get_default_net()){
		return net->connect_to(ip, port, out_session_id);
	}

	return false;
}
*/

/*
LuaNetwork::LuaNetwork()
	:_recv_data(_nullptr)
	, _recv_data_len(0)
	, _recv_msg_id(0)
	, _recv_session_id(INT_MAX)
	, _cur_read_data_len(0)
	, _send_data_buff_len(MSG_MIN_LEN)
	, _send_data_buff_msg_id(-1)
	,_recv_addition(0)
{
	memset(_send_data_buff, 0, sizeof(_send_data_buff));
}
*/

LuaNetwork::LuaNetwork() : m_recvPluto(nullptr), m_sendPluto(nullptr)
{
	m_sendPluto = new Pluto(MSGLEN_MAX);
}

LuaNetwork::~LuaNetwork()
{
	delete m_sendPluto;
}


void LuaNetwork::initSendPluto()
{
	m_sendPluto->ResetCursor();
}

void LuaNetwork::WriteMsgId(int msgId)
{
	m_sendPluto->WriteMsgId(msgId);
}

bool LuaNetwork::WriteByte(char val)
{
	return m_sendPluto->WriteByte(val);
}

bool LuaNetwork::WriteInt(int val)
{
	return m_sendPluto->WriteInt(val);
}

bool LuaNetwork::WriteFloat(float val)
{
	return m_sendPluto->WriteFloat(val);
}

bool LuaNetwork::WriteBool(bool val)
{
	return m_sendPluto->WriteBool(val);
}

bool LuaNetwork::WriteShort(short val)
{
	return m_sendPluto->WriteShort(val);
}

bool LuaNetwork::WriteInt64(int64_t val)
{
	return m_sendPluto->WriteInt64(val);
}

bool LuaNetwork::WriteString(int len, const char* str)
{
	return m_sendPluto->WriteString(len, str);
}

bool LuaNetwork::Send(int mailboxId)
{
	Mailbox *pmb = m_net->GetMailbox(mailboxId);
	if (!pmb)
	{
		LOG_WARN("mail box null %d", mailboxId);
		return false;
	}

	// TODO check pluto size


	m_sendPluto->SetMsgLen();
	Pluto *pu = m_sendPluto->Clone();
	pu->SetMsgLen(m_sendPluto->GetMsgLen());
	pu->SetMailbox(pmb);
	pmb->PushPluto(pu);

	m_sendPluto->ResetCursor();

	return true;
}

void LuaNetwork::SetRecvPluto(Pluto *pu)
{
	m_recvPluto = pu;
}

int LuaNetwork::ReadMsgId()
{
	return m_recvPluto->ReadMsgId();
}

bool LuaNetwork::ReadByte(char &out_val)
{
	return m_recvPluto->ReadByte(out_val);
}

bool LuaNetwork::ReadInt(int &out_val)
{
	return m_recvPluto->ReadInt(out_val);
}

bool LuaNetwork::ReadFloat(float &out_val)
{
	return m_recvPluto->ReadFloat(out_val);
}

bool LuaNetwork::ReadBool(bool &out_val)
{
	return m_recvPluto->ReadBool(out_val);
}

bool LuaNetwork::ReadShort(short &out_val)
{
	return m_recvPluto->ReadShort(out_val);
}

bool LuaNetwork::ReadInt64(int64_t &out_val)
{
	return m_recvPluto->ReadInt64(out_val);
}

bool LuaNetwork::ReadString(int &out_len, char *out_val)
{
	return m_recvPluto->ReadString(out_len, out_val);
}

void LuaNetwork::CloseSocket(int mailboxId)
{
	// Engine::SessionMgr::get_single_instance()->close_session(session_id);
}
