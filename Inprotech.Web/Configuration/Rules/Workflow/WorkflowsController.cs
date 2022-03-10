using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowsController : ApiController
    {
        readonly IIndex<string, ICharacteristicsValidator> _characteristicsValidator;
        readonly ICommonQueryService _commonQueryService;
        readonly IDbContext _dbContext;
        readonly IEntryService _entryService;
        readonly IInheritance _inheritance;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IValidEventService _validEventService;
        readonly IWorkflowInheritanceService _workflowInheritanceService;
        readonly IWorkflowMaintenanceService _workflowMaintenanceService;
        readonly IWorkflowSearch _workflowSearch;

        public WorkflowsController(IDbContext dbContext,
                                   ICommonQueryService commonQueryService,
                                   IIndex<string, ICharacteristicsValidator> characteristicsValidator,
                                   IWorkflowSearch workflowSearch,
                                   IInheritance inheritance,
                                   IValidEventService validEventService,
                                   IWorkflowPermissionHelper permissionHelper,
                                   IWorkflowInheritanceService workflowInheritanceService,
                                   IEntryService entryService,
                                   IPreferredCultureResolver preferredCultureResolver,
                                   IWorkflowMaintenanceService workflowMaintenanceService)
        {
            _dbContext = dbContext;
            _commonQueryService = commonQueryService;
            _characteristicsValidator = characteristicsValidator;
            _workflowSearch = workflowSearch;
            _inheritance = inheritance;
            _validEventService = validEventService;
            _permissionHelper = permissionHelper;
            _workflowInheritanceService = workflowInheritanceService;
            _entryService = entryService;
            _preferredCultureResolver = preferredCultureResolver;
            _workflowMaintenanceService = workflowMaintenanceService;
        }

        [HttpGet]
        [Route("{criteriaId:int}")]
        public dynamic GetWorkflow(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>().WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);
            bool editBlockedByDescendants;
            var canEdit = _permissionHelper.CanEdit(criteria, out editBlockedByDescendants);
            var canEditProtected = _permissionHelper.CanEditProtected();
            var isInherited = _dbContext.Set<Inherits>().Any(c => c.CriteriaNo == criteriaId);
            var isParent = _dbContext.Set<Inherits>().Any(c => c.FromCriteriaNo == criteriaId);
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

            return new
            {
                CanEdit = canEdit,
                EditBlockedByDescendants = editBlockedByDescendants,
                CanEditProtected = canEditProtected,
                HasOffices = _dbContext.Set<Office>().Any(),
                CriteriaId = criteria.Id,
                CriteriaName = criteria.Description,
                criteria.IsProtected,
                IsInherited = isInherited,
                IsHighestParent = isParent && !isInherited
            };
        }

        [HttpPost]
        [Route("")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic CreateWorkflow(WorkflowSaveModel formData)
        {
            var validated = _characteristicsValidator[CriteriaPurposeCodes.EventsAndEntries].Validate(formData);
            if (!validated.IsValidCombination) throw new Exception("Invalid Combination");
            if (string.IsNullOrWhiteSpace(formData.CriteriaName)) throw new Exception("Criteria Name is mandatory");

            return _workflowMaintenanceService.CreateWorkflow(formData);
        }

        [HttpPut]
        [Route("{criteriaId:int}")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic UpdateWorkflow(int criteriaId, WorkflowSaveModel formData)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var validated = _characteristicsValidator[CriteriaPurposeCodes.EventsAndEntries].Validate(formData);
            if (!validated.IsValidCombination) throw new Exception("Invalid Combination");
            if (string.IsNullOrWhiteSpace(formData.CriteriaName)) throw new Exception("Criteria Name is mandatory");

            return _workflowMaintenanceService.UpdateWorkflow(criteriaId, formData);
        }

        [HttpDelete]
        [Route("{criteriaId:int}")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void DeleteWorkflow(int criteriaId)
        {
            if (IsWorkflowUsedByCase(criteriaId)) throw new Exception("Used by case");

            var criteria = _dbContext.Set<Criteria>().Single(_ => _.Id == criteriaId);
            _permissionHelper.EnsureDeletePermission(criteria);

            var children = _dbContext.Set<Inherits>().Where(_ => _.FromCriteriaNo == criteriaId).Select(_ => _.CriteriaNo).ToList();

            using (var transaction = _dbContext.BeginTransaction())
            {
                children.ForEach(_workflowInheritanceService.BreakInheritance);

                _dbContext.Set<Criteria>().Remove(criteria);
                _dbContext.Delete<DatesLogic>(_ => _.CriteriaId == criteriaId);

                _dbContext.SaveChanges();
                transaction.Complete();
            }
        }

        [HttpPut]
        [Route("{criteriaId:int}/reset")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ResetWorkflow(int criteriaId, bool applyToDescendants, bool? updateRespNameOnCases = null)
        {
            var criteria = _dbContext.Set<Criteria>().Single(_ => _.Id == criteriaId);
            _permissionHelper.EnsureEditPermission(criteria);

            var result = _workflowMaintenanceService.ResetWorkflow(criteria, applyToDescendants, updateRespNameOnCases);

            return new
            {
                UsedByCase = result != "updateNameRespOnCases" && _workflowMaintenanceService.CheckCriteriaUsedByLiveCases(criteriaId),
                Status = result
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/usedByCase")]
        public bool GetWorkflowUsedByCase(int criteriaId)
        {
            return IsWorkflowUsedByCase(criteriaId);
        }

        internal bool IsWorkflowUsedByCase(int criteriaId)
        {
            var usedByOpenAction = _dbContext.Set<OpenAction>().Any(_ => _.CriteriaId == criteriaId);
            var usedByCaseChecklist = _dbContext.Set<CaseChecklist>().Any(_ => _.CriteriaId == criteriaId);
            var usedByCaseEvent = _dbContext.Set<CaseEvent>().Any(_ => _.CreatedByCriteriaKey == criteriaId);

            return usedByOpenAction || usedByCaseChecklist || usedByCaseEvent;
        }

        [HttpGet]
        [Route("{criteriaId:int}/events")]
        public PagedResults GetEvents(int criteriaId,
                                      [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                      CommonQueryParameters queryParameters)
        {
            var events = _inheritance.GetEventRulesWithInheritanceLevel(criteriaId).ToArray();

            queryParameters = CommonQueryParameters.Default.Extend(queryParameters);
            MapFilterParams(queryParameters);
            var result = _commonQueryService.Filter(events, queryParameters).ToArray();

            var total = result.Length;
            var orderedEvents = result.Select(_ => new
                                      {
                                          EventNo = _.EventId,
                                          _.Description,
                                          EventCode = _.Event.Code,
                                          _.DisplaySequence,
                                          Importance = _.Importance?.Description,
                                          _.ImportanceLevel,
                                          MaxCycles = _.NumberOfCyclesAllowed,
                                          InheritanceLevel = _.InheritanceLevel.ToString()
                                      })
                                      .OrderBy(_ => _.DisplaySequence);

            var pagedEvents = orderedEvents.Skip(queryParameters.Skip.Value)
                                           .Take(queryParameters.Take.Value);

            return new PagedResults(pagedEvents, total)
            {
                Ids = orderedEvents.Select(_ => _.EventNo)
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventdescendants")]
        public IEnumerable<dynamic> GetDescendantsWithoutEventEntry([ModelBinder] GetDescendantsForAddParams queryParams)
        {
            // get descendants for adding event
            if (queryParams.WithoutEventId.HasValue)
                return _inheritance.GetDescendantsWithoutEvent(queryParams.CriteriaId, queryParams.WithoutEventId.Value).Select(_ => new {_.Id, _.Description});

            throw new Exception("Id not provided");
        }

        [HttpGet]
        [Route("{criteriaId:int}/entrydescendants")]
        public IEnumerable<dynamic> GetDescendantsEntry([ModelBinder] GetDescendantsForAddParams queryParams)
        {
            // get descendants for adding entry
            if (!string.IsNullOrEmpty(queryParams.WithoutEntryDescription))
                return _inheritance.GetDescendantsWithoutEntry(queryParams.CriteriaId, queryParams.WithoutEntryDescription, queryParams.IsSeparator ?? false).Select(_ => new {_.criteria.Id, _.criteria.Description});

            throw new Exception("Id not provided");
        }

        [HttpGet]
        [Route("{criteriaId:int}/descendants")]
        public dynamic GetDescendants(int criteriaId)
        {
            return _inheritance.GetDescendants(criteriaId);
        }

        [HttpGet]
        [Route("{criteriaId:int}/events/filterData/{field:alpha}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(int criteriaId, string field)
        {
            var result = _inheritance.GetEventRulesWithInheritanceLevel(criteriaId);
            return
                result.OrderByDescending(x => x.ImportanceLevel ?? "ZZ").ToArray()
                      .Select(
                              _ => _.Importance == null ? new CodeDescription() : _commonQueryService.BuildCodeDescriptionObject(_.Importance.Level, _.Importance.Description))
                      .Distinct();
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventSearch")]
        public dynamic SearchForEventsReferencedIn(int criteriaId, int eventId)
        {
            return _workflowSearch.SearchForEventReferencedInCriteria(criteriaId, eventId).Select(_ => _.EventId);
        }

        [HttpGet]
        [Route("{criteriaId:int}/entryEventSearch")]
        public IEnumerable<short> SearchForEntryEventsReferencedIn(int criteriaId, int eventId)
        {
            var entries = _dbContext.Set<DataEntryTask>()
                                    .Include("AvailableEvents")
                                    .Where(e => (e.CriteriaId == criteriaId) &&
                                                ((e.HideEventNo == eventId) ||
                                                 (e.DisplayEventNo == eventId) ||
                                                 (e.DimEventNo == eventId) ||
                                                 e.AvailableEvents.Any(ae => (ae.EventId == eventId) || (ae.AlsoUpdateEventId == eventId))));

            return entries.Select(e => e.Id);
        }

        void MapFilterParams(CommonQueryParameters queryParameters)
        {
            if ((queryParameters == null) || (queryParameters.Filters == null)) return;

            foreach (var qp in queryParameters.Filters)
                if (qp.Field == "importance")
                    qp.Field = "importanceLevel";
        }

        [HttpGet]
        [Route("{criteriaId:int}/entries")]
        public dynamic GetEntries(int criteriaId,
                                  [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                  CommonQueryParameters queryParameters)
        {
            var entries = _inheritance.GetEntriesWithInheritanceLevel(criteriaId);
            return entries.Select(_ => new
            {
                EntryNo = _.Id,
                _.Description,
                _.DisplaySequence,
                InheritanceLevel = _.InheritanceLevel.ToString(),
                _.IsSeparator
            }).OrderBy(_ => _.DisplaySequence);
        }

        [HttpPut]
        [Route("{criteriaId:int}/events/{eventId:int}")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic AddEvent(int criteriaId, int eventId, int? insertAfterEventId = null, bool applyToChildren = false)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var newEvent = _validEventService.AddEvent(criteriaId, eventId, insertAfterEventId, applyToChildren);

            return new
            {
                EventNo = newEvent.EventId,
                newEvent.Description,
                EventCode = newEvent.Event.Code,
                newEvent.DisplaySequence,
                Importance = newEvent.Importance == null ? null : newEvent.Importance.Description,
                newEvent.ImportanceLevel,
                MaxCycles = newEvent.NumberOfCyclesAllowed
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/events/usedByCases")]
        public IEnumerable<dynamic> GetEventsUsedByCases(int criteriaId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "eventIds")]
                                                         int[] eventIds)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            return _validEventService.GetEventsUsedByCases(criteriaId, eventIds)
                                     .Select(ve => new
                                     {
                                         ve.EventId,
                                         ve.Description
                                     });
        }

        [HttpDelete]
        [Route("{criteriaId:int}/events")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void DeleteEvents(int criteriaId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "eventIds")]
                                 int[] eventIds, bool appliesToDescendants)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            _validEventService.DeleteEvents(criteriaId, eventIds, appliesToDescendants);
        }

        [HttpGet]
        [Route("{criteriaId:int}/parent")]
        public dynamic GetParent(int criteriaId)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);
            var inherits = _dbContext.Set<Inherits>().SingleOrDefault(_ => _.CriteriaNo == criteriaId);
            var parent = inherits?.FromCriteria;

            if (parent == null) return null;

            return new
            {
                parent.Id,
                parent.Description
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/events/descendants")]
        public dynamic GetDescendants(int criteriaId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "eventIds")]
                                      int[] eventIds, bool inheritedOnly)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var parent = _dbContext.Set<Inherits>().SingleOrDefault(_ => _.CriteriaNo == criteriaId);

            var descendantCriteriaIds = new HashSet<int>();

            foreach (var eventId in eventIds)
            {
                var ids = inheritedOnly
                    ? _inheritance.GetDescendantsWithInheritedEvent(criteriaId, eventId)
                    : _inheritance.GetDescendantsWithEvent(criteriaId, eventId);
                descendantCriteriaIds.AddRange(ids);
            }

            var descendants = _dbContext.Set<Criteria>()
                                        .WhereWorkflowCriteria()
                                        .Where(_ => descendantCriteriaIds.Contains(_.Id))
                                        .Select(_ => new
                                        {
                                            _.Id,
                                            _.Description
                                        })
                                        .ToArray();

            return new
            {
                Parent = parent == null ? null : new {parent.FromCriteria.Id, parent.FromCriteria.Description},
                Descendants = descendants
            };
        }

        [HttpPost]
        [Route("{criteriaId:int}/events/reorder")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ReorderEvent(int criteriaId, EventReorderRequest request)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            int? prevTargetId, nextTargetId;

            _validEventService.GetAdjacentEvents(criteriaId, request.TargetId, out prevTargetId, out nextTargetId);

            _validEventService.ReorderEvents(criteriaId, request.SourceId, request.TargetId, request.InsertBefore);

            return new
            {
                PrevTargetId = prevTargetId,
                NextTargetId = nextTargetId
            };
        }

        [HttpPost]
        [Route("{criteriaId:int}/events/descendants/reorder")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void ReorderDescendantEvents(int criteriaId, EventReorderRequest request)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            _validEventService.ReorderDescendantEvents(criteriaId, request.SourceId, request.TargetId, request.PrevTargetId, request.NextTargetId, request.InsertBefore);
        }

        [HttpPost]
        [Route("{criteriaId:int}/entries/reorder")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ReorderEntry(int criteriaId, EntryReorderRequest request)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);
            var culture = _preferredCultureResolver.Resolve();

            short? prevTargetId, nextTargetId;
            _entryService.GetAdjacentEntries(criteriaId, request.TargetId, out prevTargetId, out nextTargetId);
            _entryService.ReorderEntries(criteriaId, request.SourceId, request.TargetId, request.InsertBefore);

            var descendentIds = _inheritance.GetDescendantsWithMatchedDescription(criteriaId, request.SourceId);
            var descendents = _dbContext.Set<Criteria>()
                                        .WhereWorkflowCriteria()
                                        .Where(_ => descendentIds.Contains(_.Id))
                                        .Select(_ => new
                                        {
                                            _.Id,
                                            Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                        })
                                        .ToArray();
            return new
            {
                PrevTargetId = prevTargetId,
                NextTargetId = nextTargetId,
                Descendents = descendents
            };
        }

        [HttpPost]
        [Route("{criteriaId:int}/entries/descendants/reorder")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void ReorderDescendantEntries(int criteriaId, EntryReorderRequest request)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            _entryService.ReorderDescendantEntries(criteriaId, request.SourceId, request.TargetId, request.PrevTargetId, request.NextTargetId, request.InsertBefore);
        }

        [HttpPost]
        [Route("{criteriaId:int}/entries/")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic AddEntry(int criteriaId, AddEntryParams entryParams)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var result = _entryService.AddEntry(criteriaId, entryParams.EntryDescription, entryParams.InsertAfterEntryId, entryParams.ApplyToChildren, entryParams.IsSeparator);

            var newEntry = result as DataEntryTask;
            if (newEntry != null)
            {
                return new
                {
                    EntryNo = newEntry.Id,
                    newEntry.Description,
                    newEntry.DisplaySequence,
                    newEntry.IsSeparator
                };
            }

            return result;
        }

        [HttpPost]
        [Route("{criteriaId:int}/eventsentry/")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic AddEventsEntry(int criteriaId, string entryDescription, int[] eventNo, bool applyToChildren = false)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var newEntry = _entryService.AddEntryWithEvents(criteriaId, entryDescription, eventNo, applyToChildren);

            if (newEntry is DataEntryTask)
                return new
                {
                    EntryNo = newEntry.Id,
                    newEntry.Description,
                    newEntry.DisplaySequence
                };
            return newEntry;
        }

        [HttpGet]
        [Route("{criteriaId:int}/entries/descendants")]
        public IEnumerable<dynamic> GetDescendantsWithInheritedEntry(int criteriaId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "withInheritedEntryIds")]
                                                                     short[] entryIds)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            var ids = _inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteriaId, entryIds);

            return _dbContext.Set<Criteria>()
                             .WhereWorkflowCriteria()
                             .Where(_ => ids.Contains(_.Id))
                             .Select(_ => new
                             {
                                 _.Id,
                                 _.Description
                             })
                             .ToArray();
        }

        [HttpDelete]
        [Route("{criteriaId:int}/entries")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void DeleteEntries(int criteriaId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entryIds")]
                                  short[] entryIds, bool appliesToDescendants)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            _entryService.DeleteEntries(criteriaId, entryIds, appliesToDescendants);
        }

        public class EventReorderRequest
        {
            public bool InsertBefore { get; set; }
            public int? NextTargetId { get; set; }
            public int? PrevTargetId { get; set; }
            public int SourceId { get; set; }
            public int TargetId { get; set; }
        }

        public class EntryReorderRequest
        {
            public bool InsertBefore { get; set; }
            public short? NextTargetId { get; set; }
            public short? PrevTargetId { get; set; }
            public short SourceId { get; set; }
            public short TargetId { get; set; }
        }

        public class GetDescendantsForAddParams
        {
            public int CriteriaId { get; set; }
            public int? WithoutEventId { get; set; }
            public bool? IsSeparator { get; set; }

            [DisplayFormat(ConvertEmptyStringToNull = false)]
            public string WithoutEntryDescription { get; set; }
        }

        public class AddEntryParams
        {
            public string EntryDescription { get; set; }
            public bool IsSeparator { get; set; }
            public int? InsertAfterEntryId { get; set; }
            public bool ApplyToChildren { get; set; }
        }
    }
}