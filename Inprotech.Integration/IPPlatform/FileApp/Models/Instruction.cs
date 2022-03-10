using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class Instruction
    {
        public string CountryCode { get; set; }

        [JsonProperty("agent")]
        public string AgentId { get; set; }

        public string AgentRef { get; set; }

        public string ApplicationNo { get; set; }

        public string ClientRef { get; set; }

        public string AcknowledgeDate { get; set; }

        public string CompletedDate { get; set; }

        public string DeadlineDate { get; set; }

        public string EmailAddresses { get; set; }

        public string FilingDate { get; set; }

        public string FilingReceiptReceivedDate { get; set; }

        public string PassedToAgentDate { get; set; }

        public string ReceivedDate { get; set; }

        public string RequestedFilingDate { get; set; }

        public string SentToPtoDate { get; set; }

        public string Status { get; set; }

        public ICollection<Link> Links { get; set; }
    }
}