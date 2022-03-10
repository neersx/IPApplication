namespace InprotechKaizen.Model.Components.Cases
{
    public class ExternalRenewalStatusListItem
    {
        public int StatusKey { get; set; }

        public string StatusDescription { get; set; }

        public bool? LiveFlag { get; set; }

        public bool? RegisteredFlag { get; set; }
    }
}