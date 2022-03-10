using System;

namespace InprotechKaizen.Model.Components.Names
{
    public class NewNameAddress
    {
        public int AddressTypeKey { get; set; }

        public bool Owner { get; set; }

        public string Street { get; set; }

        public string City { get; set; }

        public string StateCode { get; set; }

        public string PostCode { get; set; }

        public string CountryCode { get; set; }

        public int? TelephoneKey { get; set; }

        public int? FaxKey { get; set; }

        public int? AddressStatusKey { get; set; }

        public DateTime? DateCeased { get; set; }

        public bool IsMainAddress { get; set; }
    }
}
