#pragma once

// class IStreamChannel start
#define FUNC_STREAMCHANNEL_JOIN "StreamChannel_join"
#define FUNC_STREAMCHANNEL_LEAVE "StreamChannel_leave"
#define FUNC_STREAMCHANNEL_GETCHANNELNAME "StreamChannel_getChannelName"
#define FUNC_STREAMCHANNEL_JOINTOPIC "StreamChannel_joinTopic"
#define FUNC_STREAMCHANNEL_PUBLISHTOPICMESSAGE                                 \
  "StreamChannel_publishTopicMessage"
#define FUNC_STREAMCHANNEL_LEAVETOPIC "StreamChannel_leaveTopic"
#define FUNC_STREAMCHANNEL_SUBSCRIBETOPIC "StreamChannel_subscribeTopic"
#define FUNC_STREAMCHANNEL_UNSUBSCRIBETOPIC "StreamChannel_unsubscribeTopic"
#define FUNC_STREAMCHANNEL_GETSUBSCRIBEDUSERLIST                               \
  "StreamChannel_getSubscribedUserList"
#define FUNC_STREAMCHANNEL_RELEASE "StreamChannel_release"
// class IStreamChannel end

// class IRtmClient start
#define FUNC_RTMCLIENT_INITIALIZE "RtmClient_initialize"
#define FUNC_RTMCLIENT_RELEASE "RtmClient_release"
#define FUNC_RTMCLIENT_CREATESTREAMCHANNEL "RtmClient_createStreamChannel"
#define FUNC_RTMCLIENT_RELEASESTREAMCHANNEL "RtmClient_releaseStreamChannel"
#define FUNC_RTMCLIENT_SETEVENTHANDLER "RtmClient_setEventHandler"
// class IRtmClient end