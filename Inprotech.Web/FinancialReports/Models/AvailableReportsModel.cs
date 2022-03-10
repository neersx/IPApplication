using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Reports;

namespace Inprotech.Web.FinancialReports.Models
{
    public class AvailableReportsModel
    {
        public AvailableReportsModel(IEnumerable<ExternalReport> reports, IEnumerable<TranslatedCategory> translatedCategories)
        {
            if (reports == null) throw new ArgumentNullException("reports");

            var externalReports = reports.ToArray();

            if (!externalReports.Any())
            {
                throw Exceptions.Forbidden(Properties.Resources.ErrorSecurityTaskAccessCheckFailure);
            }

            CategorisedReports = externalReports.SelectMany(r => r.SecurityTask.ProvidedByFeatures)
                                                .Select(
                                                        r =>
                                                        new AvailableReportCategoryModel(
                                                            translatedCategories.First(_ => _.Id == r.Category.Id).Name,
                                                            externalReports.Where(
                                                                                  r1 =>
                                                                                  r.SecurityTasks.Contains(
                                                                                                           r1
                                                                                                               .SecurityTask))))
                                                .OrderBy(m => m.ReportCategory)
                                                .ToArray();
        }

        public AvailableReportCategoryModel[] CategorisedReports { get; set; }
    }
}
