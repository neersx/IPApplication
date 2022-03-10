using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Reports;

namespace Inprotech.Web.FinancialReports.Models
{
    public class AvailableReportCategoryModel
    {
        public AvailableReportCategoryModel(string reportCategory, IEnumerable<ExternalReport> reports)
        {
            if (reportCategory == null) throw new ArgumentNullException("reportCategory");
            if (reports == null) throw new ArgumentNullException("reports");

            ReportCategory = reportCategory;
            Reports = reports.Select(r => new ExternalReportModel(r));
        }

        public string ReportCategory { get; set; }
        public IEnumerable<ExternalReportModel> Reports { get; set; }
    }
}
