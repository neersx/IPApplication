using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class CaseAuthorization : ICaseAuthorization
    {
        const bool Unauthorised = true;
        const bool NotUnauthorised = false;
        const string ReasonNotRequired = null;
        const int CanUpdateLevel = (int) (AccessPermissionLevel.Insert | AccessPermissionLevel.Update | AccessPermissionLevel.Delete);
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        public CaseAuthorization(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<AuthorizationResult> Authorize(int caseId, AccessPermissionLevel requiredLevel)
        {
            return (await CheckAuthorization(requiredLevel, caseId))[caseId];
        }

        public async Task<IEnumerable<int>> AccessibleCases(params int[] caseIds)
        {
            var distinctCaseIds = caseIds.Distinct().ToArray();

            var r = await CheckAuthorization(AccessPermissionLevel.Select, distinctCaseIds);

            return r.Where(_ => _.Value.Exists && !_.Value.IsUnauthorized).Select(_ => _.Key);
        }

        public async Task<IEnumerable<int>> UpdatableCases(params int[] caseIds)
        {
            var distinctCaseIds = caseIds.Distinct().ToArray();

            var r = await CheckAuthorization(AccessPermissionLevel.Update, distinctCaseIds);

            return r.Where(_ => _.Value.Exists && !_.Value.IsUnauthorized).Select(_ => _.Key);
        }

        public async Task<IDictionary<int, AccessPermissionLevel>> GetInternalUserAccessPermissions(IEnumerable<int> caseIds, int? userIdentityId = null)
        {
            var allCaseIds = (caseIds ?? new List<int>()).Distinct().ToList();

            if (!allCaseIds.Any())
            {
                return new Dictionary<int, AccessPermissionLevel>();
            }

            const int chunkSize = 10000;
            var result = new Dictionary<int, AccessPermissionLevel>();

            var currentChunk = allCaseIds.Take(chunkSize).ToArray();
            while (currentChunk.Any())
            {
                allCaseIds = allCaseIds.Except(currentChunk).ToList();

                var chunk = currentChunk;
                foreach (var kvp in await EvaluateInternalUserRowLevelAccessPermission(chunk, userIdentityId))
                    result.Add(kvp.Key, kvp.Value);

                currentChunk = allCaseIds.Take(chunkSize).ToArray();
            }
            return result;
        }

        async Task<Dictionary<int, AuthorizationResult>> CheckAuthorization(AccessPermissionLevel requiredLevel, params int[] caseIds)
        {
            var userId = _securityContext.User.Id;
            var userName = _securityContext.User.UserName;

            if (_securityContext.User.IsExternalUser) return await EvaluateExternalUserAccess(caseIds, userId);

            var r1 = await EvaluateInternalUserEthicalWall(caseIds, userId);
            if (r1.AllUnauthorisedOrNotExists(out int[] r1OutCaseIds, out Dictionary<int, AuthorizationResult> r1Unathorsied)) return r1;

            var r2 = (await EvaluateInternalUserRowLevelAccessPermission(userId, requiredLevel, r1OutCaseIds)).Include(r1Unathorsied);
            if (r2.AllUnauthorisedOrNotExists(out int[] r2OutCaseIds, out Dictionary<int, AuthorizationResult> r2Unathorsied)) return r2;

            if (requiredLevel == AccessPermissionLevel.Select) return r2;

            return (await EvaluateUpdateCasePermissionBasedOnStatusSecurity(userName, r2OutCaseIds)).Include(r2Unathorsied);
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateExternalUserAccess(int[] caseIds, int userId)
        {
            /*
             * External Users should only be authorised based on their account case contact
             */
            return caseIds.ToAuthorizationResults(await (from c in _dbContext.Set<Case>()
                                                         join a in _dbContext.FilterUserCases(userId, true, null) on c.Id equals a.CaseId into a1
                                                         from a in a1.DefaultIfEmpty()
                                                         where caseIds.Contains(c.Id)
                                                         select new
                                                         {
                                                             CaseId = c.Id,
                                                             Unauthorised = a == null
                                                         }).ToDictionaryAsync(k => k.CaseId, v => v.Unauthorised), ErrorTypeCode.CaseNotRelatedToExternalUser.ToString());
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateInternalUserEthicalWall(int[] caseIds, int userId)
        {
            /*
             * Internal Users should be authorised first based on Ethical Wall
             */
            return caseIds.ToAuthorizationResults(await (from c in _dbContext.Set<Case>()
                                                         join eth in _dbContext.CasesEthicalWall(userId) on c.Id equals eth.CaseId into eth1
                                                         from eth in eth1.DefaultIfEmpty()
                                                         where caseIds.Contains(c.Id)
                                                         select new
                                                         {
                                                             c.Id,
                                                             Unauthorised = eth == null
                                                         }).ToDictionaryAsync(k => k.Id, v => v.Unauthorised), ErrorTypeCode.EthicalWallForCase.ToString());
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateInternalUserRowLevelAccessPermission(int userId, AccessPermissionLevel requiredLevel, params int[] caseIds)
        {
            /*
             * Internal Users should be evaluated with Row Level Access, if configured.
             */
            var caseRowAccessDetails = await _dbContext.Set<RowAccessDetail>().Where(_ => _.AccessType == "C").Select(_ => _.Name).ToArrayAsync();

            if (!caseRowAccessDetails.Any()) return caseIds.ToAuthorizationResults(NotUnauthorised, ReasonNotRequired);

            var noRowAccessAppliedToSelf = !_securityContext.User.RowAccessPermissions.Any(_ => caseRowAccessDetails.Contains(_.Name));

            var hasRowAccessAppliedToOthers = await _dbContext.Set<User>().AnyAsync(_ => !_.IsExternalUser && _.RowAccessPermissions.Any(rad => caseRowAccessDetails.Contains(rad.Name)));

            if (noRowAccessAppliedToSelf)
            {
                /*
                 * When row access has been configured in the system, all users are subjected to row access
                 * Users without explicitly being assigned row access should not see any cases.
                 */

                return hasRowAccessAppliedToOthers
                    ? caseIds.ToAuthorizationResults(Unauthorised, ErrorTypeCode.NoRowaccessForCase.ToString())
                    : caseIds.ToAuthorizationResults(NotUnauthorised, ReasonNotRequired);
            }

            /*
             * If Row Level Security is in use for the user, determine how/if Office is stored against Cases.  
             * It is possible to store the office directly in the CASES table or if a Case is to have multiple offices then it is stored in TABLEATTRIBUTES.
             * Check to see if there are any Offices held as TABLEATRRIBUTES of the Case. 
             * If not then treat as if Office is stored directly in the CASES table.
             */
            var useCaseOffice = _siteControlReader.Read<bool?>(SiteControls.RowSecurityUsesCaseOffice) == true ||
                                !await _dbContext.Set<TableAttributes>().AnyAsync(_ => _.ParentTable == KnownTableAttributes.Case && _.SourceTableId == (short) TableTypes.Office);

            var rowAccessForCases = useCaseOffice
                ? _dbContext.CasesRowSecurity(userId)
                : _dbContext.CasesRowSecurityMultiOffice(userId);

            var rowAccess = await (from rac in rowAccessForCases
                                   where caseIds.Contains(rac.CaseId) && rac.SecurityFlag != null
                                   select new
                                   {
                                       rac.CaseId,
                                       AccessLevel = (AccessPermissionLevel) rac.SecurityFlag
                                   }).ToDictionaryAsync(k => k.CaseId, v => v.AccessLevel);

            var result = new Dictionary<int, AuthorizationResult>();
            foreach (var caseId in caseIds)
            {
                if (!rowAccess.TryGetValue(caseId, out AccessPermissionLevel permissionLevel) || !permissionLevel.HasFlag(requiredLevel))
                {
                    result.Add(caseId, new AuthorizationResult(caseId, true, Unauthorised, ErrorTypeCode.NoRowaccessForCase.ToString()));
                    continue;
                }

                result.Add(caseId, AuthorizationResult.Authorized(caseId));
            }
            return result;
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateUpdateCasePermissionBasedOnStatusSecurity(string userName, params int[] caseIds)
        {
            /*
             * Internal Users should be evaluated with Status Security, if update permission requested.
             */
            var defaultStatusAccess = _siteControlReader.Read<int?>(SiteControls.DefaultSecurity);

            var theCasesWithStatus = _dbContext.Set<Case>().Where(_ => caseIds.Contains(_.Id) && _.CaseStatus != null);

            var statusAccess = await (from ss in _dbContext.Set<StatusSecurity>()
                                      join c in theCasesWithStatus on ss.StatusId equals c.CaseStatus.Id
                                      where ss.UserName == userName && ss.AccessLevel != null
                                      select new
                                      {
                                          c.Id,
                                          ss.AccessLevel
                                      }).ToDictionaryAsync(k => k.Id, v => (short) v.AccessLevel);

            if (!statusAccess.Any() && defaultStatusAccess == null)
            {
                return caseIds.ToAuthorizationResults(NotUnauthorised, ReasonNotRequired);
            }

            var result = new Dictionary<int, AuthorizationResult>();
            foreach (var caseId in caseIds)
            {
                if (statusAccess.TryGetValue(caseId, out short permissionLevel))
                {
                    result.Add(caseId, (permissionLevel & CanUpdateLevel) > 0
                                   ? AuthorizationResult.Authorized(caseId)
                                   : AuthorizationResult.Unauthorized(caseId, ErrorTypeCode.NoStatusSecurityForCase.ToString()));
                    continue;
                }

                if ((defaultStatusAccess.GetValueOrDefault() & CanUpdateLevel) > 0)
                {
                    result.Add(caseId, AuthorizationResult.Authorized(caseId));
                    continue;
                }

                result.Add(caseId, AuthorizationResult.Unauthorized(caseId, ErrorTypeCode.NoStatusSecurityForCase.ToString()));
            }
            return result;
        }

        [Obsolete("This method does not consider Ethical Wall and Case Status security")]
        async Task<Dictionary<int, AccessPermissionLevel>> EvaluateInternalUserRowLevelAccessPermission(IEnumerable<int> caseIds, int? userIdentityId = null)
        {
            var userId = userIdentityId ?? _securityContext.User.Id;

            if (_dbContext.Set<User>().Single(_ => _.Id == userId).IsExternalUser) throw new InvalidOperationException("This method is not appropriate for external users");

            var caseRowAccessDetails = await _dbContext.Set<RowAccessDetail>().Where(_ => _.AccessType == "C").Select(_ => _.Name).ToArrayAsync();

            if (!caseRowAccessDetails.Any())
            {
                /* if no row access configured, then everyone has full access */
                return caseIds.ToDictionary(caseId => caseId, v => AccessPermissionLevel.FullAccess);
            }

            var noRowAccessAppliedToSelf = !_securityContext.User.RowAccessPermissions.Any(_ => caseRowAccessDetails.Contains(_.Name));

            var hasRowAccessAppliedToOthers = await _dbContext.Set<User>().AnyAsync(_ => !_.IsExternalUser && _.RowAccessPermissions.Any(rad => caseRowAccessDetails.Contains(rad.Name)));

            /*
             * When row access has been configured in the system, all users are subjected to row access
             * Users without explicitly being assigned row access should not see any cases.
             */
            var blockAll = noRowAccessAppliedToSelf && hasRowAccessAppliedToOthers;

            if (noRowAccessAppliedToSelf && !hasRowAccessAppliedToOthers)
            {
                /* if no row access has been assigned to anyone, then everyone has full access */
                return caseIds.ToDictionary(caseId => caseId, v => AccessPermissionLevel.FullAccess);
            }

            /*
             * If Row Level Security is in use for the user, determine how/if Office is stored against Cases.  
             * It is possible to store the office directly in the CASES table or if a Case is to have multiple offices then it is stored in TABLEATTRIBUTES.
             * Check to see if there are any Offices held as TABLEATRRIBUTES of the Case. 
             * If not then treat as if Office is stored directly in the CASES table.
             */
            var useCaseOffice = _siteControlReader.Read<bool?>(SiteControls.RowSecurityUsesCaseOffice) == true ||
                                !await _dbContext.Set<TableAttributes>().AnyAsync(_ => _.ParentTable == KnownTableAttributes.Case && _.SourceTableId == (short) TableTypes.Office);

            var rowAccessForCases = useCaseOffice
                ? _dbContext.CasesRowSecurity(userId)
                : _dbContext.CasesRowSecurityMultiOffice(userId);

            var interim = from rac in rowAccessForCases
                          join c in _dbContext.Set<Case>() on rac.CaseId equals c.Id into c1
                          from c in c1
                          where caseIds.Contains(c.Id) && rac.SecurityFlag != null
                          select new
                          {
                              rac.CaseId,
                              AccessLevel = (AccessPermissionLevel) rac.SecurityFlag
                          };

            var result = new Dictionary<int, AccessPermissionLevel>();

            foreach (var r in interim)
            {
                if (result.ContainsKey(r.CaseId) || blockAll)
                {
                    result[r.CaseId] |= r.AccessLevel;
                }
                else
                {
                    result[r.CaseId] = r.AccessLevel;
                }
            }

            return result;
        }
    }
}