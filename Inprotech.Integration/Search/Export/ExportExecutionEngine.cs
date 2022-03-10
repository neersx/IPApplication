using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable.Dispatcher;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.SearchResults.Exporters;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;
using InprotechKaizen.Model.TempStorage;
using Newtonsoft.Json;
using Z.EntityFramework.Plus;

namespace Inprotech.Integration.Search.Export
{
    public class ExportExecutionEngine
    {
        readonly ISearchResultsExport _searchResultsExport;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit;

        public ExportExecutionEngine(IDbContext dbContext, ISearchResultsExport searchResultsExport,
                                     Func<DateTime> now, IExportExecutionTimeLimit exportExecutionTimeLimit)
        {
            _dbContext = dbContext;
            _searchResultsExport = searchResultsExport;
            _now = now;
            _exportExecutionTimeLimit = exportExecutionTimeLimit;
        }

        public async Task Execute(int storageId)
        {
            var storageData = _dbContext.Set<TempStorage>()
                                        .SingleOrDefault(_ => _.Id == storageId);

            if (storageData == null) throw new ArgumentException("storage not found");

            var args = JsonConvert.DeserializeObject<ExportExecutionJobArgs>(storageData.Value);

            var result = await _searchResultsExport.Export(args.ExportRequest, args.Settings);

            var content = _dbContext.Set<ReportContentResult>()
                                    .SingleOrDefault(_ => _.Id == args.ExportRequest.SearchExportContentId);

            if (content == null) throw new ArgumentException("Export Content not found");

            content.Content = result.Content;
            content.ContentType = result.ContentType;
            content.FileName = result.FileName;
            content.Status = (int)Infrastructure.Notifications.StatusType.Completed;
            content.Finished = _now().ToUniversalTime();

            await _dbContext.SaveChangesAsync();

            var isTimeElapsed = _exportExecutionTimeLimit.IsLapsed(content.Started, content.Finished, content.FileName, content.IdentityId);
            if (isTimeElapsed) await UpdateBackgroundStatusAsync(args.ExportRequest);
        }

        public async Task UpdateBackgroundStatusAsync(ExportRequest exportRequest)
        {
            var content = _dbContext.Set<ReportContentResult>()
                                     .SingleOrDefault(_ => _.Id == exportRequest.SearchExportContentId);

            if (content == null) return;

            var bgProcess = new BackgroundProcess
            {
                IdentityId = exportRequest.RunBy,
                Status = (int)Infrastructure.Notifications.StatusType.Completed,
                ProcessType = BackgroundProcessType.StandardReportRequest.ToString(),
                StatusDate = _now()
            };

            _dbContext.Set<BackgroundProcess>().Add(bgProcess);
            await _dbContext.SaveChangesAsync();

            content.ProcessId = bgProcess.Id;
            await _dbContext.SaveChangesAsync();
        }

        public async Task CleanUpTempStorage(int storageId)
        {
            var entryToRemove = _dbContext.Set<TempStorage>()
                                          .Where(_ => _.Id == storageId);

            await entryToRemove.DeleteAsync();
        }

        public void HandleException(ExceptionContext exception, int storageId)
        {
            var storageData = _dbContext.Set<TempStorage>()
                                        .SingleOrDefault(_ => _.Id == storageId);

            if (storageData == null) throw new ArgumentException("storage not found");

            var args = JsonConvert.DeserializeObject<ExportExecutionJobArgs>(storageData.Value);

            var contentStatus = _dbContext.Set<ReportContentResult>()
                                          .Single(_ => _.Id == args.ExportRequest.SearchExportContentId);

            contentStatus.Error = JsonConvert.SerializeObject(exception, new JsonSerializerSettings
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                Formatting = Formatting.Indented
            });
            contentStatus.Status = (int)Infrastructure.Notifications.StatusType.Error;

            _dbContext.SaveChanges();
        }
    }
}
