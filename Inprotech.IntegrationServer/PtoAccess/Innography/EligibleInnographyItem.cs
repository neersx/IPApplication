using System;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public class EligibleInnographyItem : EligibleCaseItem
    {
        public string IpId { get; set; }

        public string TypeCode { get; set; }

        public DateTime? ApplicationDate { get; set; }

        public DateTime? RegistrationDate { get; set; }

        public DateTime? PublicationDate { get; set; }
        
        public string PctCountry { get; set; }
        
        public string PctNumber { get; set; }

        public DateTime? PctDate { get; set; }

        public string PriorityCountry { get; set; }

        public string PriorityNumber { get; set; }

        public DateTime? PriorityDate { get; set; }

        public DateTime? GrantPublicationDate { get; set; }

        public DateTime? ExpirationDate { get; set; }

        public DateTime? TerminationDate { get; set; }
    }
}