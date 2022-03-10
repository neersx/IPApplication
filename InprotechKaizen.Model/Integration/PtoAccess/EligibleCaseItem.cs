using System.ComponentModel.DataAnnotations;

namespace InprotechKaizen.Model.Integration.PtoAccess
{
    public class EligibleCaseItem
    {
        [Key]
        public int CaseKey { get; set; }

        public string ApplicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public string SystemCode { get; set; }

        public string CountryCode { get; set; }

        public bool IsLiveCase { get; set; }

        public string PropertyType { get; set; }
    }
}