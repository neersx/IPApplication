using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowEntryControlController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IWorkflowEntryDetailService _entryDetails;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly IInheritance _inheritance;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWorkflowEntryControlService _workflowEntryControlService;
        readonly IWorkflowEntryStepsService _workflowEntryStepsService;
        readonly IDescriptionValidator _descriptionValidator;

        public WorkflowEntryControlController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                              IWorkflowEntryControlService workflowEntryControlService,
                                              IWorkflowEntryStepsService workflowEntryStepsService,
                                              IWorkflowEntryDetailService entryDetails,
                                              IWorkflowPermissionHelper permissionHelper,
                                              IInheritance inheritance,
                                              IDescriptionValidator descriptionValidator)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _workflowEntryControlService = workflowEntryControlService;
            _workflowEntryStepsService = workflowEntryStepsService;
            _entryDetails = entryDetails;
            _permissionHelper = permissionHelper;
            _inheritance = inheritance;
            _descriptionValidator = descriptionValidator;
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}")]
        public async Task<dynamic> GetEntryControl(int criteriaId, int entryId)
        {
            if (!_dbContext.Set<DataEntryTask>().Any(_ => _.Id == entryId && _.Criteria.Id == criteriaId))
                return new HttpResponseMessage(HttpStatusCode.NotFound);

            return await _workflowEntryControlService.GetEntryControl(criteriaId, entryId);
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/details")]
        public IEnumerable<dynamic> GetDetails(int criteriaId, int entryId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var eventControl = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId);

            var entries = _dbContext.Set<AvailableEvent>().Where(_ => _.CriteriaId == criteriaId && _.DataEntryTaskId == entryId);

            return from entry in entries
                   join eec in eventControl on entry.EventId equals eec.EventId into eec1
                   from entryEventControl in eec1.DefaultIfEmpty()
                   join auec in eventControl on entry.AlsoUpdateEventId equals auec.EventId into auec1
                   from alsoUpdateEventControl in auec1.DefaultIfEmpty()
                   orderby entry.DisplaySequence
                   select new InterimEntryEventDetails
                   {
                       IsInherited = entry.Inherited == 1,
                       EventId = entry.Event.Id,
                       BaseEventName = DbFuncs.GetTranslation(entry.Event.Description, null, entry.Event.DescriptionTId, culture),
                       EventToUpdateId = entry.AlsoUpdateEventId,
                       BaseEventToUpdate = DbFuncs.GetTranslation(entry.AlsoUpdateEvent.Description, null, entry.AlsoUpdateEvent.DescriptionTId, culture),
                       SpecificEventName = entryEventControl != null ? DbFuncs.GetTranslation(entryEventControl.Description, null, entryEventControl.DescriptionTId, culture) : null,
                       SpecificEventToUpdate = alsoUpdateEventControl != null ? DbFuncs.GetTranslation(alsoUpdateEventControl.Description, null, alsoUpdateEventControl.DescriptionTId, culture) : null,
                       EventDate = entry.EventAttribute,
                       DueDate = entry.DueAttribute,
                       Policing = entry.PolicingAttribute,
                       Period = entry.PeriodAttribute,
                       DueDateResp = entry.DueDateResponsibleNameAttribute,
                       OverrideDueDate = entry.OverrideDueAttribute,
                       OverrideEventDate = entry.OverrideEventAttribute
                   };
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/documents")]
        public IEnumerable<dynamic> GetDocuments(int criteriaId, int entryId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var documents = _dbContext.Set<DocumentRequirement>().Where(_ => _.CriteriaId == criteriaId && _.DataEntryTaskId == entryId)
                                      .Select(_ => new
                                              {
                                                  IsInherited = _.Inherited == 1,
                                                  DocumentId = (short?) _.Document.Id,
                                                  DocumentName = DbFuncs.GetTranslation(_.Document.Name, null, _.Document.NameTId, culture),
                                                  MustProduce = _.InternalMandatoryFlag == 1
                                              }).ToArray();

            return documents.Select(_ => new
                                    {
                                        _.IsInherited,
                                        _.MustProduce,
                                        Document = PicklistModelHelper.GetPicklistOrNull(_.DocumentId, _.DocumentName)

                                    }).OrderBy(_ => _.Document.Value);
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/steps")]
        public dynamic GetSteps(int criteriaId, int entryId)
        {
            return _workflowEntryStepsService.GetSteps(criteriaId, entryId);
        }
        
        [HttpPut]
        [Route("{criteriaId}/entrycontrol/{entryId}")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic SaveEntryDetails(int criteriaId, short entryId, WorkflowEntryControlSaveModel newValues)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);
            newValues.CriteriaId = criteriaId;
            newValues.Id = entryId;

            var entryToUpdate = _dbContext.Set<DataEntryTask>()
                                          .Single(_ => _.CriteriaId == criteriaId && _.Id == entryId);

            var errors = _entryDetails.ValidateChange(entryToUpdate, newValues).ToArray();
            if (errors.Any())
            {
                return new
                {
                    Status = "error",
                    Errors = errors
                };
            }

            _entryDetails.UpdateEntryDetail(entryToUpdate, newValues);

            return new
            {
                Status = "success"
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId}/descendants")]
        public dynamic GetEntryDescendants(int criteriaId, short entryId, string newEntryDescription = null)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var affectedCriteriaIds = _inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteriaId, new[] {entryId})
                                                  .ToArray();

            var affectedDescendents = _dbContext.Set<Criteria>()
                                                .WhereWorkflowCriteria()
                                                .Where(_ => affectedCriteriaIds.Contains(_.Id))
                                                .Select(_ => new
                                                        {
                                                            _.Id,
                                                            _.Description
                                                        }).ToArray();

            var entry = _dbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteriaId && _.Id == entryId);
            var breakingCriteria = Enumerable.Empty<int>();

            if (Helper.AreDescriptionsDifferent(entry.Description, newEntryDescription, !entry.IsSeparator) 
                 && _descriptionValidator.IsDescriptionUnique(criteriaId, entry.Description, newEntryDescription, entry.IsSeparator))
            {
                breakingCriteria = _descriptionValidator.IsDescriptionExisting(affectedCriteriaIds, newEntryDescription, entry.IsSeparator)
                                                        .Distinct()
                                                        .ToArray();
            }

            return new
            {
                Descendants = affectedDescendents.Where(_ => !breakingCriteria.Contains(_.Id)).ToArray(),
                Breaking = affectedDescendents.Where(_ => breakingCriteria.Contains(_.Id)).ToArray()
            };
        }

        [HttpPost]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/reset")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ResetEntryInheritance(int criteriaId, short entryId, bool appliesToDescendants = false)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);
            _workflowEntryControlService.ResetEntryControl(criteriaId, entryId, appliesToDescendants);
            return new
            {
                Status = "success"
            };
        }

        [HttpPost]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/break")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic BreakEntryInheritance(int criteriaId, short entryId)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);
            _workflowEntryControlService.BreakEntryControlInheritance(criteriaId, entryId);
            return new
            {
                Status = "success"
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/descendants/parent")]
        public dynamic GetDescendantsAndParentWithInheritedEntry(int criteriaId, short entryId)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var ids = _inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteriaId, new[] { entryId });
            var parent = _inheritance.GetParentEntryWithFuzzyMatch(_dbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteriaId && _.Id == entryId));

            return new
            {
                Descendants = _dbContext.Set<Criteria>()
                                        .WhereWorkflowCriteria()
                                        .Where(_ => ids.Contains(_.Id))
                                        .Select(_ => new
                                        {
                                            _.Id,
                                            _.Description
                                        }).ToArray(),
                Parent = new
                {
                    parent.Criteria.Id,
                    parent.Criteria.Description
                }
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrycontrol/{entryId:int}/useraccess")]
        public IEnumerable<dynamic> GetUserAccess(int criteriaId, int entryId)
        {
            var roles = _dbContext.Set<RolesControl>().Where(r => r.CriteriaId == criteriaId && r.DataEntryTaskId == entryId).OrderBy(_ => _.Role.RoleName);
            return roles.Select(r => new
            {
                Key = r.Role.Id,
                Value = r.Role.RoleName,
                IsInherited = r.Inherited ?? false
            });
        }
    }

    public class InterimEntryEventDetails
    {
        public bool IsInherited { get; set; }

        public PicklistModel<int> EntryEvent => PicklistModelHelper.GetPicklistOrNull((int?) EventId, EventName);

        public PicklistModel<int> EventToUpdate => PicklistModelHelper.GetPicklistOrNull(EventToUpdateId, EventToUpdateDescription);

        public short? EventDate { get; set; }

        public short? DueDate { get; set; }

        public short? Policing { get; set; }

        public short? Period { get; set; }

        public short? DueDateResp { get; set; }

        public short? OverrideDueDate { get; set; }

        public short? OverrideEventDate { get; set; }

        [JsonIgnore]
        public int EventId { get; set; }

        [JsonIgnore]
        public int? EventToUpdateId { get; set; }

        [JsonIgnore]
        public string BaseEventName { get; set; }

        [JsonIgnore]
        public string BaseEventToUpdate { get; set; }

        [JsonIgnore]
        public string SpecificEventName { get; set; }

        [JsonIgnore]
        public string SpecificEventToUpdate { get; set; }

        [JsonIgnore]
        public string EventName => SpecificEventName ?? BaseEventName;

        [JsonIgnore]
        public string EventToUpdateDescription => SpecificEventToUpdate ?? BaseEventToUpdate;
    }
}