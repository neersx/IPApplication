using System;
using Microsoft.AspNet.SignalR;
using Newtonsoft.Json;
using NLog;

namespace Demogod
{
    public static class EventStream
    {
        public static void Publish(string message)
        {
            var hub = GlobalHost.ConnectionManager.GetHubContext("MessageHub");

            hub.Clients.All.publish(message);
        }

        public static void Publish(Exception exception)
        {
            LogManager.GetLogger("EventStream").Error(exception);

            var message = JsonConvert.SerializeObject(exception, Formatting.Indented);
            Publish(message);
        }
    }
}