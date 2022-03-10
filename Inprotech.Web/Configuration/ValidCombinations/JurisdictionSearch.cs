using Inprotech.Infrastructure.SearchResults.Exporters.Excel;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public class JurisdictionSearch
    {
        public string CountryCode { get; set; }

        [ExcelHeader("Jurisdiction")]
        public string Country { get; set; }

        [ExcelHeader("Property Type")]
        public string PropertyType { get; set; }

        [ExcelHeader("Case Type")]
        public string CaseType { get; set; }

        [ExcelHeader("Acton")]
        public string Action { get; set; }

        [ExcelHeader("Case Category")]
        public string Category { get; set; }

        [ExcelHeader("Sub Type")]
        public string SubType { get; set; }

        [ExcelHeader("Basis")]
        public string Basis { get; set; }

        [ExcelHeader("Status")]
        public string Status { get; set; }

        [ExcelHeader("Checklist")]
        public string Checklist { get; set; }

        [ExcelHeader("Relationship")]
        public string Relationship { get; set; }
    }
}
