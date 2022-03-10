using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace InprotechKaizen.Model.Components.ContentManagement.Export
{
    public interface IExportExecutionTimeLimit
    {
        bool IsLapsed(DateTime? started, DateTime? finished, string fileName, int identity);
    }

    public class ExportExecutionTimeLimit : IExportExecutionTimeLimit
    {
        readonly IDbContext _dbContext;

        public ExportExecutionTimeLimit(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool IsLapsed(DateTime? started, DateTime? finished, string fileName, int identity)
        {
            int? settingValue;
            if (fileName == null || !fileName.IgnoreCaseContains("billingWorksheet"))
            {
                settingValue = _dbContext.Set<SettingValues>()
                                             .SingleOrDefault(_ => _.SettingId == KnownSettingIds.SearchReportGenerationTimeout && _.User == null)
                                             ?.IntegerValue.GetValueOrDefault();
            }
            else
            {
                settingValue = _dbContext.Set<SettingValues>()
                                         .Where(v => (v.User == null || v.User.Id == identity) && v.SettingId == KnownSettingIds.BillingWorksheetReportPushtoBackgroundTimeout)
                                         .OrderByDescending(_ => _.User != null)
                                         .FirstOrDefault()?.IntegerValue.GetValueOrDefault();
            }
           
            var timeout = settingValue * 1000;
            return (finished.GetValueOrDefault()
                                 - started.GetValueOrDefault()).TotalMilliseconds > timeout;
        }
    }
}
