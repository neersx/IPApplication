using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.System.Messages
{
    public class BroadcastMessageToClient : Message
    {
        public string Topic { get; set; }
        public object Data { get; set; }
    }

    public class SendMessageToClient : Message
    {
        public string ConnectionId { get; set; }
        public string Topic { get; set; }
        public object Data { get; set; }
    }
}