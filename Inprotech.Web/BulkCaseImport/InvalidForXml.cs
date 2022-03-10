namespace Inprotech.Web.BulkCaseImport
{
    public class Sanitised
    {
        public int Row { get; set; }

        public string FieldName { get; set; }

        public string OriginalValue { get; set; }

        public string SanitisedValue { get; set; }

        public string Reason { get; set; }
    }

    public class SanitisedForXml : Sanitised
    {
        public SanitisedForXml()
        {
            Reason = "Invalid for Xml";
        }
    }
}