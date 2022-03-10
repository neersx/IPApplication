using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.Integration.ExchangeIntegration
{
    public class GraphMessage
    {
        public int UserId { get; set; }

        public string Scope { get; set; }

        public int BackgroundProcessId { get; set; }

        public string CallBackUrl { get; set; }

        public ExchangeGraph GraphSettings { get; set; }

        public string ConnectionId { get; set; }
    }
}
