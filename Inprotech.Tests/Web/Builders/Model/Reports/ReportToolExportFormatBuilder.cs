using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Reports
{
    public class ReportToolExportFormatBuilder : IBuilder<ReportToolExportFormat>
    {
        //public int Id { get; set; }

        public int? ReportTool { get; set; }

        public int ExportFormat { get; set; }

        public bool UsedByWorkbench { get; set; }

        public ReportToolExportFormat Build()
        {
            return new ReportToolExportFormat()
            {
                ExportFormat = ExportFormat,
                ReportTool = ReportTool,
                UsedByWorkbench = UsedByWorkbench,
                Id = Fixture.Integer()
            };
        }
    }
}