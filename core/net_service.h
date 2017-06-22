
#pragma once

extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <time.h>
#include <errno.h>

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}

#include <string>
#include <set>
#include <map>
#include <list>
#include "mailbox.h"
#include "world.h"


class NetService
{

public:
	NetService();
	virtual ~NetService();

	int Init(const char *addr, unsigned int port, std::set<std::string> &trustIpSet);
	int Service();
	// return >= 0 as mailboxId, < 0 as error
	int64_t ConnectTo(const char *addr, unsigned int port);

	Mailbox *GetMailboxByFd(int fd);
	Mailbox *GetMailboxByMailboxId(int64_t mailboxId);
	void SetWorld(World *world);
	World *GetWorld();

	virtual int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);

	virtual int HandleSocketReadEvent(struct bufferevent *bev);
	virtual int HandleSocketReadMessage(struct bufferevent *bev);
	virtual void AddRecvMsg(Pluto *u);

	virtual int HandleSocketConnected(evutil_socket_t fd);
	virtual int HandleSocketClosed(evutil_socket_t fd);
	virtual int HandleSocketError(evutil_socket_t fd);

	virtual int HandleTickEvent();
	virtual int HandleRecvPluto();
	virtual int HandleSendPluto();

	void CloseMailbox(int fd);
	void CloseMailbox(int64_t mailboxId);

private:
	bool Listen(const char *addr, unsigned int port);
	Mailbox * NewMailbox(int fd, E_CONN_TYPE type);
	void CloseMailbox(Mailbox *pmb);

	struct event_base *m_mainEvent;
	struct event *m_tickEvent;
	struct event *m_timerEvent;
	struct event *m_stdinEvent;
	struct evconnlistener *m_evconnlistener;

	std::map<int, Mailbox *> m_fds;
	std::map<int64_t, Mailbox *> m_mailboxs;
	std::list<Mailbox *> m_mb4del;
	std::list<Pluto *> m_recvMsgs;
	std::set<std::string> m_trustIpSet;
	World *m_world;
};
