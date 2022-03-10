namespace Inprotech.Contracts.Messages.Channel
{
    public class ChannelConnectedMessage : Message
    {
        public string[] Bindings;
        public string ConnectionId;
    }
}