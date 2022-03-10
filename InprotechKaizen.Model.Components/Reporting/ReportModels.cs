using Inprotech.Infrastructure.Formatting.Exports;

namespace InprotechKaizen.Model.Components.Reporting
{
    
    public class ContentDetails
    {
        public string ContentType { get; set; }
        public string FileExtension { get; set; }
    }

    public class ExportFormatData
    {
        public bool IsDefault { get; set; }
        public ReportExportFormat ExportFormatKey { get; set; }
        public string ExportFormatDescription { get; set; }
    }
}
