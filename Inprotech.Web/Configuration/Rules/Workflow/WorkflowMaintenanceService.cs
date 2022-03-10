using System;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowMaintenanceService
    {
        dynamic CreateWorkflow(WorkflowSaveModel formData);

        dynamic UpdateWorkflow(int criteriaId, WorkflowSaveModel formData);

        dynamic ResetWorkflow(Criteria criteria, bool applyToDescendants, bool? updateRespNameOnCases);

        bool CheckCriteriaUsedByLiveCases(int criteriaId);
    }

    internal class WorkflowMaintenanceService : IWorkflowMaintenanceService
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly IWorkflowEventControlService _workflowEventControlService;
        readonly IWorkflowInheritanceService _workflowInheritanceService;
        readonly ICriteriaMaintenanceValidator _criteriaMaintenanceValidator;
        readonly IWorkflowPermissionHelper _permissionHelper;

        public WorkflowMaintenanceService(IDbContext dbContext, IWorkflowPermissionHelper permissionHelper, ILastInternalCodeGenerator lastInternalCodeGenerator,
            IWorkflowEventControlService workflowEventControlService, IWorkflowInheritanceService workflowInheritanceService, ICriteriaMaintenanceValidator criteriaMaintenanceValidator)
        {
            _permissionHelper = permissionHelper;
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _workflowEventControlService = workflowEventControlService;
            _workflowInheritanceService = workflowInheritanceService;
            _criteriaMaintenanceValidator = criteriaMaintenanceValidator;
        }

        public dynamic CreateWorkflow(WorkflowSaveModel formData)
        {
            ValidationError validation;

            if ((validation = _criteriaMaintenanceValidator.ValidateCriteriaName(formData.CriteriaName)) != null)
                return _criteriaMaintenanceValidator.Error(validation);

            if (formData.IsProtected && !_permissionHelper.CanEditProtected())
                throw new Exception("does not have permission to make criteria protected");

            var criteria = new Criteria
            {
                IsProtected = formData.IsProtected,
                Description = formData.CriteriaName,
                RuleInUse = formData.InUse ? 1 : 0,
                OfficeId = formData.Office,
                CaseTypeId = formData.CaseType,
                CountryId = formData.Jurisdiction,
                PropertyTypeId = formData.PropertyType,
                ActionId = formData.Action,
                CaseCategoryId = formData.CaseCategory,
                SubTypeId = formData.SubType,
                BasisId = formData.Basis,
                DateOfLaw = formData.DateOfLaw == null ? null : DateTime.Parse(formData.DateOfLaw),
                TableCodeId = formData.ExaminationType ?? formData.RenewalType,
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries
            }.WithUnknownToDefault();
            if (formData.IsLocalClient == null)
                criteria.LocalClientFlag = null;
            else
                criteria.LocalClientFlag = formData.IsLocalClient.Value ? 1 : 0;

            if ((validation = _criteriaMaintenanceValidator.ValidateDuplicateCriteria(criteria)) != null)
                return _criteriaMaintenanceValidator.Error(validation);

            criteria.Id = _permissionHelper.CanCreateNegativeWorkflow()
                ? _lastInternalCodeGenerator.GenerateNegativeLastInternalCode(KnownInternalCodeTable.CriteriaMaxim)
                : _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Criteria);

            _dbContext.Set<Criteria>().Add(criteria);
            _dbContext.SaveChanges();

            _permissionHelper.GetEditProtectionLevelFlags(criteria, out bool isEditProtectionBlockedByParent, out bool isEditProtectionBlockedByDescendants);

            return new
            {
                Status = true,
                CriteriaId = criteria.Id,
                IsEditProtectionBlockedByParent = isEditProtectionBlockedByParent,
                IsEditProtectionBlockedByDescendants = isEditProtectionBlockedByDescendants
            };
        }

        public dynamic UpdateWorkflow(int criteriaId, WorkflowSaveModel formData)
        {
            ValidationError validation;

            if ((validation = _criteriaMaintenanceValidator.ValidateCriteriaName(formData.CriteriaName, criteriaId)) != null)
                return _criteriaMaintenanceValidator.Error(validation);

            var criteria = _dbContext.Set<Criteria>().WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);

            if (criteria.IsProtected != formData.IsProtected)
            {
                _permissionHelper.EnsureEditProtectionLevelAllowed(criteria, formData.IsProtected);
            }
            criteria.IsProtected = formData.IsProtected;

            criteria.Description = formData.CriteriaName;
            criteria.RuleInUse = formData.InUse ? 1 : 0;
            if (formData.IsLocalClient == null)
            {
                criteria.LocalClientFlag = null;
            }
            else
            {
                criteria.LocalClientFlag = formData.IsLocalClient.Value ? 1 : 0;
            }

            criteria.OfficeId = formData.Office;
            criteria.CaseTypeId = formData.CaseType;
            criteria.CountryId = formData.Jurisdiction;
            criteria.PropertyTypeId = formData.PropertyType;
            criteria.ActionId = formData.Action;
            criteria.CaseCategoryId = formData.CaseCategory;
            criteria.SubTypeId = formData.SubType;
            criteria.BasisId = formData.Basis;
            criteria.DateOfLaw = formData.DateOfLaw == null ? null : DateTime.Parse(formData.DateOfLaw);

            criteria.TableCodeId = formData.ExaminationType ?? formData.RenewalType;

            if ((validation = _criteriaMaintenanceValidator.ValidateDuplicateCriteria(criteria)) != null)
                return _criteriaMaintenanceValidator.Error(validation);

            _dbContext.SaveChanges();

            _permissionHelper.GetEditProtectionLevelFlags(criteria, out var isEditProtectionBlockedByParent, out var isEditProtectionBlockedByDescendants);

            return new
            {
                IsEditProtectionBlockedByParent = isEditProtectionBlockedByParent,
                IsEditProtectionBlockedByDescendants = isEditProtectionBlockedByDescendants
            };
        }

        public dynamic ResetWorkflow(Criteria criteria, bool applyToDescendants, bool? updateRespNameOnCases = null)
        {
            var parent = _dbContext.Set<Inherits>().Single(_ => _.CriteriaNo == criteria.Id).FromCriteria;

            var eventsToReset = criteria.ValidEvents.Where(_ => parent.ValidEvents.Select(p => p.EventId).Contains(_.EventId)).ToArray();
            if (updateRespNameOnCases == null && CheckDueDateRespNameChanges(parent, eventsToReset))
                return "updateNameRespOnCases";

            using (var ts = _dbContext.BeginTransaction())
            {
                _workflowInheritanceService.ResetEventControl(criteria, applyToDescendants, updateRespNameOnCases.GetValueOrDefault(), parent);

                _workflowInheritanceService.ResetEntries(criteria, applyToDescendants, parent);

                _dbContext.SaveChanges();

                ts.Complete();
            }

            return "Success";
        }

        bool CheckDueDateRespNameChanges(Criteria parent, ValidEvent[] eventsToReset)
        {
            var nameRespChanges = eventsToReset.Select(_ => _workflowEventControlService.CheckDueDateRespNameChange(parent.ValidEvents.Single(p => p.EventId == _.EventId), _));
            return nameRespChanges.Any(_ => _);
        }

        public bool CheckCriteriaUsedByLiveCases(int criteriaId)
        {
            var usedByCases = from cr in _dbContext.Set<Criteria>()
                              join oa in _dbContext.Set<OpenAction>()
                              on cr.Id equals oa.CriteriaId
                              join ca in _dbContext.Set<Case>()
                              on oa.CaseId equals ca.Id
                              where cr.Id == criteriaId &&
                                    (ca.CaseStatus == null || (ca.CaseStatus.LiveFlag ?? 1) == 1) &&
                                    (ca.Property == null || ca.Property.RenewalStatus == null || (ca.Property.RenewalStatus.LiveFlag ?? 1) == 1)
                              select true;

            return usedByCases.Any();
        }
    }
}