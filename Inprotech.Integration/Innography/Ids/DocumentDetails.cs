using System.Collections.Generic;
using System.Collections.ObjectModel;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.Ids
{
    public class DocumentDetails
    {
        [JsonProperty("ip_type")]
        public string IpType { get; set; }

        [JsonProperty("document_type")]
        public string DocumentType { get; set; }

        [JsonProperty("ipid")]
        public string IpId { get; set; }
        
        [JsonProperty("title")]
        public string Title { get; set; }

        [JsonProperty("country_code")]
        public string CountryCode { get; set; }

        [JsonProperty("number")]
        public string Number { get; set; }
        
        [JsonProperty("kind_code")]
        public string KindCode { get; set; }

        [JsonProperty("date")]
        public string Date { get; set; }

        [JsonProperty("application_number")]
        public string ApplicationNumber { get; set; }

        [JsonProperty("application_date")]
        public string ApplicationDate { get; set; }

        [JsonProperty("patent_body")]
        public string Abstract { get; set; }
        
        [JsonProperty("applicant")]
        [JsonConverter(typeof(SingleOrArrayConverter<string>))]
        public string[] Applicant { get; set; }

        [JsonProperty("current_owner")]
        [JsonConverter(typeof(SingleOrArrayConverter<string>))]
        public string[] CurrentOwner { get; set; }

        [JsonProperty("inventors")]
        [JsonConverter(typeof(SingleOrArrayConverter<string>))]
        public string[] Inventor { get; set; }

        [JsonProperty("ipcr_classification")]
        public IEnumerable<IpcrClassification> IpcrClassification { get; set; }

        [JsonProperty("innography_link")]
        public string InnographyLink { get; set; }

        public DocumentDetails()
        {
            IpcrClassification = new Collection<IpcrClassification>();
        }
    }
}