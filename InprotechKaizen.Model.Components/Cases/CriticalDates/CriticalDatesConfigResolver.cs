using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface ICriticalDatesConfigResolver
    {
        Task Resolve(User user, string culture, CriticalDatesMetadata result);
    }

    public class CriticalDatesConfigResolver : ICriticalDatesConfigResolver
    {
        readonly IDbContext _dbContext;
        readonly ICriteriaReader _criteriaReader;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly ISiteControlReader _siteControls;

        public CriticalDatesConfigResolver(IDbContext dbContext,
                                           ICriteriaReader criteriaReader,
                                           ISiteControlReader siteControlReader,
                                           IImportanceLevelResolver importanceLevelResolver)
        {
            _dbContext = dbContext;
            _criteriaReader = criteriaReader;
            _siteControls = siteControlReader;
            _importanceLevelResolver = importanceLevelResolver;
        }

        public Task Resolve(User user, string culture, CriticalDatesMetadata result)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var action = _siteControls.Read<string>(user.IsExternalUser
                                                        ? SiteControls.CriticalDates_External
                                                        : SiteControls.CriticalDates_Internal);

            if (_criteriaReader.TryGetEventControl(result.CaseId, action, out int? criteriaId))
            {
                result.CriteriaNo = criteriaId;
            }

            result.CaseRef = _dbContext.Set<Case>().Single(_ => _.Id == result.CaseId).Irn;
            result.Action = action;
            result.RenewalAction = _siteControls.Read<string>(SiteControls.MainRenewalAction);
            result.ImportanceLevel = _importanceLevelResolver.Resolve(user);

            return Task.FromResult<object>(null);
        }
    }
}