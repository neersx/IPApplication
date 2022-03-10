using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
#pragma warning disable 618

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowInheritanceService
    {
        string GetInheritanceTreeXml(IEnumerable<int> criteriaIds);
        void BreakInheritance(int criteriaId);
        void PushDownInheritanceTree(int parentCriteria, IEnumerable<ValidEvent> inheritedParentEvents, IEnumerable<DataEntryTask> inheritedParentEntries, bool replaceCommonRules);

        void ResetEventControl(Criteria criteria, bool applyToDescendants, bool updateRespNameOnCases, Criteria parent);
        void ResetEntries(Criteria criteria, bool applyToDescendants, Criteria parent);
    }

    public class WorkflowInheritanceService : IWorkflowInheritanceService
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWorkflowEntryInheritanceService _workflowEntryInheritanceService;
        readonly IWorkflowEventControlService _workflowEventControlService;
        readonly IValidEventService _validEventService;
        readonly IWorkflowEntryControlService _workflowEntryControlService;
        readonly IEntryService _entryService;
        readonly IInheritance _inheritance;
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;

        public WorkflowInheritanceService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
            IWorkflowEventInheritanceService workflowEventInheritanceService,IWorkflowEntryInheritanceService workflowEntryInheritanceService,
            IWorkflowEventControlService workflowEventControlService, IValidEventService validEventService,
            IWorkflowEntryControlService workflowEntryControlService, IEntryService entryService, IInheritance inheritance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _workflowEntryInheritanceService = workflowEntryInheritanceService;
            _workflowEventControlService = workflowEventControlService;
            _validEventService = validEventService;
            _workflowEntryControlService = workflowEntryControlService;
            _entryService = entryService;
            _inheritance = inheritance;
        }

        public string GetInheritanceTreeXml(IEnumerable<int> criteriaIds)
        {
            var result = _dbContext.GetWorkflowInheritanceTree(_preferredCultureResolver.Resolve(), criteriaIds).SingleOrDefault();
            return result?.Tree;
        }

        public void BreakInheritance(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>()
                                     .Single(_ => _.Id == criteriaId);

            criteria.ParentCriteriaId = null;

            // DB allows multiple inherits record for criteriano (edge case)
            _dbContext.Set<Inherits>()
                      .Where(_ => _.CriteriaNo == criteriaId).ToList()
                      .ForEach(_ => _dbContext.Set<Inherits>().Remove(_));
            _dbContext.SaveChanges();

            _workflowEventInheritanceService.BreakEventsInheritance(criteriaId);
            BreakEntriesInheritance(criteriaId);
        }

        public void PushDownInheritanceTree(int parentCriteria, IEnumerable<ValidEvent> inheritedParentEvents, IEnumerable<DataEntryTask> inheritedParentEntries, bool replaceCommonRules)
        {
            var newParentCriteriaEvents = inheritedParentEvents as ValidEvent[] ?? inheritedParentEvents.ToArray();
            var newParentCriteriaEntries = inheritedParentEntries as DataEntryTask[] ?? inheritedParentEntries.ToArray();

            var children = _inheritance.GetChildren(parentCriteria);

            foreach (var child in children)
            {
                var inheritedEvents = _workflowEventInheritanceService.InheritNewEventRules(child, newParentCriteriaEvents, replaceCommonRules);
                var inheritedEntries = _workflowEntryInheritanceService.InheritNewEntries(child, newParentCriteriaEntries, replaceCommonRules);
                PushDownInheritanceTree(child.Id, inheritedEvents, inheritedEntries, replaceCommonRules);
            }
        }

        public void ResetEventControl(Criteria criteria, bool applyToDescendants, bool updateRespNameOnCases, Criteria parent)
        {
            var parentEventIds = parent.ValidEvents.Select(_ => _.EventId).ToArray();
            var existingEventIds = criteria.ValidEvents.Select(_ => _.EventId);
            var eventsToReset = criteria.ValidEvents.Where(_ => parentEventIds.Contains(_.EventId)).ToArray();
            
            foreach (var u in eventsToReset)
            {
                _workflowEventControlService.ResetEventControl(criteria.Id, u.EventId, applyToDescendants, updateRespNameOnCases);
            }

            var eventIdsToAdd = parentEventIds.Where(_ => !existingEventIds.Contains(_)).ToArray();
            foreach (var id in eventIdsToAdd)
            {
                _validEventService.AddEvent(criteria.Id, id, null, applyToDescendants);
                _workflowEventControlService.ResetEventControl(criteria.Id, id, applyToDescendants, false);
            }

            var deleteIds = existingEventIds.Where(_ => !parentEventIds.Contains(_)).ToArray();
            _validEventService.DeleteEvents(criteria.Id, deleteIds, applyToDescendants);

            foreach (var v in criteria.ValidEvents)
            {
                v.DisplaySequence = parent.ValidEvents.SingleOrDefault(_ => _.EventId == v.EventId)?.DisplaySequence ?? 0;
            }
        }

        public void ResetEntries(Criteria criteria, bool applyToDescendants, Criteria parent)
        {
            var entriesToAdd = parent.DataEntryTasks.Where(_ => !_inheritance.HasSingleEntryMatch(criteria.DataEntryTasks, _.Description));
            var entriesToReset = criteria.DataEntryTasks.Where(_ => _inheritance.HasSingleEntryMatch(parent.DataEntryTasks, _.Description));
            var entriesToDelete = criteria.DataEntryTasks.Where(_ => !entriesToReset.Contains(_));

            foreach (var e in entriesToReset)
            {
                _workflowEntryControlService.ResetEntryControl(criteria.Id, e.Id, applyToDescendants);
            }

            foreach (var e in entriesToAdd)
            {
                var newEntry = _entryService.AddEntry(criteria.Id, e.Description, null, applyToDescendants, e.IsSeparator);
                _workflowEntryControlService.ResetEntryControl(criteria.Id, newEntry.Id, applyToDescendants);
            }

            _entryService.DeleteEntries(criteria.Id, entriesToDelete.Select(_ => _.Id).ToArray(), applyToDescendants);

            foreach (var v in criteria.DataEntryTasks)
            {
                v.DisplaySequence = parent.DataEntryTasks.FirstOrDefault(_ => _.Description == v.Description)?.DisplaySequence ?? 0;
            }
        }

        internal void BreakEntriesInheritance(int criteriaId)
        {
            _dbContext.Update(_dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaId),
                              _ => new DataEntryTask {ParentCriteriaId = null, ParentEntryId = null, Inherited = 0});

            _dbContext.Update(_dbContext.Set<AvailableEvent>().Where(_ => _.CriteriaId == criteriaId),
                              _ => new AvailableEvent {Inherited = 0});

            _dbContext.Update(_dbContext.Set<DocumentRequirement>().Where(_ => _.CriteriaId == criteriaId),
                              _ => new DocumentRequirement {Inherited = 0});

            _dbContext.Update(_dbContext.Set<UserControl>().Where(_ => _.CriteriaNo == criteriaId),
                              _ => new UserControl {Inherited = 0});

            _dbContext.Update(_dbContext.Set<GroupControl>().Where(_ => _.CriteriaId == criteriaId),
                              _ => new GroupControl {Inherited = 0});

            _dbContext.Update(_dbContext.Set<WindowControl>().Where(_ => _.CriteriaId == criteriaId && _.Name == "WorkflowWizard").SelectMany(_=>_.TopicControls),
                              _ => new TopicControl {IsInherited = false});
        }
    }
}