using System;
using InprotechKaizen.Model.Reports;

namespace Inprotech.Web.FinancialReports.Models
{
    public class ExternalReportModel
    {
        public ExternalReportModel(ExternalReport externalReport)
        {
            if (externalReport == null) throw new ArgumentNullException("externalReport");

            Id = externalReport.Id;
            Title = externalReport.Title;
            Path = externalReport.Path;
            Description = externalReport.Description;
        }

        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Path { get; set; }
    }
}
