using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.SearchResults.Exporters;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;
using Z.EntityFramework.Plus;

namespace Inprotech.Web.ContentManagement
{
    public interface IExportContentService
    {
        Task<int> GenerateContentId(string connectionId,  string fileName = null);
        ExportResult GetContentByProcessId(int processId);
        ExportResult GetContentById(int contentId);
        void RemoveContent(int contentId);
        void RemoveContentsByConnection(string connectionId);
    }

    public class ExportContentService : IExportContentService
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;

        public ExportContentService(IDbContext dbContext, Func<DateTime> now, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _now = now;
            _securityContext = securityContext;
        }

        public async Task<int> GenerateContentId(string connectionId, string fileName = null )
        {
            var now = _now();
            var content = new ReportContentResult
            {
                Started = now.ToUniversalTime(),
                Status = (int) StatusType.Started,
                ConnectionId = connectionId,
                IdentityId = _securityContext.User.Id,
                FileName = fileName
            };

            _dbContext.Set<ReportContentResult>().Add(content);
            await _dbContext.SaveChangesAsync();

            return content.Id;
        }

        public ExportResult GetContentByProcessId(int processId)
        {
            var exportData = _dbContext.Set<ReportContentResult>()
                                        .SingleOrDefault(_ => _.BackgroundProcess.Id == processId);

            if (exportData == null) throw new ArgumentException("Invalid ProcessId");

            if(exportData.IdentityId != _securityContext.User.Id)
                throw new UnauthorizedAccessException();

            return new ExportResult
            {  
                FileName = Path.GetFileName(exportData.FileName),
                Content = exportData.Content,
                ContentType = exportData.ContentType,
                ContentLength = exportData.Content.Length
            };
        }

        public ExportResult GetContentById(int contentId)
        {
            var exportData = _dbContext.Set<ReportContentResult>()
                                       .SingleOrDefault(_ => _.Id == contentId);

            if (exportData == null) throw new ArgumentException("Invalid ContentId");

            if(exportData.IdentityId != _securityContext.User.Id)
                throw new UnauthorizedAccessException();

            return new ExportResult
            {  
                FileName = Path.GetFileName(exportData.FileName),
                Content = exportData.Content,
                ContentType = exportData.ContentType,
                ContentLength = exportData.Content.Length
            };
        }

        public void RemoveContent(int contentId)
        {
            var entryToRemove = _dbContext.Set<ReportContentResult>()
                                          .Where(_ => _.Id == contentId);

            if (!entryToRemove.Any()) throw new ArgumentException("Invalid ContentId");

            entryToRemove.Delete();
        }

        public void RemoveContentsByConnection(string connectionId)
        {
            GetContentsToDelete(connectionId)
                .Delete();
        }

        IQueryable<ReportContentResult> GetContentsToDelete(string connectionId)
        {
            return _dbContext.Set<ReportContentResult>()
                             .Where(_ => !_.ProcessId.HasValue && _.ConnectionId == connectionId);
        }
    }
}