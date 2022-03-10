using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Account
    {
        [JsonProperty("account_id")]
        public string AccountId { get; set; }

        [JsonProperty("account_secret")]
        public string AccountSecret { get; set; }

        [JsonProperty("queue_access_id")]
        public string QueueAccessId { get; set; }

        [JsonProperty("queue_access_secret")]
        public string QueueAccessSecret { get; set; }

        [JsonProperty("queue_url")]
        public string QueueUrl { get; set; }

        [JsonProperty("sqs_region")]
        public string SqsRegion { get; set; }

        [JsonIgnore]
        public bool IsValid => !string.IsNullOrWhiteSpace(AccountId) &&
                               !string.IsNullOrWhiteSpace(AccountSecret) &&
                               !string.IsNullOrWhiteSpace(QueueAccessId) &&
                               !string.IsNullOrWhiteSpace(QueueAccessSecret) &&
                               !string.IsNullOrWhiteSpace(SqsRegion);
    }
}