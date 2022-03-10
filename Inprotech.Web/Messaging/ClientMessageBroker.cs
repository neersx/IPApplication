using System;
using System.Linq;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.System.Messages;
using Microsoft.AspNet.SignalR;

namespace Inprotech.Web.Messaging
{
    public interface IClientMessageBroker
    {        
        void Publish(string topic, object data);
    }

    public class ClientMessageBroker : IClientMessageBroker, IHandle<BroadcastMessageToClient>, IHandle<SendMessageToClient>
    {
        readonly IClientSubscriptions _clientSubscriptions;

        public ClientMessageBroker(IClientSubscriptions clientSubscriptions)
        {
            if (clientSubscriptions == null) throw new ArgumentNullException("clientSubscriptions");
            _clientSubscriptions = clientSubscriptions;
        }

        public void Publish(string topic, object data)
        {
            var recipients = _clientSubscriptions.Find(topic, (a, b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
                                           .ToArray();

            if (recipients.Length == 0) return;

            GlobalHost.ConnectionManager.GetHubContext<ClientMessageBrokerHub>().Clients.Clients(recipients).receive(topic, data);
        }

        public void Publish(string topic, object data, string connectionId)
        {
            if (string.IsNullOrEmpty(connectionId) || string.IsNullOrEmpty(topic)) return;

            GlobalHost.ConnectionManager.GetHubContext<ClientMessageBrokerHub>().Clients.Client(connectionId).receive(topic, data);
        }

        public void Handle(BroadcastMessageToClient message)
        {
            Publish(message.Topic, message.Data);
        }

        public void Handle(SendMessageToClient message)
        {
            Publish(message.Topic, message.Data, message.ConnectionId);
        }
    }
}