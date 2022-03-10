using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Notifications
{
    public class InnographyDuplicateCasesFinder : IDuplicateCasesFinder
    {
        readonly IRepository _repository;
        readonly IDbContext _dbContext;
        readonly ICpaXmlProvider _cpaXmlProvider;
        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml;

        public InnographyDuplicateCasesFinder(IRepository repository, IDbContext dbContext, ICpaXmlProvider cpaXmlProvider, IInnographyIdFromCpaXml innographyIdFromCpaXml)
        {
            _repository = repository;
            _dbContext = dbContext;
            _cpaXmlProvider = cpaXmlProvider;
            _innographyIdFromCpaXml = innographyIdFromCpaXml;
        }

        public async Task<IEnumerable<int>> FindFor(int forNotificationId)
        {
            var result = await GetNotificationAndInnographyId(forNotificationId);

            if (!result.notification.Case.CorrelationId.HasValue)
            {
                return Enumerable.Empty<int>();
            }

            var forCaseId = result.notification.Case.CorrelationId.Value;

            var innographyId = result.innographyId;

            var caseIds = FindDuplicatesFor(innographyId);

            return caseIds.Concat(new[] {forCaseId}).Distinct();
        }

        public async Task<bool> AreDuplicatesPresent(int forNotificationId)
        {
            var result = await GetNotificationAndInnographyId(forNotificationId);

            if (!result.notification.Case.CorrelationId.HasValue)
            {
                return false;
            }

            var forCaseId = result.notification.Case.CorrelationId.Value;

            var innographyId = result.innographyId;

            var caseIds = FindDuplicatesFor(innographyId);

            return caseIds.Except(new[]{ forCaseId }).Any();
        }

        async Task<(string innographyId, CaseNotification notification)> GetNotificationAndInnographyId(int notificationId)
        {
            var notification = _repository.Set<CaseNotification>()
                                          .Include(_ => _.Case)
                                          .Single(cn => cn.Id == notificationId);

            return ( _innographyIdFromCpaXml.Resolve(await _cpaXmlProvider.For(notification.Id)), notification);
        }

        IQueryable<int> FindDuplicatesFor(string innographyId)
        {
            var cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>();
            var innographyIds = _dbContext.Set<CpaGlobalIdentifier>();

            return from i in innographyIds
                    where i.IsActive
                    join c in cases on i.CaseId equals c.Id
                    where i.InnographyId == innographyId
                    select c.Id;
        }
    }
}