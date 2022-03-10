using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using Newtonsoft.Json;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseView
    {
        IQueryable<OverviewSummary> GetSummary(int caseKey);
        Task<IQueryable<NameSummary>> GetNames(int caseKey);
    }

    class CaseView : ICaseView
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly INameAuthorization _nameAuthorization;

        public CaseView(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, INameAuthorization nameAuthorization)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _nameAuthorization = nameAuthorization;
        }

        public IQueryable<OverviewSummary> GetSummary(int caseKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var @case = _dbContext.Set<Case>().Where(_ => _.Id == caseKey);
            var validProperty = _dbContext.Set<ValidProperty>();
            var validCategory = _dbContext.Set<ValidCategory>();

            var data = from c in @case
                       join vp in _dbContext.Set<ValidProperty>() on new
                       {
                           c.PropertyTypeId,
                           CountryId = validProperty
                                       .Where(_ => _.PropertyTypeId == c.PropertyTypeId && new[] { c.CountryId, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                       .Select(_ => _.CountryId)
                                       .Min()
                       }
                        equals new { vp.PropertyTypeId, vp.CountryId }
                       join vc in _dbContext.Set<ValidCategory>() on new
                       {
                           c.PropertyTypeId,
                           CaseTypeId = c.TypeId,
                           CaseCategoryId = c.CategoryId,
                           CountryId = validCategory
                                       .Where(_ => _.PropertyTypeId == c.PropertyTypeId && _.CaseTypeId == c.TypeId
                                                                                        && _.CaseCategoryId == c.CategoryId
                                                                                        && new[] { c.CountryId, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                       .Select(_ => _.CountryId)
                                       .Min()
                       }
                        equals new { vc.PropertyTypeId, vc.CaseTypeId, vc.CaseCategoryId, vc.CountryId } into vc1
                       from vc in vc1.DefaultIfEmpty()
                       select new OverviewSummary
                       {
                           CaseKey = c.Id,
                           PropertyType = DbFuncs.GetTranslation(vp.PropertyName, null, vp.PropertyNameTId, culture),
                           CaseCategory = vc == null ? null : DbFuncs.GetTranslation(vc.CaseCategoryDesc, null, vc.CaseCategoryDescTid, culture),
                           Title = DbFuncs.GetTranslation(c.Title, null, c.TitleTId, culture)
                       };
            return data;
        }

        public async Task<IQueryable<NameSummary>> GetNames(int caseKey)
        {
            var user = _securityContext.User;
            var isExternalUser = user.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();
            var nameTypes = isExternalUser
                ? new[] { KnownNameTypes.Instructor, KnownNameTypes.Owner, KnownNameTypes.Inventor }
                : new[] { KnownNameTypes.Instructor, KnownNameTypes.Agent, KnownNameTypes.Owner, KnownNameTypes.Signatory, KnownNameTypes.StaffMember, KnownNameTypes.ChallengerOurSide, "G", KnownNameTypes.InstructorsClient, "V" };

            var data = from cn in _dbContext.Set<CaseName>().Where(_ => _.CaseId == caseKey && nameTypes.Contains(_.NameTypeId))
                       join nt in _dbContext.FilterUserNameTypes(user.Id, culture, isExternalUser, false) on cn.NameTypeId equals nt.NameType
                       join n in _dbContext.Set<Name>() on cn.NameId equals n.Id
                       select new NameSummary
                       {
                           NameTypeCode = nt.NameType,
                           NameId = cn.NameId,
                           Sequence = cn.Sequence,
                           NameType = nt.Description,
                           N = n,
                           NameCode = n.NameCode,
                           DisplayOrder = cn.NameTypeId == KnownNameTypes.Instructor ? 0
                               : cn.NameTypeId == KnownNameTypes.Agent ? 1
                               : cn.NameTypeId == KnownNameTypes.Owner ? 2
                               : cn.NameTypeId == "G" ? 3
                               : cn.NameTypeId == KnownNameTypes.InstructorsClient ? 4
                               : cn.NameTypeId == KnownNameTypes.ChallengerOurSide ? 5
                               : cn.NameTypeId == "V" ? 6
                               : cn.NameTypeId == KnownNameTypes.StaffMember ? 7
                               : cn.NameTypeId == KnownNameTypes.Signatory ? 8
                               : 9,
                           CanView = false
                       };

            if (!isExternalUser)
            {
                var caseNames = _dbContext.Set<CaseName>();
                var associatedNames = _dbContext.Set<AssociatedName>();
                var relatedName1 = from c in _dbContext.Set<Case>().Where(_ => _.Id == caseKey)
                                   join cn in _dbContext.Set<CaseName>() on new
                                   {
                                       CaseId = c.Id,
                                       NameTypeId = c.TypeId == KnownNameTypes.CopiesTo ? KnownNameTypes.ChallengerOurSide
                                           : c.TypeId == KnownNameTypes.Debtor ? "G"
                                           : c.TypeId == "F" ? KnownNameTypes.InstructorsClient
                                           : c.TypeId == KnownNameTypes.InstructorsClient ? "V"
                                           : KnownNameTypes.Owner
                                   }
                                    equals new { cn.CaseId, cn.NameTypeId }
                                   join an in _dbContext.Set<AssociatedName>() on new { Id = cn.NameId, Relationship = KnownNameRelations.ResponsibilityOf, c.PropertyTypeId } equals new { an.Id, an.Relationship, an.PropertyTypeId }
                                   where cn.Sequence == caseNames.Where(_ => _.CaseId == cn.CaseId && _.NameTypeId == cn.NameTypeId && _.ExpiryDate == null).Select(_ => _.Sequence).Min()
                                         && an.Sequence == associatedNames.Where(_ => _.Id == an.Id && _.Relationship == an.Relationship && _.PropertyTypeId == an.PropertyTypeId).Select(_ => _.Sequence).Min()
                                   select new
                                   {
                                       RELATEDNAME = an.RelatedNameId
                                   };

                var relatedName2 = from c in _dbContext.Set<Case>().Where(_ => _.Id == caseKey)
                                   join cn in _dbContext.Set<CaseName>() on new
                                   {
                                       CaseId = c.Id,
                                       NameTypeId = c.TypeId == "C" ? KnownNameTypes.ChallengerOurSide
                                           : c.TypeId == "D" ? "G"
                                           : c.TypeId == "F" ? KnownNameTypes.InstructorsClient
                                           : c.TypeId == "H" ? "V"
                                           : KnownNameTypes.Owner
                                   }
                                    equals new { cn.CaseId, cn.NameTypeId }
                                   join an in _dbContext.Set<AssociatedName>() on new { Id = cn.NameId, Relationship = KnownNameRelations.ResponsibilityOf } equals new { an.Id, an.Relationship }
                                   join an2 in _dbContext.Set<AssociatedName>() on new { Id = cn.NameId, Relationship = KnownNameRelations.ResponsibilityOf, c.PropertyTypeId } equals new { an2.Id, an2.Relationship, an2.PropertyTypeId } into an21
                                   from an2 in an21.DefaultIfEmpty()
                                   where an.PropertyTypeId == null && an2 == null && cn.Sequence == caseNames.Where(_ => _.CaseId == cn.CaseId && _.NameTypeId == cn.NameTypeId && _.ExpiryDate == null).Select(_ => _.Sequence).Min()
                                         && an.Sequence == associatedNames.Where(_ => _.Id == an.Id && _.Relationship == an.Relationship && _.PropertyTypeId == null).Select(_ => _.Sequence).Min()
                                   select new
                                   {
                                       RELATEDNAME = an.RelatedNameId
                                   };
                var relatedNameQuery = relatedName1.Concat(relatedName2);

                var forInternal = from res in relatedNameQuery
                                  join n in _dbContext.Set<Name>() on res.RELATEDNAME equals n.Id
                                  join nr in _dbContext.Set<NameRelation>() on new { RelationshipCode = KnownNameRelations.ResponsibilityOf } equals new { nr.RelationshipCode }
                                  select new NameSummary
                                  {
                                      NameTypeCode = KnownNameRelations.ResponsibilityOf,
                                      NameId = n.Id,
                                      Sequence = 1,
                                      NameType = nr.RelationDescription,
                                      N = n,
                                      NameCode = n.NameCode,
                                      DisplayOrder = 9,
                                      CanView = false
                                  };
                data = data.Concat(forInternal);
            }

            return !data.Any() ? data : (await GetFilteredNames(data)).OrderBy(_ => _.DisplayOrder).ThenBy(_ => _.NameTypeCode).ThenBy(_ => _.Sequence);
        }

        async Task<IQueryable<NameSummary>> GetFilteredNames(IQueryable<NameSummary> names)
        {
            var filteredNames = (await _nameAuthorization.AccessibleNames(names.Select(n => n.NameId)
                                                                        .Distinct().ToArray())).ToArray();

            return names.Select(d => new NameSummary
            {
                NameTypeCode = d.NameTypeCode,
                NameId = filteredNames.Contains(d.NameId) ? d.NameId : 0,
                Sequence = d.Sequence,
                NameType = d.NameType,
                N = filteredNames.Contains(d.NameId) ? d.N : null,
                NameCode = filteredNames.Contains(d.NameId) ? d.NameCode : null,
                DisplayOrder = d.DisplayOrder,
                CanView = !filteredNames.Contains(d.NameId)
            });
        }
    }

    public class OverviewSummary
    {
        public int CaseKey { get; set; }
        public string Title { get; set; }
        public string PropertyType { get; set; }
        public string CaseCategory { get; set; }
        public IEnumerable<NameSummary> Names { get; set; }
        public IEnumerable<CriticalDate> CriticalDates { get; set; }
        public IEnumerable<CaseTextData> Classes { get; set; }
    }

    public class NameSummary
    {
        public string NameTypeCode { get; set; }
        public int NameId { get; set; }
        public short Sequence { get; set; }
        public string NameType { get; set; }

        public bool CanView { get; set; }

        [JsonIgnore]
        public Name N { get; set; }

        public string NameCode { get; set; }
        public int? DisplayOrder { get; set; }

        public string Name => N?.Formatted();
    }
}