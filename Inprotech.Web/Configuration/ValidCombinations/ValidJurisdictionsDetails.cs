using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System.Linq;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidJurisdictionsDetails
    {
        IQueryable<JurisdictionSearch> SearchValidJurisdiction(ValidCombinationSearchCriteria searchCriteria);
    }

    public class ValidJurisdictionDetails : IValidJurisdictionsDetails
    {
        readonly IDbContext _dbContext;

        public ValidJurisdictionDetails(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<JurisdictionSearch> SearchValidJurisdiction(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = GetValidPropertyTypes()
                .Concat(GetValidActions())
                .Concat(GetValidCategories())
                .Concat(GetValidSubTypes())
                .Concat(GetValidBasis())
                .Concat(GetValidStatus())
                .Concat(GetValidChecklist())
                .Concat(GetValidRelationships())
                .Where(_ => !searchCriteria.Jurisdictions.Any() || searchCriteria.Jurisdictions.Contains(_.CountryCode));

            return result.OrderBy(r => r.Country).ThenBy(r => r.PropertyType)
                         .ThenBy(r => r.CaseType).ThenBy(r => r.Action).ThenBy(r => r.Category)
                         .ThenBy(r => r.SubType).ThenBy(r => r.Basis)
                         .ThenBy(r => r.Status).ThenBy(r => r.Checklist).ThenBy(r => r.Relationship);
        }

        IQueryable<JurisdictionSearch> GetValidPropertyTypes()
        {
            return _dbContext.Set<ValidProperty>()
                             .Select(
                                     vp =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vp.CountryId,
                                             Country = vp.Country.Name,
                                             PropertyType = vp.PropertyName,
                                             CaseType = null,
                                             Action = null,
                                             Category = null,
                                             SubType = null,
                                             Basis = null,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidActions()
        {
            return _dbContext.Set<ValidAction>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = vc.CaseType.Name,
                                             Action = vc.ActionName,
                                             Category = null,
                                             SubType = null,
                                             Basis = null,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidCategories()
        {
            return _dbContext.Set<ValidCategory>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = vc.CaseType.Name,
                                             Action = null,
                                             Category = vc.CaseCategoryDesc,
                                             SubType = null,
                                             Basis = null,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidSubTypes()
        {
            return _dbContext.Set<ValidSubType>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = vc.CaseType.Name,
                                             Action = null,
                                             Category = vc.ValidCategory.CaseCategory.Name,
                                             SubType = vc.SubTypeDescription,
                                             Basis = null,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidBasis()
        {
            return _dbContext.Set<ValidBasis>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = null,
                                             Action = null,
                                             Category = null,
                                             SubType = null,
                                             Basis = vc.BasisDescription,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidStatus()
        {
            return _dbContext.Set<ValidStatus>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = vc.CaseType.Name,
                                             Action = null,
                                             Category = null,
                                             SubType = null,
                                             Basis = null,
                                             Status = vc.Status.Name,
                                             Checklist = null,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidChecklist()
        {
            return _dbContext.Set<ValidChecklist>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = vc.CaseType.Name,
                                             Action = null,
                                             Category = null,
                                             SubType = null,
                                             Basis = null,
                                             Status = null,
                                             Checklist = vc.ChecklistDescription,
                                             Relationship = null
                                         });
        }

        IQueryable<JurisdictionSearch> GetValidRelationships()
        {
            return _dbContext.Set<ValidRelationship>()
                             .Select(
                                     vc =>
                                         new JurisdictionSearch
                                         {
                                             CountryCode = vc.CountryId,
                                             Country = vc.Country.Name,
                                             PropertyType = vc.PropertyType.Name,
                                             CaseType = null,
                                             Action = null,
                                             Category = null,
                                             SubType = null,
                                             Basis = null,
                                             Status = null,
                                             Checklist = null,
                                             Relationship = vc.Relationship.Description
                                         });
        }
    }
}
