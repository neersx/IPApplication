using System;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Checklists
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Delete)]
    [RoutePrefix("api/configuration/rules/checklist-configuration")]
    public class ChecklistMaintenanceController : ApiController
    {
        readonly IIndex<string, ICharacteristicsValidator> _characteristicsValidator;
        readonly IChecklistMaintenanceService _checklistMaintenanceService;

        public ChecklistMaintenanceController(IIndex<string, ICharacteristicsValidator> characteristicsValidator, IChecklistMaintenanceService checklistMaintenanceService)
        {
            _characteristicsValidator = characteristicsValidator;
            _checklistMaintenanceService = checklistMaintenanceService;
        }

        [HttpPut]
        [Route("add")]
        [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)]
        [AppliesToComponent(KnownComponents.Checklist)]
        public dynamic CreateWorkflow(ChecklistSaveModel formData)
        {
            var validated = _characteristicsValidator[CriteriaPurposeCodes.CheckList].Validate(formData);
            if (!validated.IsValidCombination) throw new Exception("Invalid Combination");
            if (string.IsNullOrWhiteSpace(formData.CriteriaName)) throw new Exception("Criteria Name is mandatory");

            return _checklistMaintenanceService.CreateChecklistCriteria(formData);
        }
    }

    public class ChecklistSaveModel : WorkflowCharacteristics
    {
        public string CriteriaName { get; set; }
        public bool? IsLocalClient { get; set; }
        public bool IsProtected { get; set; }
        public bool InUse { get; set; }

    }
}
