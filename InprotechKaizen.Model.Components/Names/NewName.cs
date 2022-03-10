using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Names
{
    public class NewName
    {
        public string NameCode { get; set; }

        public bool Individual { get; set; }

        public bool Staff { get; set; }

        public bool Client { get; set; }

        public bool Supplier { get; set; }

        public string HomeCountryCode { get; set; }

        public string Name { get; set; }

        public string Title { get; set; }

        public string Initials { get; set; }

        public string FirstName { get; set; }

        public string ExtendedName { get; set; }

        public string SearchKey1 { get; set; }

        public string SearchKey2 { get; set; }

        public string NationalityCode { get; set; }

        public string GenderCode { get; set; }

        public string FormalSalutation { get; set; }

        public string InformalSalutation { get; set; }

        public string Remarks { get; set; }

        public int? GroupKey { get; set; }

        public int? NameStyleKey { get; set; }

        public string InstructorPrefix { get; set; }

        public int? CaseSequence { get; set; }

        public string AirportCode { get; set; }

        public string TaxNo { get; set; }

        public IEnumerable<NewNameAddress> NameAddresses { get; set; }

        public IEnumerable<NewNameTeleCommunication> NameTeleCommunications { get; set; }
    }
}
