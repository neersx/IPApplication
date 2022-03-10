using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;

namespace InprotechKaizen.Model.Components.ContentManagement.Export
{
    public interface IExportContentStatusReader
    {
        IEnumerable<ExportContent> ReadMany(IEnumerable<string> connections);
    }

    public class ExportContentStatusReader : IExportContentStatusReader
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit;

        public ExportContentStatusReader(IDbContext dbContext, Func<DateTime> now, IExportExecutionTimeLimit exportExecutionTimeLimit)
        {
            _dbContext = dbContext;
            _now = now;
            _exportExecutionTimeLimit = exportExecutionTimeLimit;
        }

        public IEnumerable<ExportContent> ReadMany(IEnumerable<string> connections)
        {
            var connectionIds = connections as string[] ?? connections.ToArray();
            var all = _dbContext.Set<ReportContentResult>()
                                                    .Where(_ => connectionIds.Contains(_.ConnectionId))
                                                    .ToArray();

            var contents = all.Select(_ => new
            {
                ContentId = _.Id,
                _.ConnectionId,
                Status = CheckStatus(_)
            });

            return contents.Where(_ => !string.IsNullOrEmpty(_.Status)).GroupBy(
                                      p => p.ConnectionId,
                                      p => new ExportContentData
                                      {
                                          Status = p.Status,
                                          ContentId = p.ContentId
                                      },
                                      (key, g) => new ExportContent
                                      {
                                          ConnectionId = key,
                                          ContentList = g.ToList()
                                      });
        }

        string CheckStatus(ReportContentResult _)
        {
            switch (_.ProcessId)
            {
                case null when _.Status == (int)StatusType.Completed && _.Finished.HasValue && !_exportExecutionTimeLimit.IsLapsed(_.Started, _.Finished, _.FileName, _.IdentityId):
                    return ContentStatus.ReadyToDownload;
                case null when _exportExecutionTimeLimit.IsLapsed(_.Started, _now().ToUniversalTime(),_.FileName, _.IdentityId):
                    return ContentStatus.ProcessedInBackground;
                default:
                    return _.Status == (int)StatusType.Error ? ContentStatus.ExecutionFailed : string.Empty;
            }
        }
    }

    public class ExportContentData
    {
        public int ContentId { get; set; }
        public string Status { get; set; }
    }

    public class ExportContent
    {
        public string ConnectionId { get; set; }
        public List<ExportContentData> ContentList { get; set; }
    }

    public static class ContentStatus
    {
        public const string ReadyToDownload = "ready.to.download";
        public const string ProcessedInBackground = "processed.in.background";
        public const string ExecutionFailed = "error";
    }
}
