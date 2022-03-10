namespace InprotechKaizen.Model.Components.DataValidation
{
    public class SanityCheckResults
    {
        public string Status => Error ? "Error" : (Information ? "Information" : ByPassError ? "ByPassError" : string.Empty);
        public int Id { get; set; }
        public int ProcessKey { get; set; }
        public int CaseKey { get; set; }
        public string CaseReference { get; set; }
        public string CaseOffice { get; set; }
        public int? OfficeId { get; set; }
        public int? Staff { get; set; }
        public int? Signatory { get; set; }
        public string StaffName { get; set; }
        public string SignatoryName { get; set; }
        public bool ByPassError { get; set; }
        public bool Error { get; set; }
        public bool Information { get; set; }
        public string DisplayMessage { get; set; }
    }
}
