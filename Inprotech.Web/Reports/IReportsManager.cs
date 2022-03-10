
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using InprotechKaizen.Model.Components.Reporting;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Reports
{
    public interface IReportsManager
    {
        Task<ReportRequest> CreateReportRequest(JObject criteria, int contentId);
    }

    public class ReportCriteria
    {
        public string XmlFilterCriteria { get; set; }
        public ReportExportFormat ReportExportFormat { get; set; }
        public string ReportName { get; set; }
        public string ConnectionId { get; set; }
    }

    public class BillingWorksheetCriteria : ReportCriteria
    {
        public IEnumerable<BillingWorksheetItem> Items { get; set; }
    }

    public class BillingWorksheetItem
    {
        public int? EntityKey { get; set; }
        public int? WipNameKey { get; set; }
        public int? CaseKey { get; set; }
    }

    public static class ReportsTypes
    {
        public const string BillingWorksheet = "BILLING_WORKSHEETS";
       
    }
}
