using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class NameAuthorization : INameAuthorization
    {
        const bool Unauthorised = true;
        const bool NotUnauthorised = false;
        const string ReasonNotRequired = null;

        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public NameAuthorization(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public async Task<AuthorizationResult> Authorize(int nameId, AccessPermissionLevel requiredLevel)
        {
            return (await CheckAuthorization(requiredLevel, nameId))[nameId];
        }

        public async Task<IEnumerable<int>> AccessibleNames(params int[] nameIds)
        {
            var r = await CheckAuthorization(AccessPermissionLevel.Select, nameIds);

            return r.Where(_ => _.Value.Exists && !_.Value.IsUnauthorized).Select(_ => _.Key);
        }

        public async Task<IEnumerable<int>> UpdatableNames(params int[] nameIds)
        {
            var r = await CheckAuthorization(AccessPermissionLevel.FullAccess, nameIds);

            return r.Where(_ => _.Value.Exists && !_.Value.IsUnauthorized).Select(_ => _.Key);
        }

        async Task<Dictionary<int, AuthorizationResult>> CheckAuthorization(AccessPermissionLevel requiredLevel, params int[] nameIds)
        {
            var userId = _securityContext.User.Id;

            if (_securityContext.User.IsExternalUser) return await EvaluateExternalUserAccess(nameIds, userId);

            var r1 = await EvaluateInternalUserEthicalWall(nameIds, userId);
            if (r1.AllUnauthorisedOrNotExists(out var r1OutNameIds, out var r1Unathorsied)) return r1;

            return (await EvaluateInternalUserRowLevelAccessPermission(userId, requiredLevel, r1OutNameIds)).Include(r1Unathorsied);
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateExternalUserAccess(int[] nameIds, int userId)
        {
            /*
             * External Users should only be authorised based on their account case contact
             */
            return nameIds.ToAuthorizationResults(await (from n in _dbContext.Set<Name>()
                                                         join a in _dbContext.FilterUserViewNames(userId) on n.Id equals a.NameNo into a1
                                                         from a in a1.DefaultIfEmpty()
                                                         where nameIds.Contains(n.Id)
                                                         select new
                                                         {
                                                             NameId = n.Id,
                                                             Unauthorised = a == null
                                                         }).ToDictionaryAsync(k => k.NameId, v => v.Unauthorised), ErrorTypeCode.NameNotRelatedToExternalUser.ToString());
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateInternalUserEthicalWall(int[] nameIds, int userId)
        {
            /*
             * Internal Users should be authorised first based on Ethical Wall
             */
            return nameIds.ToAuthorizationResults(await (from n in _dbContext.Set<Name>()
                                                         join eth in _dbContext.NamesEthicalWall(userId) on n.Id equals eth.NameNo into eth1
                                                         from eth in eth1.DefaultIfEmpty()
                                                         where nameIds.Contains(n.Id)
                                                         select new
                                                         {
                                                             n.Id,
                                                             Unauthorised = eth == null
                                                         }).ToDictionaryAsync(k => k.Id, v => v.Unauthorised), ErrorTypeCode.EthicalWallForName.ToString());
        }

        async Task<Dictionary<int, AuthorizationResult>> EvaluateInternalUserRowLevelAccessPermission(int userId, AccessPermissionLevel requiredLevel, params int[] nameIds)
        {
            /*
             * Internal Users should be evaluated with Row Level Access, if configured.
             */
            var nameRowAccessDetails = await _dbContext.Set<RowAccessDetail>().Where(_ => _.AccessType == "N").Select(_ => _.Name).ToArrayAsync();

            if (!nameRowAccessDetails.Any()) return nameIds.ToAuthorizationResults(NotUnauthorised, ReasonNotRequired);

            var noRowAccessAppliedToSelf = !_securityContext.User.RowAccessPermissions.Any(_ => nameRowAccessDetails.Contains(_.Name));

            var hasRowAccessAppliedToOthers = await _dbContext.Set<User>().AnyAsync(_ => !_.IsExternalUser && _.RowAccessPermissions.Any(rad => nameRowAccessDetails.Contains(rad.Name)));

            if (noRowAccessAppliedToSelf)
            {
                /*
                 * When row access has been configured in the system, all users are subjected to row access
                 * Users without explicitly being assigned row access should not see any names.
                 */

                return hasRowAccessAppliedToOthers
                    ? nameIds.ToAuthorizationResults(Unauthorised, ErrorTypeCode.NoRowaccessForName.ToString())
                    : nameIds.ToAuthorizationResults(NotUnauthorised, ReasonNotRequired);
            }

            var rowAccess = (await (from rac in _dbContext.NamesRowSecurity(userId)
                                    where nameIds.Contains(rac.NameNo) && rac.SecurityFlag != null
                                    select new
                                    {
                                        rac.NameNo,
                                        AccessLevel = (AccessPermissionLevel) rac.SecurityFlag
                                    })
                                .ToArrayAsync())
                            .Distinct()
                            .ToDictionary(k => k.NameNo, v => v.AccessLevel);

            var result = new Dictionary<int, AuthorizationResult>();
            foreach (var nameId in nameIds)
            {
                if (!rowAccess.TryGetValue(nameId, out var permissionLevel) || !permissionLevel.HasFlag(requiredLevel))
                {
                    result.Add(nameId, new AuthorizationResult(nameId, true, Unauthorised, ErrorTypeCode.NoRowaccessForName.ToString()));
                    continue;
                }

                result.Add(nameId, AuthorizationResult.Authorized(nameId));
            }

            return result;
        }
    }
}