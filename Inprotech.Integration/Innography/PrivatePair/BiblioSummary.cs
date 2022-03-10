using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class BiblioSummary
    {
        [JsonProperty("appid")]
        public string AppId { get; set; }

        [JsonProperty("attorney_docket_number")]
        public string AttorneyDocketNumber { get; set; }

        [JsonProperty("app_number")]
        public string AppNumber { get; set; }

        [JsonProperty("class_sub")]
        public string ClassAndSubClass { get; set; }

        [JsonProperty("confirmation_number")]
        public string ConfirmationNumber { get; set; }

        [JsonProperty("customer_number")]
        public string CustomerNumber { get; set; }

        [JsonProperty("earliest_pub_no")]
        public string PublicationNumber { get; set; }

        [JsonProperty("earliest_pub_date")]
        public string PublicationDate { get; set; }

        [JsonProperty("examiner_name")]
        public string ExaminerName { get; set; }

        [JsonProperty("filing_371")]
        public string FilingDate371 { get; set; }

        [JsonProperty("group_art_unit")]
        public string GroupArtUnit { get; set; }

        [JsonProperty("issue_date")]
        public string IssueDate { get; set; }

        [JsonProperty("first_inventor")]
        public string Inventor { get; set; }

        [JsonProperty("patent_number")]
        public string PatentNumber { get; set; }

        [JsonProperty("status")]
        public string StatusDescription { get; set; }

        [JsonProperty("status_date")]
        public string StatusDate { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; }
    }
}