using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;

namespace Inprotech.Web.Messaging
{
    [HubName("messageBroker")]
    public class ClientMessageBrokerHub : Hub
    {
        readonly IClientSubscriptions _clientSubscriptions;
        readonly IBus _bus;
        readonly IBackgroundProcessLogger<ClientMessageBrokerHub> _logger;

        public ClientMessageBrokerHub(IClientSubscriptions clientSubscriptions, IBus bus, IBackgroundProcessLogger<ClientMessageBrokerHub> logger)
        {
            _clientSubscriptions = clientSubscriptions;
            _bus = bus;
            _logger = logger;
        }

        public override Task OnConnected()
        {
            Subscribe();

            return base.OnConnected();
        }

        public override Task OnReconnected()
        {
            Subscribe();

            return base.OnReconnected();
        }

        public override Task OnDisconnected(bool stopCalled)
        {
            var connectionId = Context.ConnectionId;

            _clientSubscriptions.Remove(connectionId);
            Publish(new ChannelDisconnectedMessage { ConnectionId = connectionId });

            return base.OnDisconnected(stopCalled);
        }

        void Subscribe()
        {
            var connectionId = Context.ConnectionId;
            var bindings = GetBindings();

            _clientSubscriptions.Add(connectionId, bindings);
            Publish(new ChannelConnectedMessage { ConnectionId = connectionId, Bindings = bindings });
        }

        string[] GetBindings()
        {
            return Context.Request.QueryString["bindings"].Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        }

        void Publish(Message message)
        {
            try
            {
                _bus.Publish(message);
            }
            catch (Exception e)
            {
                _logger.Exception(e);
            }
        }
    }
}