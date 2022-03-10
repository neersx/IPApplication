using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Checklists
{
    public interface IChecklistMaintenanceService
    {
        dynamic CreateChecklistCriteria(ChecklistSaveModel formData);
    }

    public class ChecklistMaintenanceService : IChecklistMaintenanceService
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly ICriteriaMaintenanceValidator _maintenanceValidator;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public ChecklistMaintenanceService(IDbContext dbContext,
                                           ILastInternalCodeGenerator lastInternalCodeGenerator,
                                           ICriteriaMaintenanceValidator maintenanceValidator,
                                           ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _maintenanceValidator = maintenanceValidator;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public dynamic CreateChecklistCriteria(ChecklistSaveModel formData)
        {
            ValidationError validation;

            if ((validation = _maintenanceValidator.ValidateCriteriaName(formData.CriteriaName)) != null)
            {
                return _maintenanceValidator.Error(validation);
            }

            if (formData.IsProtected && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create))
            {
                throw new Exception("does not have permission to create protected rules");
            }

            var criteria = new Criteria
            {
                IsProtected = formData.IsProtected,
                Description = formData.CriteriaName,
                RuleInUse = formData.InUse ? 1 : 0,
                OfficeId = formData.Office,
                CaseTypeId = formData.CaseType,
                CountryId = formData.Jurisdiction,
                PropertyTypeId = formData.PropertyType,
                CaseCategoryId = formData.CaseCategory,
                SubTypeId = formData.SubType,
                BasisId = formData.Basis,
                Profile = formData.Profile,
                ChecklistType = formData.Checklist,
                PurposeCode = CriteriaPurposeCodes.CheckList
            }.WithUnknownToDefault();
            if (formData.IsLocalClient == null)
            {
                criteria.LocalClientFlag = null;
            }
            else
            {
                criteria.LocalClientFlag = formData.IsLocalClient.Value ? 1 : 0;
            }

            if ((validation = _maintenanceValidator.ValidateDuplicateCriteria(criteria, true)) != null)
            {
                return _maintenanceValidator.Error(validation);
            }

            criteria.Id = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Criteria);

            _dbContext.Set<Criteria>().Add(criteria);
            _dbContext.SaveChanges();

            return new
            {
                Status = true,
                CriteriaId = criteria.Id
            };
        }
    }
}