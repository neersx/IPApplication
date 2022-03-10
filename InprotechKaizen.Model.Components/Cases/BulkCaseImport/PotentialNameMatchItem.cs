namespace InprotechKaizen.Model.Components.Cases.BulkCaseImport
{
    public class PotentialNameMatchItem
    {
        public int NameNo { get; set; }

        public string NameCode { get; set; }
        
        public string Name { get; set; }
        
        public string FirstName { get; set; }
        
        public int? AddressCode { get; set; }
        
        public string Street1 { get; set; }
        
        public string City { get; set; }
        
        public string State { get; set; }
        
        public string PostCode { get; set; }
        
        public string Country { get; set; }
        
        public string SearchKey1 { get; set; }
        
        public string Remarks { get; set; }
        
        public short UsedAsFlag { get; set; }
        
        public int MatchStatus { get; set; }
    }
}