using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Search.Export;

namespace InprotechKaizen.Model.Components.System.BackgroundProcess
{
    public class BackgroundProcessMessageClient : IBackgroundProcessMessageClient
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public BackgroundProcessMessageClient(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }

        public Task SendAsync(BackgroundProcessMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _dbContext.Set<Model.BackgroundProcess.BackgroundProcess>()
                      .Add(
                           new Model.BackgroundProcess.BackgroundProcess
                           {
                               IdentityId = message.IdentityId,
                               ProcessType = message.ProcessType.ToString(),
                               Status = (int)message.StatusType,
                               StatusInfo = message.Message,
                               StatusDate = _now(),
                               ProcessSubType = message.ProcessSubType?.ToString()
                           });

            _dbContext.SaveChanges();

            return Task.FromResult((object)null);
        }

        public IEnumerable<BackgroundProcessMessage> Get(IEnumerable<int> identityIds, bool onlyProcessIds = false)
        {
            var ids = identityIds as int[] ?? identityIds.ToArray();
            if (!ids.Any())
            {
                return Enumerable.Empty<BackgroundProcessMessage>();
            }

            var statusTypes = new[] { StatusType.Completed, StatusType.Error, StatusType.Information }.Cast<int>().ToArray();

            return (from b in _dbContext.Set<Model.BackgroundProcess.BackgroundProcess>()
                    where statusTypes.Contains(b.Status) && ids.Contains(b.IdentityId)
                    orderby b.StatusDate descending
                    select new
                    {
                        b.Id,
                        b.IdentityId,
                        b.ProcessType,
                        b.StatusDate,
                        b.StatusInfo,
                        b.Status,
                        b.ProcessSubType
                    })
                   .ToArray()
                   .Select(_ => onlyProcessIds
                               ? new BackgroundProcessMessage
                               {
                                   ProcessId = _.Id,
                                   IdentityId = _.IdentityId
                               }
                               : new BackgroundProcessMessage
                               {
                                   StatusType = (StatusType)_.Status,
                                   ProcessId = _.Id,
                                   ProcessType = (BackgroundProcessType)Enum.Parse(typeof(BackgroundProcessType), _.ProcessType),
                                   FileName = FileName((BackgroundProcessType)Enum.Parse(typeof(BackgroundProcessType), _.ProcessType), _.Id),
                                   StatusDate = _.StatusDate,
                                   StatusInfo = _.StatusInfo,
                                   IdentityId = _.IdentityId,
                                   ProcessSubType = _.ProcessSubType != null ? (BackgroundProcessSubType)Enum.Parse(typeof(BackgroundProcessSubType), _.ProcessSubType) : null
                               });
        }

        public bool DeleteBackgroundProcessMessages(int[] processIds)
        {
            if (processIds != null && processIds.Length > 0)
            {
                var processes = _dbContext.Set<Model.BackgroundProcess.BackgroundProcess>().Where(_ => processIds.Contains(_.Id));
                _dbContext.RemoveRange(processes);
                _dbContext.SaveChanges();
                return true;
            }

            return false;
        }

        string FileName(BackgroundProcessType processType, int processId)
        {
            if (processType != BackgroundProcessType.StandardReportRequest) return null;

            var content = _dbContext.Set<ReportContentResult>().Single(_ => _.ProcessId == processId);

            return content.FileName;
        }
    }
}