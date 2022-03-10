namespace Inprotech.Integration.CaseSource
{
    public class EligibleCase
    {
        public int CaseKey { get; set; }

        public string ApplicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public string SystemCode { get; set; }

        public string CountryCode { get; set; }

        public string PropertyType { get; set; }

        public EligibleCase()
        {
            
        }

        public EligibleCase(int caseKey, string countryCode, string systemCode = null)
        {
            CaseKey = caseKey;
            CountryCode = countryCode;
            SystemCode = systemCode;
        }
    }
}