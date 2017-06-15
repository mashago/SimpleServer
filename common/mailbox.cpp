
extern "C"
{
#include <stddef.h>
#include <string.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}
#include "logger.h"
#include "util.h"
#include "mailbox.h"

Mailbox::Mailbox(E_CONN_TYPE type) : m_fdType(type), m_pluto(nullptr), m_bev(nullptr), m_bDeleteFlag(false), m_sendPos(0)
{
}

Mailbox::~Mailbox()
{
	// delete recv pluto
	if (m_pluto)
	{
		delete m_pluto;
	}

	// delete send pluto
	ClearContainer(m_tobeSend);
}

void Mailbox::PushPluto(Pluto *u)
{
	m_tobeSend.push_back(u);
}

int Mailbox::SendAll()
{
	// LOG_DEBUG("m_tobeSend.size=%d", m_tobeSend.size());

	if (!m_bev)
	{
		return 0;
	}

	if (m_tobeSend.empty())
	{
		return 0;
	}

	struct evbuffer *output = bufferevent_get_output(m_bev);
	while (!m_tobeSend.empty())
	{
		// send pluto
		Pluto *u = m_tobeSend.front();
		int nSendWant = u->GetMsgLen() - m_sendPos;

		struct evbuffer_iovec v[1]; // the vector struct to access evbuffer directly, without memory copy
		// reserve space
		int res = evbuffer_reserve_space(output, nSendWant, v, 1);
		const size_t iov_len = v[0].iov_len; // iov_len may not equal to reserve num
		if (res <= 0 || iov_len == 0)
		{
			LOG_ERROR("evbuffer_reserve_space fail m_fd=%d nSendWant=%d res=%d", m_fd, nSendWant, res);
			return 0;
		}

		// reset iov_len to send buffer size, and copy buffer to iov
		char *buffer = (char *)v[0].iov_base;
		int nSendCan = nSendWant <= (int)iov_len ? nSendWant : iov_len;
		memcpy(buffer, u->GetBuffer()+m_sendPos, nSendCan);
		v[0].iov_len = nSendCan;

		// commit space
		if (evbuffer_commit_space(output, v, 1) != 0)
		{
			LOG_ERROR("evbuffer_commit_space fail m_fd=%d", m_fd);
			return -1;
		}

		// check if all data send
		if (nSendCan != nSendWant)
		{
			// still has data in pluto 
			// send block, do it later
			// update send pos
			m_sendPos += nSendCan;
			return 0;
		}

		// pluto send done, do clean
		m_sendPos = 0;
		m_tobeSend.pop_front();
		delete u;
	}

	return 0;
}
