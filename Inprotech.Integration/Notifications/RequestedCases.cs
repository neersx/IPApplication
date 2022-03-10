using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Integration.Notifications
{
    public interface IRequestedCases
    {
        Task<Dictionary<CaseNotification, InprotechCase>> LoadNotifications(string[] caseIds, DataSourceType[] dataSourceTypes = null);
    }

    public class RequestedCases : IRequestedCases
    {
        readonly IEthicalWall _ethicalWall;
        readonly IDbContext _dbContext;
        readonly IExternalSystems _externalSystems;
        readonly ICaseAuthorization _caseAuthorization;
        readonly IMatchingCases _matchingCases;
        readonly IRepository _repository;

        public RequestedCases(IDbContext dbContext, IRepository repository, IExternalSystems externalSystems,
                              ICaseAuthorization caseAuthorization, IEthicalWall ethicalWall, IMatchingCases matchingCases)
        {
            _dbContext = dbContext;
            _repository = repository;
            _externalSystems = externalSystems;
            _caseAuthorization = caseAuthorization;
            _ethicalWall = ethicalWall;
            _matchingCases = matchingCases;
        }

        public async Task<Dictionary<CaseNotification, InprotechCase>> LoadNotifications(string[] caseIds, DataSourceType[] dataSourceTypes = null)
        {
            if (!caseIds.Any())
            {
                return new Dictionary<CaseNotification, InprotechCase>();
            }

            var matches = await LoadAccessibleMatches(caseIds, dataSourceTypes);

            var caseNotifications = _repository.Set<CaseNotification>()
                                               .Include(_ => _.Case)
                                               .Where(_ => matches.Keys.Contains(_.Case.Id))
                                               .ToArray();

            var cases = _dbContext.Set<InprotechCase>()
                                  .Where(_ => matches.Values.Contains(_.Id))
                                  .ToArray();

            return InRequestOrder(caseIds, matches, caseNotifications, cases);
        }

        async Task<Dictionary<int, int>> LoadAccessibleMatches(IEnumerable<string> caseIds, DataSourceType[] dataSourceTypes = null)
        {
            var externalSystems = dataSourceTypes?.Select(ExternalSystems.SystemCode).ToArray() ?? _externalSystems.DataSources();
            
            var sources = string.Join(",", externalSystems);

            var filteredIds = _ethicalWall.AllowedCases(caseIds.Select(int.Parse).ToArray());

            var cases = (await _caseAuthorization.GetInternalUserAccessPermissions(filteredIds))
                                           .Where(_ => (_.Value & AccessPermissionLevel.Select) == AccessPermissionLevel.Select)
                                           .Select(_ => _.Key)
                                           .ToArray();

            return _matchingCases.Resolve(sources, cases);
        }

        static Dictionary<CaseNotification, InprotechCase> InRequestOrder(string[] caseIds,
                                                                          Dictionary<int, int> matches, CaseNotification[] caseNotifications,
                                                                          InprotechCase[] cases)
        {
            var results = new Dictionary<CaseNotification, InprotechCase>();

            foreach (var caseId in caseIds)
            {
                var id = int.Parse(caseId);
                foreach (var match in matches.Where(_ => _.Value == id))
                {
                    var m = match;
                    var notification = caseNotifications.FirstOrDefault(cn => cn.Case.Id == m.Key);

                    if (notification == null)
                    {
                        continue; /* case record created but no notifications yet */
                    }

                    results.Add(
                                notification,
                                cases.Single(c => c.Id == id)
                               );
                }
            }

            return results;
        }
    }
}