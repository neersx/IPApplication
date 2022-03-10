using System;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Models
{
    public class RelatedCase
    {
        public string RelationshipCode { get; set; }

        public string Description { get; set; }

        public string CountryCode { get; set; }

        public string OfficialNumber { get; set; }

        public DateTime? EventDate { get; set; }

        public string Status { get; set; }

        public string RegistrationNumber { get; set; }
    }

    public class VerifiedRelatedCase : RelatedCase
    {
        public bool CountryCodeVerified { get; set; }

        public bool OfficialNumberVerified { get; set; }

        public bool EventDateVerified { get; set; }

        public string InputCountryCode { get; set; }

        public string InputOfficialNumber { get; set; }

        public DateTime? InputEventDate { get; set; }
    }
}
