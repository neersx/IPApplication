using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Case = InprotechKaizen.Model.Cases.Case;
using Office = InprotechKaizen.Model.Cases.Office;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowCharacteristicsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IIndex<string, ICharacteristicsService> _characteristicsService;
        readonly IValidatedDefaultDateOfLawCharacteristic _defaultDateOfLawCharacteristic;
        readonly IWorkflowPermissionHelper _workflowPermissionHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IFormatDateOfLaw _formatDateOfLaw;

        public WorkflowCharacteristicsController(IDbContext dbContext,
            IIndex<string, ICharacteristicsService> characteristicsService,
            IWorkflowPermissionHelper workflowPermissionHelper,
            IPreferredCultureResolver preferredCultureResolver,
            IFormatDateOfLaw formatDateOfLaw, IValidatedDefaultDateOfLawCharacteristic defaultDateOfLawCharacteristic)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _characteristicsService = characteristicsService ?? throw new ArgumentNullException(nameof(characteristicsService));
            _workflowPermissionHelper = workflowPermissionHelper ?? throw new ArgumentNullException(nameof(workflowPermissionHelper));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _formatDateOfLaw = formatDateOfLaw ?? throw new ArgumentNullException(nameof(formatDateOfLaw));
            _defaultDateOfLawCharacteristic = defaultDateOfLawCharacteristic;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("defaultDateOfLaw")]
        public ValidatedCharacteristic GetDefaultDateOfLaw(int caseId, string actionId)
        {
            return _defaultDateOfLawCharacteristic.GetDefaultDateOfLaw(caseId, actionId);
        }

        [HttpGet]
        [Route("{criteriaId:int}/characteristics")]
        public dynamic GetWorkflowCharacteristics(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>()
                .Include(_ => _.Office)
                .Include(_ => _.PropertyType)
                .Include(_ => _.Country)
                .Include(_ => _.SubType)
                .Include(_ => _.Basis)
                .WhereWorkflowCriteria()
                .Single(_ => _.Id == criteriaId);

            var c = new WorkflowCharacteristics
            {
                Office = criteria.Office == null ? (int?)null : criteria.Office.Id,
                Jurisdiction = criteria.Country == null ? null : criteria.Country.Id,
                CaseType = criteria.CaseTypeId,
                PropertyType = criteria.PropertyType == null ? null : criteria.PropertyType.Code,
                CaseCategory = criteria.CaseCategoryId,
                SubType = criteria.SubType == null ? null : criteria.SubType.Code,
                Basis = criteria.Basis == null ? null : criteria.Basis.Code,
                Action = criteria.Action == null ? null : criteria.Action.Code
            };

            var vc = _characteristicsService[CriteriaPurposeCodes.EventsAndEntries].GetValidCharacteristics(c);

            bool isEditProtectionBlockedByParent;
            bool isEditProtectionBlockedByDescendants;
            _workflowPermissionHelper.GetEditProtectionLevelFlags(criteria, out isEditProtectionBlockedByParent, out isEditProtectionBlockedByDescendants);

            bool editBlockedByDescendants;
            var canEdit = _workflowPermissionHelper.CanEdit(criteria, out editBlockedByDescendants);
            if (!canEdit)
            {
                var culture = _preferredCultureResolver.Resolve();
                var translation = _dbContext.Set<Criteria>()
               .Select(_ => new
               {
                   _.Id,
                   DescriptionT = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
               }).Single(_ => _.Id == criteriaId);
                criteria.Description = translation.DescriptionT;
            }

            var actionType = criteria.Action?.ActionType;
            var tableCodePl = PicklistModelHelper.GetPicklistOrNull(criteria.TableCodeId, criteria.TableCode?.Name);

            return new
            {
                criteria.Id,
                CriteriaName = criteria.Description,
                criteria.InUse,
                criteria.IsLocalClient,
                criteria.IsProtected,
                Office = GetOffice(criteria.Office),
                Jurisdiction = GetJurisdiction(criteria.Country),
                vc.CaseType,
                vc.PropertyType,
                vc.CaseCategory,
                vc.SubType,
                vc.Basis,
                DateOfLaw = GetDateOfLaw(criteria.DateOfLaw),
                Action = vc.Action == null ? null : new { vc.Action.Key, vc.Action.Value, vc.Action.IsValid, vc.Action.Code, ActionType = actionType != null ? (ActionType)actionType : ActionType.Other },
                ExaminationType = criteria.TableCode?.TableTypeId == (short)TableTypes.ExaminationType ? tableCodePl : null,
                RenewalType = criteria.TableCode?.TableTypeId == (short)TableTypes.RenewalType ? tableCodePl : null,
                IsEditProtectionBlockedByParent = isEditProtectionBlockedByParent,
                IsEditProtectionBlockedByDescendants = isEditProtectionBlockedByDescendants
            };
        }

        public ValidatedCharacteristic GetOffice(Office office)
        {
            return office == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(office.Id.ToString(), office.Name);
        }

        public ValidatedCharacteristic GetJurisdiction(Country jurisdiction)
        {
            return jurisdiction == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(jurisdiction.Id, jurisdiction.Name);
        }

        public ValidatedCharacteristic GetDateOfLaw(DateTime? dateOfLaw)
        {
            return dateOfLaw == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(_formatDateOfLaw.AsId(dateOfLaw.Value),
                                              _formatDateOfLaw.Format(dateOfLaw.Value));
        }
    }
}