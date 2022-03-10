using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Cases.Details.DesignatedJurisdiction
{
    public interface IDesignatedJurisdictions
    {
        Task<IQueryable<DesignatedJurisdictionData>> Get(int caseKey);
    }

    internal class DesignatedJurisdictions : IDesignatedJurisdictions
    {
        readonly ICaseAuthorization _caseAuthorization;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public DesignatedJurisdictions(IDbContext dbContext, ISecurityContext securityContext, ICaseAuthorization caseAuthorization, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _caseAuthorization = caseAuthorization;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<IQueryable<DesignatedJurisdictionData>> Get(int caseKey)
        {
            var user = _securityContext.User;
            var isExternalUser = user.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();
            IQueryable<DesignatedJurisdictionData> data;
            var djRelatedCase = _dbContext.Set<InprotechKaizen.Model.Cases.RelatedCase>().Where(r => r.CaseId == caseKey && r.Relationship == KnownRelations.DesignatedCountry1);
            var accessibleCases = new int[0];
            if (!isExternalUser)
            {
                accessibleCases = (from ap in await _caseAuthorization.AccessibleCases(await (from rc in djRelatedCase
                                                                                              where rc.RelatedCaseId != null
                                                                                              select (int) rc.RelatedCaseId
                                                                                           ).ToArrayAsync())
                                   select ap).ToArray();
            }

            var relatedCasesForClasses = _dbContext.Set<InprotechKaizen.Model.Cases.RelatedCase>();

            var result = from c in _dbContext.Set<Case>().Where(_ => _.Id == caseKey)
                         join r in djRelatedCase on c.Id equals r.CaseId
                         join cr in _dbContext.Set<Case>() on r.RelatedCaseId equals cr.Id into cr1
                         from cr in cr1.DefaultIfEmpty()
                         join ct in _dbContext.Set<Country>() on cr != null ? cr.CountryId : r.CountryCode equals ct.Id
                         join cf in _dbContext.Set<CountryFlag>() on new {c.CountryId, FlagNumber = r.CurrentStatus} equals new {cf.CountryId, FlagNumber = (int?) cf.FlagNumber} into cf1
                         from cf in cf1.DefaultIfEmpty()
                         join g in _dbContext.Set<CountryGroup>() on new {MemberCountry = ct.Id, TreatyCode = c.CountryId} equals new {g.MemberCountry, TreatyCode = g.Id} into g1
                         from g in g1.DefaultIfEmpty()
                         join rc in _dbContext.Set<Case>() on r.RelatedCaseId equals rc.Id into rc1
                         from rc in rc1.DefaultIfEmpty()
                         select new
                         {
                             Jurisdiction = DbFuncs.GetTranslation(ct.Name, null, ct.NameTId, culture),
                             DesignatedStatus = cf == null ? null : DbFuncs.GetTranslation(cf.Name, null, cf.NameTId, culture),
                             CountryCode = ct.Id,
                             OfficialNumber = rc == null ? null : rc.CurrentOfficialNumber,
                             r.PriorityDate,
                             Classes = rc != null
                                 ? rc.LocalClasses
                                 : r.Class != null
                                     ? r.Class
                                     : r.RelationshipNo == relatedCasesForClasses.Where(_ => _.CaseId == r.CaseId && _.RelationshipNo == r.RelationshipNo && _.CountryCode == r.CountryCode).Select(_ => _.RelationshipNo).Min()
                                         ? c.LocalClasses
                                         : null,
                             InternalReference = rc == null ? null : rc.Irn,
                             RelatedCaseId = rc == null ? null : (int?) rc.Id,
                             CfCountryCode = cf == null ? null : cf.CountryId,
                             RcCaseStaus = rc == null || rc.CaseStatus == null ? null : rc.CaseStatus,
                             IsExtensionState = g == null ? null : g.AssociateMember.HasValue ? (bool?) (g.AssociateMember.Value == 1) : null,
                             r.Notes,
                             hasInternalAccess = rc == null || accessibleCases.Contains(rc.Id)
                         };

            if (!isExternalUser)
            {
                data = from r in result
                       join cni in _dbContext.Set<CaseName>() on new {CaseId = r.RelatedCaseId, NameTypeId = KnownNameTypes.Instructor} equals new {CaseId = (int?) cni.CaseId, cni.NameTypeId} into cni1
                       from cni in cni1.DefaultIfEmpty()
                       join cna in _dbContext.Set<CaseName>() on new {CaseId = r.RelatedCaseId, NameTypeId = KnownNameTypes.Agent} equals new {CaseId = (int?) cna.CaseId, cna.NameTypeId} into cna1
                       from cna in cna1.DefaultIfEmpty()
                       select new DesignatedJurisdictionData
                       {
                           Jurisdiction = r.Jurisdiction,
                           DesignatedStatus = r.DesignatedStatus,
                           CountryCode = r.CountryCode,
                           OfficialNumber = r.OfficialNumber,
                           PriorityDate = r.PriorityDate,
                           Classes = r.Classes == null ? null : r.Classes.Replace(",", ", "),
                           CaseStatus = r.RcCaseStaus == null ? null : DbFuncs.GetTranslation(r.RcCaseStaus.Name, null, r.RcCaseStaus.NameTId, culture),
                           IsExtensionState = r.IsExtensionState,
                           InstructorReference = cni == null ? null : cni.Reference,
                           AgentReference = cna == null ? null : cna.Reference,
                           Notes = r.Notes,
                           CaseKey = r.hasInternalAccess ? r.RelatedCaseId : null,
                           InternalReference = r.hasInternalAccess ? r.InternalReference : null,
                           CanView = r.hasInternalAccess
                       };
            }
            else
            {
                data = from r in result
                       join g in _dbContext.Set<CountryGroup>() on r.CountryCode equals g.MemberCountry
                       join fc in _dbContext.FilterUserCases(user.Id, true) on r.RelatedCaseId equals fc.CaseId into fc1
                       from fc in fc1.DefaultIfEmpty()
                       join p in _dbContext.Set<CaseProperty>() on r.RelatedCaseId equals p.CaseId into p1
                       from p in p1.DefaultIfEmpty()
                       join rs in _dbContext.Set<Status>() on new {Id = p == null ? null : p.RenewalStatusId} equals new {Id = (short?) rs.Id} into rs1
                       from rs in rs1.DefaultIfEmpty()
                       join st in _dbContext.Set<Status>() on new {Id = r.RcCaseStaus == null ? null : (short?) r.RcCaseStaus.Id}
                           equals new {Id = (short?) st.Id} into st1
                       from st in st1.DefaultIfEmpty()
                       join tc in _dbContext.Set<TableCode>() on new
                       {
                           Id = st != null && st.LiveFlag == 0 || rs != null && rs.LiveFlag == 0
                               ? (int?) KnownStatusCodes.Dead
                               : st != null && st.RegisteredFlag == 1
                                   ? (int?) KnownStatusCodes.Registered
                                   : r != null && r.RelatedCaseId != null
                                       ? (int?) KnownStatusCodes.Pending
                                       : null
                       }
                        equals new {Id = (int?) tc.Id} into tc1
                       from tc in tc1.DefaultIfEmpty()
                       where g.Id == r.CfCountryCode
                       select new DesignatedJurisdictionData
                       {
                           Jurisdiction = r.Jurisdiction,
                           DesignatedStatus = r.DesignatedStatus,
                           CountryCode = r.CountryCode,
                           OfficialNumber = r.OfficialNumber,
                           PriorityDate = r.PriorityDate,
                           Classes = r.Classes == null ? null : r.Classes.Replace(",", ", "),
                           CaseStatus = tc == null ? null : tc.Name,
                           ClientReference = fc == null ? null : fc.ClientReferenceNo,
                           IsExtensionState = r.IsExtensionState,
                           Notes = r.Notes,
                           CaseKey = fc != null ? r.RelatedCaseId : null,
                           InternalReference = fc != null ? r.InternalReference : null,
                           CanView = r.RelatedCaseId == null || fc != null
                       };
            }

            return data.OrderBy(_ => _.CountryCode).ThenBy(_ => _.PriorityDate).ThenBy(_ => _.Classes);
        }
    }
}