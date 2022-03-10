using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules
{
    public interface ICriteriaMaintenanceValidator
    {
        ValidationError ValidateDuplicateCriteria(Criteria criteria, bool checkInUse = false);
        ValidationError ValidateCriteriaName(string criteriaName, int? criteriaId = null);
        dynamic Error(dynamic error);
    }

    public class CriteriaMaintenanceValidator : ICriteriaMaintenanceValidator
    {
        readonly IDbContext _dbContext;

        public CriteriaMaintenanceValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public ValidationError ValidateDuplicateCriteria(Criteria criteria, bool checkInUse = false)
        {
            Criteria duplicateCriteria;
            return (duplicateCriteria = _dbContext.Set<Criteria>().WhereUnknownToDefault().FirstOrDefault(_ => ((!checkInUse && criteria.RuleInUse != 0 && _.RuleInUse == 1) || checkInUse) && /////Only match rules that are InUse, allow to save duplicate rules if not InUse
                                                                                                               (criteria.Id == 0 || _.Id != criteria.Id) &&
                                                                                                               _.PurposeCode == criteria.PurposeCode &&
                                                                                                               _.ActionId == criteria.ActionId &&
                                                                                                               _.BasisId == criteria.BasisId &&
                                                                                                               _.CaseCategoryId == criteria.CaseCategoryId &&
                                                                                                               _.CaseTypeId == criteria.CaseTypeId &&
                                                                                                               _.CountryId == criteria.CountryId &&
                                                                                                               _.OfficeId == criteria.OfficeId &&
                                                                                                               _.PropertyTypeId == criteria.PropertyTypeId &&
                                                                                                               _.SubTypeId == criteria.SubTypeId &&
                                                                                                               _.LocalClientFlag == criteria.LocalClientFlag &&
                                                                                                               _.UserDefinedRule == criteria.UserDefinedRule &&
                                                                                                               _.Profile == criteria.Profile &&
                                                                                                               _.ChecklistType == criteria.ChecklistType &&
                                                                                                               _.DateOfLaw == criteria.DateOfLaw &&
                                                                                                               _.TableCodeId == criteria.TableCodeId
                                                                                                         )) != null ? new ValidationError(checkInUse ? "criteriaDuplicate" : "characteristicsDuplicate", duplicateCriteria.Id.ToString()) : CommonValidations.Validate(criteria).FirstOrDefault();
        }

        public ValidationError ValidateCriteriaName(string criteriaName, int? criteriaId = null)
        {
            if (string.IsNullOrEmpty(criteriaName))
            {
                return new ValidationError("criteriaName", "required");
            }

            return !IsNameUnique(criteriaName, criteriaId) ? new ValidationError("criteriaName", "notunique") : null;
        }

        public dynamic Error(dynamic error)
        {
            return new
            {
                Status = false,
                Error = error
            };
        }

        bool IsNameUnique(string criteriaName, int? criteriaId)
        {
            return !_dbContext.Set<Criteria>().Any(_ => _.Description == criteriaName && (!criteriaId.HasValue || _.Id != criteriaId));
        }
    }
}