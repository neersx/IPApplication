using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;
using Newtonsoft.Json;
using StatusType = Inprotech.Infrastructure.Notifications.StatusType;

namespace Inprotech.Integration.Reports
{
    public class ReportContentManager : IReportContentManager
    {
        readonly IDbContext _dbContext;
        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit;
        readonly IFileSystem _fileSystem;
        readonly IBackgroundProcessLogger<ReportContentManager> _log;
        readonly Func<DateTime> _now;

        public ReportContentManager(IDbContext dbContext,
                                    Func<DateTime> now,
                                    IBackgroundProcessLogger<ReportContentManager> log,
                                    IExportExecutionTimeLimit exportExecutionTimeLimit,
                                    IFileSystem fileSystem)
        {
            _dbContext = dbContext;
            _now = now;
            _log = log;
            _exportExecutionTimeLimit = exportExecutionTimeLimit;
            _fileSystem = fileSystem;
        }

        public async Task Save(int? contentId, byte[] fileContent, string contentType, string fileName)
        {
            var content = _dbContext.Set<ReportContentResult>()
                                    .First(_ => _.Id == contentId);

            if (content == null) return;

            content.Content = fileContent;
            content.ContentType = contentType;
            content.FileName = fileName;
            content.Status = (int) StatusType.Completed;
            content.Finished = _now().ToUniversalTime();

            await _dbContext.SaveChangesAsync();
        }
        
        public async Task Save(int? contentId, string filePath, string contentType)
        {
            var fileContent = _fileSystem.ReadAllBytes(filePath);

            await Save(contentId, fileContent, contentType, filePath);
        }

        public async Task TryPutInBackground(int identityId, int? contentId, BackgroundProcessType backgroundProcessType)
        {
            var content = _dbContext.Set<ReportContentResult>()
                                    .SingleOrDefault(_ => _.Id == contentId);

            if (content == null || !_exportExecutionTimeLimit.IsLapsed(content.Started, content.Finished, content.FileName, content.IdentityId)) return;

            var bgProcess = new BackgroundProcess
            {
                IdentityId = identityId,
                Status = (int) StatusType.Completed,
                ProcessType = backgroundProcessType.ToString(),
                StatusDate = _now()
            };

            _dbContext.Set<BackgroundProcess>().Add(bgProcess);
            await _dbContext.SaveChangesAsync();

            content.ProcessId = bgProcess.Id;
            content.ConnectionId = null;
            await _dbContext.SaveChangesAsync();
        }

        public void LogException(Exception exception, int contentId, string friendlyMessage = null, BackgroundProcessType? backgroundProcessType = null)
        {
            _log.Exception(exception);
            var contentStatus = _dbContext.Set<ReportContentResult>()
                                          .Single(_ => _.Id == contentId);

            contentStatus.Error = JsonConvert.SerializeObject(exception, new JsonSerializerSettings
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                Formatting = Formatting.Indented
            });
            contentStatus.Status = (int) StatusType.Error;
            contentStatus.Finished = _now();

            _dbContext.SaveChanges();

            if (backgroundProcessType != null)
            {

                if (contentStatus.BackgroundProcess == null)
                {
                    contentStatus.BackgroundProcess = _dbContext.Set<BackgroundProcess>().Add(new BackgroundProcess
                    {
                        ProcessType = backgroundProcessType.ToString(),
                    });
                }

                contentStatus.BackgroundProcess.IdentityId = contentStatus.IdentityId;
                contentStatus.BackgroundProcess.Status = (int)StatusType.Error;
                contentStatus.BackgroundProcess.StatusDate = _now();
                contentStatus.BackgroundProcess.StatusInfo = friendlyMessage ?? exception.Message;

                _dbContext.SaveChanges();
            }
        }
    }
}