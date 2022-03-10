using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Migration
{
    public class NotificationForInactiveInnographyLink : IPerformBackgroundJob
    {
        readonly IDbContext _dbContext;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IRepository _repository;

        public NotificationForInactiveInnographyLink(IDbContext dbContext, IRepository repository, IPtoAccessCase ptoAccessCase)
        {
            _dbContext = dbContext;
            _repository = repository;
            _ptoAccessCase = ptoAccessCase;
        }

        public string Type => typeof(NotificationForInactiveInnographyLink).Name;

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<NotificationForInactiveInnographyLink>(_ => _.FindMissingRejectedNotifications());
        }

        public async Task<Activity> FindMissingRejectedNotifications()
        {
            var ids = await _dbContext.Set<CpaGlobalIdentifier>()
                                      .Include(_ => _.Case)
                                      .Where(_ => !_.IsActive)
                                      .Select(_ => new
                                                   {
                                                       _.CaseId,
                                                       _.Case.Title
                                                   })
                                      .ToDictionaryAsync(_ => _.CaseId, _ => _.Title);

            if (!ids.Any()) return DefaultActivity.NoOperation();

            var missing = (from c in _repository.Set<Case>()
                           join cn in _repository.Set<CaseNotification>() on c.Id equals cn.CaseId into cn1
                           from cn in cn1.DefaultIfEmpty()
                           where c.CorrelationId != null
                                 && c.Source == DataSourceType.IpOneData
                                 && ids.Keys.Contains(c.CorrelationId.Value)
                                 && cn == null
                           select new
                                  {
                                      c.Id,
                                      InprotechCaseId = (int) c.CorrelationId
                                  })
                .ToArray()
                .Select(m =>
                        {
                            var title = ids[m.InprotechCaseId];
                            return (Activity) Activity.Run<NotificationForInactiveInnographyLink>(_ => _.CreateRejectedItemNotification(m.Id, title));
                        })
                .ToArray();

            return missing.Any()
                ? Activity.Sequence(missing)
                : DefaultActivity.NoOperation();
        }

        public async Task CreateRejectedItemNotification(int id, string title)
        {
            var @case = await _repository.Set<Case>().SingleAsync(_ => _.Id == id);

            var cn = _ptoAccessCase.CreateOrUpdateNotification(@case, title);

            cn.Type = CaseNotificateType.Rejected;

            _repository.SaveChanges();
        }
    }
}