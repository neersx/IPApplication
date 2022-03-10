using System;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICaseStatusReader
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        TableCode GetCaseStatusSummary(Case @case);
        string GetCaseStatusDescription(Status status);
        Task<(string CaseStatus, string RenewalStatus)> GetStatusDescriptions(int caseId, string culture);
    }

    public class CaseStatusReader : ICaseStatusReader
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseStatusReader(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public TableCode GetCaseStatusSummary(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var code = GetTableCode(@case);

            return _dbContext.Set<TableCode>().SingleOrDefault(_ => _.Id == code);
        }

        public string GetCaseStatusDescription(Status status)
        {
            var culture = _preferredCultureResolver.Resolve();
            if (_securityContext.User.IsExternalUser)
            {
                return status == null ? null : DbFuncs.GetTranslation(status.ExternalName, null, status.ExternalNameTId, culture);
            }
            return status == null ? null : DbFuncs.GetTranslation(status.Name, null, status.NameTId, culture);
        }

        public async Task<(string CaseStatus, string RenewalStatus)> GetStatusDescriptions(int caseId, string culture)
        {
            var result = await (from c in _dbContext.Set<Case>()
                         where c.Id == caseId
                         select new
                         {
                             InternalCaseStatus = c.CaseStatus != null ? DbFuncs.GetTranslation(c.CaseStatus.Name, null, c.CaseStatus.NameTId, culture) : null,
                             ExternalCaseStatus = c.CaseStatus != null ? DbFuncs.GetTranslation(c.CaseStatus.ExternalName, null, c.CaseStatus.ExternalNameTId, culture) : null,
                             InternalRenewalStatus = c.Property != null && c.Property.RenewalStatus != null ? DbFuncs.GetTranslation(c.Property.RenewalStatus.Name, null, c.Property.RenewalStatus.NameTId, culture) : null,
                             ExternalRenewalStatus = c.Property != null && c.Property.RenewalStatus != null ? DbFuncs.GetTranslation(c.Property.RenewalStatus.ExternalName, null, c.Property.RenewalStatus.ExternalNameTId, culture) : null
                         }).SingleAsync();

            return _securityContext.User.IsExternalUser
                ? (result.ExternalCaseStatus, result.ExternalRenewalStatus)
                : (result.InternalCaseStatus, result.InternalRenewalStatus);
        }

        static int GetTableCode(Case @case)
        {            
            if ((@case.CaseStatus != null && !@case.CaseStatus.IsLive) || 
                (@case.Property != null && @case.Property.RenewalStatus != null && !@case.Property.RenewalStatus.IsLive))
                return (int) KnownStatusCodes.Dead;

            if (@case.CaseStatus != null && @case.CaseStatus.IsRegistered)
                return (int)KnownStatusCodes.Registered;

            return (int)KnownStatusCodes.Pending;
        }
    }
}
