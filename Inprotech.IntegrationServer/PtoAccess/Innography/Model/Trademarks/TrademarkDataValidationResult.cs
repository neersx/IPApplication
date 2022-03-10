using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks
{
    public class TrademarkDataValidationResult
    {
        [JsonProperty(PropertyName = "ipid")]
        public string IpId { get; set; }

        [JsonProperty(PropertyName = "client_index")]
        public string ClientIndex { get; set; }

        [JsonProperty(PropertyName = "match")]
        public string Match { get; set; }

        [JsonProperty(PropertyName = "application_number")]
        public MatchingFieldData ApplicationNumber { get; set; }

        [JsonProperty(PropertyName = "application_date")]
        public MatchingFieldData ApplicationDate { get; set; }

        [JsonProperty(PropertyName = "publication_number")]
        public MatchingFieldData PublicationNumber { get; set; }

        [JsonProperty(PropertyName = "publication_date")]
        public MatchingFieldData PublicationDate { get; set; }

        [JsonProperty(PropertyName = "registration_number")]
        public MatchingFieldData RegistrationNumber { get; set; }

        [JsonProperty(PropertyName = "registration_date")]
        public MatchingFieldData RegistrationDate { get; set; }

        [JsonProperty(PropertyName = "mark_type")]
        public MatchingFieldData MarkType { get; set; }
        
        [JsonProperty(PropertyName = "mark")]
        public MatchingFieldData Mark { get; set; }

        [JsonProperty(PropertyName = "owner")]
        public MatchingFieldData Owner { get; set; }

        [JsonProperty(PropertyName = "status")]
        public MatchingFieldData Status { get; set; }
        
        [JsonProperty(PropertyName = "expiration_date")]
        public MatchingFieldData ExpirationDate { get; set; }
        
        [JsonProperty(PropertyName = "termination_date")]
        public MatchingFieldData TerminationDate { get; set; }
        
        [JsonProperty(PropertyName = "priority_number")]
        public MatchingFieldData PriorityNumber { get; set; }
        
        [JsonProperty(PropertyName = "priority_date")]
        public MatchingFieldData PriorityDate { get; set; }

        [JsonProperty(PropertyName = "priority_country")]
        public MatchingFieldData PriorityCountry { get; set; }

        [JsonProperty(PropertyName = "goods_services_nice")]
        public GoodsServicesNiceMatch[] GoodsServicesNice { get; set; }

        [JsonProperty(PropertyName = "application_language_code")]
        public MatchingFieldData ApplicationLanguageCode { get; set; }
    }

    public class GoodsServicesNiceMatch
    {
        [JsonProperty("class_code")]
        public MatchingFieldData ClassCode { get; set; }

        [JsonProperty("goods_description")]
        public MatchingFieldData GoodsDescription { get; set; }

        [JsonProperty("language_code")]
        public MatchingFieldData LanguageCode { get; set; }
    }

    public static class TrademarkValidationExtensions
    {
        public static bool IsHighConfidenceMatch(this TrademarkDataValidationResult validationResult)
        {
            foreach(var prop in validationResult.GetType().GetProperties())
            {
                if (prop.PropertyType.FullName == typeof(MatchingFieldData).FullName)
                {
                    if (prop.GetValue(validationResult) is MatchingFieldData propValue && (propValue.StatusCode == TrademarkValidationStatusCodes.PublicDataNotMatchesUserData
                                                                                           || propValue.StatusCode == TrademarkValidationStatusCodes.UserDataNotProvided))
                        return false;
                }
            }

            return true;
        }
    }

    public static class TrademarkValidationStatusCodes
    {
        public const string PublicDataMatchesUserData = "10";
        public const string NeitherPublicOrUserDataAvailable = "11";
        public const string PublicDataNotMatchesUserData = "20";
        public const string PublicDataNotAvailable = "21";
        public const string UserDataNotProvided = "22";
    }
}
