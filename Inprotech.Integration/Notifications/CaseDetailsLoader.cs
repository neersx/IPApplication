using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseDetailsLoader
    {
        Task<Dictionary<int, CaseDetails>> LoadCasesForNotifications(IEnumerable<CaseNotificationResponse> notifications);
    }

    public class CaseDetails
    {
        public int CaseId { get; set; }
        public string CaseRef { get; set; }
        public bool HasPermission { get; set; }
    }

    public class CaseDetailsLoader : ICaseDetailsLoader
    {
        readonly IDbContext _dbContext;
        readonly IEthicalWall _ethicalWall;
        readonly ICaseAuthorization _caseAuthorization;

        public CaseDetailsLoader(IDbContext dbContext, IEthicalWall ethicalWall, ICaseAuthorization caseAuthorization)
        {
            _dbContext = dbContext;
            _ethicalWall = ethicalWall;
            _caseAuthorization = caseAuthorization;
        }

        public async Task<Dictionary<int, CaseDetails>> LoadCasesForNotifications(IEnumerable<CaseNotificationResponse> notifications)
        {
            var matches = notifications
                .Where(n => n.CaseId.HasValue)
                .ToDictionary(
                              n => n.NotificationId,
                              n => new
                              {
                                  NotificationKey = n.NotificationId,
                                  CaseKey = n.CaseId.GetValueOrDefault()
                              });

            if (matches.Count == 0)
            {
                return new Dictionary<int, CaseDetails>();
            }

            var caseIds = matches.Select(o => o.Value.CaseKey).ToArray();

            var cases = (from c in _dbContext.Set<InprotechCase>()
                         where caseIds.Contains(c.Id)
                         select new CaseReference {Id = c.Id, Irn = c.Irn})
                .ToArray();

            var permissions = await _caseAuthorization.GetInternalUserAccessPermissions(_ethicalWall.AllowedCases(caseIds));
            
            return matches.ToDictionary(
                                        n => n.Key,
                                        n => new CaseDetails
                                        {
                                            CaseId = n.Value.CaseKey,
                                            CaseRef = IrnOf(n.Value.CaseKey, cases),
                                            HasPermission = permissions.ContainsKey(n.Value.CaseKey) &&
                                                            (permissions[n.Value.CaseKey] & AccessPermissionLevel.Select) ==
                                                            AccessPermissionLevel.Select
                                        });
        }

        static string IrnOf(int caseId, IEnumerable<CaseReference> cases)
        {
            return cases.SingleOrDefault(_ => _.Id == caseId)?.Irn;
        }

        public class CaseReference
        {
            public int Id { get; set; }

            public string Irn { get; set; }
        }
    }
}