using System;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class IpIdResult
    {
        [JsonProperty(PropertyName = "ipid")]
        public string IpId { get; set; }

        [JsonProperty(PropertyName = "message")]
        public string Message { get; set; }

        [JsonProperty(PropertyName = "validation")]
        public string[] Validation { get; set; }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "public_data")]
        public PatentData PublicData { get; set; }

        [JsonProperty(PropertyName = "confidence")]
        public string Confidence { get; set; }
    }

    public static class IdsResultExtension
    {
        public static bool IsHighConfidenceMatch(this IpIdResult result)
        {
            return result.Matched("high");
        }

        public static bool Matched(this IpIdResult result, string confidence)
        {
            if (result == null)
            {
                return false;
            }

            return result.Message.StartsWith("Matched", StringComparison.InvariantCultureIgnoreCase) &&
                   string.Compare(result.Confidence, confidence, StringComparison.InvariantCultureIgnoreCase) == 0;
        }

        public static bool HasInvalidInnographyId(this IpIdResult result)
        {
            return string.IsNullOrWhiteSpace(result?.IpId) || result.IpId?.Trim() == "0";
        }
    }
}