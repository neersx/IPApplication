using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Names.Restrictions
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/names")]
    public class CheckRestrictionsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly INameAuthorization _nameAuthorization;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public CheckRestrictionsController(IDbContext dbContext, ISecurityContext securityContext, INameAuthorization nameAuthorization, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _nameAuthorization = nameAuthorization;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [Route("restrictions")]
        public async Task<IEnumerable<DebtorRestriction>> GetRestrictions(string ids)
        {
            var debtorIds = (string.IsNullOrWhiteSpace(ids) ? string.Empty : ids)
                            .Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                            .Select(int.Parse)
                            .ToArray();

            var culture = _preferredCultureResolver.Resolve();

            var authorisedIds = _securityContext.User.IsExternalUser ? new int [0] : await _nameAuthorization.AccessibleNames(debtorIds);

            var debtorRestrictions = _dbContext.Set<ClientDetail>()
                                               .Where(_ => _.DebtorStatus != null && authorisedIds.Contains(_.Id))
                                               .Select(_ => new DebtorRestriction
                                               {
                                                   Id = _.Id,
                                                   Description = DbFuncs.GetTranslation(_.DebtorStatus.Status, null, _.DebtorStatus.StatusTId, culture),
                                                   RestrictionAction = (short?) _.DebtorStatus.RestrictionType
                                               }).ToArray();

            var unavailable = debtorRestrictions.Select(_ => _.Id);

            return debtorIds.Except(unavailable).Select(DebtorRestriction.NotApplicable)
                            .Concat(debtorRestrictions);
        }
    }

    public class DebtorRestriction
    {
        static readonly Dictionary<short?, string> Map = new Dictionary<short?, string>
        {
            {KnownDebtorRestrictions.DisplayError, "error"},
            {KnownDebtorRestrictions.DisplayWarning, "warning"},
            {KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, "warning"},
            {KnownDebtorRestrictions.NoRestriction, "information"},
            {short.MinValue, null}
        };

        public int Id { get; set; }

        [JsonIgnore]
        public short? RestrictionAction { get; set; }

        public string Severity => Map.TryGetValue(RestrictionAction ?? KnownDebtorRestrictions.NoRestriction, out var value) ? value : string.Empty;

        public string Description { get; set; }

        public static DebtorRestriction NotApplicable(int id)
        {
            return new DebtorRestriction {Id = id, RestrictionAction = short.MinValue};
        }
    }
}