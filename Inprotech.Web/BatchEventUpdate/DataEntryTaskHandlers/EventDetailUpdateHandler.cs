using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Miscellaneous;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Cases.PostModificationTasks;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers
{
    public interface IEventDetailUpdateHandler
    {
        PolicingRequests ApplyChanges(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            DateTime whenMovedToLocation,
            AvailableEventModel[] availableEvents,
            Document[] documentsToGenerate);

        PolicingRequests ProcessPostModificationTasks(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<AvailableEventModel> availableEvents);
    }

    public class EventDetailUpdateHandler : IEventDetailUpdateHandler
    {
        readonly IChangeTracker _changeTracker;
        readonly ICurrentOfficialNumberUpdater _currentOfficialNumberUpdater;
        readonly IDbContext _dbContext;
        readonly IDocumentGenerator _documentGenerator;
        readonly IEnumerable<IPostCaseDetailModificationTask> _postCaseDetailModificationTasks;
        readonly Func<DateTime> _systemClock;

        public EventDetailUpdateHandler(
            IDbContext dbContext,
            IEnumerable<IPostCaseDetailModificationTask> postCaseDetailModificationTasks,
            IChangeTracker changeTracker,
            Func<DateTime> systemClock,
            IDocumentGenerator documentGenerator,
            ICurrentOfficialNumberUpdater currentOfficialNumberUpdater)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(postCaseDetailModificationTasks == null)
                throw new ArgumentNullException("postCaseDetailModificationTasks");
            if(changeTracker == null) throw new ArgumentNullException("changeTracker");
            if(systemClock == null) throw new ArgumentNullException("systemClock");
            if(documentGenerator == null) throw new ArgumentNullException("documentGenerator");
            if(currentOfficialNumberUpdater == null) throw new ArgumentNullException("currentOfficialNumberUpdater");

            _dbContext = dbContext;
            _postCaseDetailModificationTasks = postCaseDetailModificationTasks;
            _systemClock = systemClock;
            _documentGenerator = documentGenerator;
            _currentOfficialNumberUpdater = currentOfficialNumberUpdater;
            _changeTracker = changeTracker;
        }

        public PolicingRequests ApplyChanges(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            DateTime whenMovedToLocation,
            AvailableEventModel[] availableEvents,
            Document[] documentsToGenerate)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(availableEvents == null) throw new ArgumentNullException("availableEvents");
            if(documentsToGenerate == null) throw new ArgumentNullException("documentsToGenerate");

            if(dataEntryTask.OfficialNumberType != null)
            {
                CreateOrUpdateOfficialNumber(@case, dataEntryTask, officialNumber);
                _currentOfficialNumberUpdater.Update(@case);
            }

            var policingRequests = ApplyChangesFromAvailableEvents(@case, dataEntryTask, availableEvents);

            ApplyCaseLocationRecordal(@case, fileLocationId, whenMovedToLocation);

            if(documentsToGenerate.Any())
                _documentGenerator.QueueDocument(@case, dataEntryTask, documentsToGenerate, _systemClock());

            return policingRequests;
        }

        public PolicingRequests ProcessPostModificationTasks(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<AvailableEventModel> availableEvents)
        {
            var eventsToConsider = availableEvents.AsEventsToConsider();

            var requests = _postCaseDetailModificationTasks.SelectMany(
                                                                       t =>
                                                                       t.Run(@case, dataEntryTask, eventsToConsider)
                                                                        .PolicingRequests).ToArray();

            return new PolicingRequests(requests);
        }

        static void CreateOrUpdateOfficialNumber(Case @case, DataEntryTask dataEntrytask, string number)
        {
            var officialNumber = @case.CurrentOfficialNumberFor(dataEntrytask);
            if(officialNumber == null)
            {
                officialNumber = new OfficialNumber(dataEntrytask.OfficialNumberType, @case, number);
                officialNumber.MarkAsCurrent();
                @case.OfficialNumbers.Add(officialNumber);
            }
            else
            {
                officialNumber.Number = number;
            }
        }

        static CaseEvent GetOrPrepareAssociatedEvent(Case @case, DataEntryTask dataEntryTask, int eventId, short cycle)
        {
            var caseEvent = @case.CaseEvents.SingleOrDefault(ce => ce.EventNo == eventId && ce.Cycle == cycle);
            if(caseEvent == null)
            {
                caseEvent = new CaseEvent(@case.Id, eventId, cycle)
                            {
                                CreatedByCriteriaKey = dataEntryTask.CriteriaId,
                                CreatedByActionKey = dataEntryTask.Criteria.Action.Code
                            };
                @case.CaseEvents.Add(caseEvent);
            }
            return caseEvent;
        }

        PolicingRequests ApplyChangesFromAvailableEvents(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<AvailableEventModel> availableEvents)
        {
            var policingRequests = ApplyChangesFromAvailableEventsCore(@case, dataEntryTask, availableEvents).ToArray();

            return dataEntryTask.HasEventsRequiringAnImmediatePolicingService
                       ? new PolicingRequests(policingRequests, true)
                       : new PolicingRequests(policingRequests);
        }

        IEnumerable<IQueuedPolicingRequest> ApplyChangesFromAvailableEventsCore(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<AvailableEventModel> availableEvents)
        {
            foreach(var eventData in availableEvents.Where(ae => ae.HasChanged(@case)))
            {
                var caseEvent = GetOrPrepareAssociatedEvent(@case, dataEntryTask, eventData.EventId, eventData.Cycle);
                caseEvent.EventDate = eventData.EventDate;
                if (eventData.DueDate.HasValue && caseEvent.EventDueDate != eventData.DueDate)
                    caseEvent.IsDateDueSaved = 1;
                caseEvent.EventDueDate = eventData.DueDate;
                caseEvent.EnteredDeadline = eventData.EnteredDeadline;
                caseEvent.PeriodType = eventData.PeriodTypeId;

                if(eventData.IsStopPolicing.GetValueOrDefault())
                    caseEvent.IsOccurredFlag = 1;

                if (!eventData.EventDate.HasValue)
                    caseEvent.IsOccurredFlag = null;
                
                if(_changeTracker.HasChanged(caseEvent))
                    yield return new PoliceCaseEvent(caseEvent, dataEntryTask);

                if(string.Compare(
                                  caseEvent.EffectiveEventText(),
                                  eventData.EventText,
                                  StringComparison.InvariantCulture) != 0)
                {
                    caseEvent.EventLongText = string.IsNullOrEmpty(eventData.EventText.Trim()) ? null : eventData.EventText;
                    caseEvent.EventText = null;
                    caseEvent.IsLongEventText = 1;
                }
            }
        }

        void ApplyCaseLocationRecordal(Case @case, int? fileLocationId, DateTime whenMovedToLocation)
        {
            if(!fileLocationId.HasValue) return;

            var mostRecent = @case.MostRecentCaseLocation();
            if (mostRecent != null && mostRecent.FileLocationId == fileLocationId) return;
            var location = _dbContext.Set<TableCode>().Single(tc => tc.Id == fileLocationId);
            @case.RecordNewCaseLocation(new CaseLocation(@case, location, whenMovedToLocation), _dbContext);
        }
    }
}