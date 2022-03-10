using System.Collections.Generic;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    class CriteriaDetailDbSetup : DbSetup
    {
        public static readonly string CriteriaPrefix = Fixture.Prefix("criteria");
        public static readonly string CriteriaDescription = CriteriaPrefix + "parent";
        public static readonly string ChildCriteriaDescription = CriteriaPrefix + "child";
        public static readonly string EventPrefix = Fixture.Prefix("event");
        public static readonly string ExistingEvent = EventPrefix + "1";
        public static readonly string ExistingEvent2 = EventPrefix + "2";
        public static readonly string ExistingEvent3 = EventPrefix + "3";
        public static readonly string EventToBeAdded = EventPrefix + "4";
        public static readonly string EventToBeAdded2 = EventPrefix + "5";
        static readonly string ActionDescription = Fixture.Prefix("action");

        public ScenarioData SetUp(string criteriaDescription = null)
        {
            if (criteriaDescription == null)
            {
                criteriaDescription = CriteriaDescription;
            }

            var criteria = AddCriteria(criteriaDescription);
            var child = AddCriteria(ChildCriteriaDescription, criteria.Id);

            Insert(new Inherits(child.Id, criteria.Id));

            var existingEvent = AddEvent(ExistingEvent, true);
            var existingEvent2 = AddEvent(ExistingEvent2);

            AddEvent(EventToBeAdded);
            AddEvent(EventToBeAdded2);

            var validEvent = AddValidEvent(criteria, existingEvent);

            AddValidEvent(criteria, existingEvent2);
            AddValidEvent(child, existingEvent, true, criteria.Id, existingEvent.Id);

            var parentTask = AddDataEntryTask(criteria, "Data Entry Task");
            AddDataEntryTask(child, "Data Entry Task", true, parentTask.ParentCriteriaId, parentTask.ParentEntryId);

            var newCase = new CaseBuilder(DbContext).Create(Fixture.Prefix());
            Insert(new CaseEvent(newCase.Id, existingEvent.Id, 1));

            var action = Insert(new Action(ActionDescription, id: "e2"));
            Insert(new OpenAction(action, newCase, 1, null, criteria, true));

            return new ScenarioData
            {
                Criteria = criteria,
                CriteriaId = criteria.Id,
                ChildCriteria = child,
                ChildCriteriaId = child.Id,
                ValidEventId = validEvent.EventId,
                EventId = existingEvent.Id,
                EventName = existingEvent.Description,
                EventId2 = existingEvent2.Id,
                ExistingEvent = existingEvent,
                CaseTypeName = newCase.Type.Name,
                PropertyTypeName = newCase.PropertyType.Name,
                ActionId = criteria.ActionId,
                SecondEventId = existingEvent2.Id
            };
        }

        public Criteria AddCriteria(string description, int? parentId = null)
        {
            var act = InsertWithNewId(new Action {Name = ActionDescription}).Code;
            return InsertWithNewId(new Criteria
                                   {
                                       Description = description,
                                       PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                       UserDefinedRule = 1,
                                       RuleInUse = 1,
                                       ActionId = act,
                                       ParentCriteriaId = parentId
                                   });
        }

        public Criteria AddChildCriteria(Criteria parent, string description)
        {
            var childCriteria = AddCriteria(description, parent.Id);
            Insert(new Inherits(childCriteria.Id, parent.Id));
            return childCriteria;
        }

        public DataEntryTask AddEntry(Criteria criteria, string entryDescription, short? parentEntryNo = null)
        {
            var count = (short)criteria.DataEntryTasks.Count;
            return Insert(new DataEntryTask(criteria, count)
                   {
                       Description = entryDescription,
                       Inherited = parentEntryNo.HasValue ? 1 : 0,
                       ParentCriteriaId = criteria.ParentCriteriaId,
                       ParentEntryId = parentEntryNo
                   });
        }
        
        public Event AddEvent(string description, bool withCompleteDetails = false)
        {
            var @event = InsertWithNewId(new Event
                                         {
                                             Description = description
                                         });

            @event.Code = "E2ECode" + @event.Id;
            @event.Notes = "E2ENotes" + @event.Id;

            if (withCompleteDetails)
            {
                @event.NumberOfCyclesAllowed = 10;
                @event.ShouldPoliceImmediate = true;
                @event.SuppressCalculation = true;
                @event.RecalcEventDate = true;
                @event.IsAccountingEvent = true;
            }

            return @event;
        }

        public ValidEvent AddValidEvent(Criteria criteria, Event @event, bool inherits = false, int? parentCriteriaNo = null, int? parentEventNo = null)
        {
            var validEvent = new ValidEvent(criteria, @event, @event.Description) {NumberOfCyclesAllowed = 1, ImportanceLevel = "5", Notes = "Some Notes"};
            validEvent.DisplaySequence = (short)criteria.ValidEvents.Count;

            if (inherits)
            {
                validEvent.Inherited = 1;
                validEvent.ParentCriteriaNo = parentCriteriaNo;
                validEvent.ParentEventNo = parentEventNo;
            }

            criteria.ValidEvents.Add(validEvent);

            DbContext.SaveChanges();

            return validEvent;
        }

        public DataEntryTask AddDataEntryTask(Criteria criteria, string entryDescription, bool inherits = false, int? parentCriteriaId = null, short? parentEntryId = null)
        {
            var etCount = criteria.DataEntryTasks.Count;

            var entry = new DataEntryTask(criteria, (short) (etCount + 1))
            {
                Description = entryDescription
            };

            if (inherits)
            {
                entry.Inherited = 1;
                entry.ParentCriteriaId = parentCriteriaId;
                entry.ParentEntryId = parentEntryId;
            }

            criteria.DataEntryTasks.Add(entry);

            DbContext.SaveChanges();

            return entry;
        }

        public Criteria AddCriteriaWithEventsInheritance()
        {
            var parentCriteria = AddCriteria(CriteriaDescription);
            var criteria = AddCriteria(ChildCriteriaDescription, parentCriteria.Id);

            Insert(new Inherits(criteria.Id, parentCriteria.Id));

            var fullyInheritedEvent = AddEvent(ExistingEvent);
            var partiallyInheritedEvent = AddEvent(ExistingEvent2);
            var notInheritedEvent = AddEvent(ExistingEvent3);

            var pFullyInheritedValidEvent = AddValidEvent(parentCriteria, fullyInheritedEvent);
            var pPartiallyInheritedValidEvent = AddValidEvent(parentCriteria, partiallyInheritedEvent);
            var pNotInheritedValidEvent = AddValidEvent(parentCriteria, notInheritedEvent);
            var cFullyInheritedValidEvent = AddValidEvent(criteria, fullyInheritedEvent, true);
            var cPartiallyInheritedValidEvent = AddValidEvent(criteria, partiallyInheritedEvent, true);
            var cNotInheritedValidEvent = AddValidEvent(criteria, notInheritedEvent);

            AddDueDateCalc(pFullyInheritedValidEvent);
            AddDueDateCalc(pPartiallyInheritedValidEvent);
            AddDueDateCalc(pPartiallyInheritedValidEvent);
            AddDueDateCalc(pNotInheritedValidEvent);

            AddDueDateCalc(cFullyInheritedValidEvent, true);
            AddDueDateCalc(cPartiallyInheritedValidEvent, true);
            AddDueDateCalc(cNotInheritedValidEvent);

            return criteria;
        }

        public Criteria AddCriteriaWithEntryInheritance()
        {
            var parentCriteria = AddCriteria(CriteriaDescription);
            var criteria = AddCriteria(ChildCriteriaDescription);

            Insert(new Inherits(criteria.Id, parentCriteria.Id));

            var entryPrefix = Fixture.Prefix("entry");
            var fullyInheritedEvent = entryPrefix + "1";
            var partiallyInheritedEvent = entryPrefix + "2";
            var notInheritedEvent = entryPrefix + "3";

            var pFullyInheritedValidEvent = AddDataEntryTask(parentCriteria, fullyInheritedEvent);
            var pPartiallyInheritedValidEvent = AddDataEntryTask(parentCriteria, partiallyInheritedEvent);
            var pNotInheritedValidEvent = AddDataEntryTask(parentCriteria, notInheritedEvent);

            var cFullyInheritedValidEvent = AddDataEntryTask(criteria, fullyInheritedEvent, true, parentCriteria.Id, pFullyInheritedValidEvent.Id);
            var cPartiallyInheritedValidEvent = AddDataEntryTask(criteria, partiallyInheritedEvent, true, parentCriteria.Id, pPartiallyInheritedValidEvent.Id);
            var cNotInheritedValidEvent = AddDataEntryTask(criteria, notInheritedEvent, false, parentCriteria.Id, pNotInheritedValidEvent.Id);

            AddAvailableEvent(pFullyInheritedValidEvent);
            AddAvailableEvent(pPartiallyInheritedValidEvent);
            AddAvailableEvent(pPartiallyInheritedValidEvent);
            AddAvailableEvent(pNotInheritedValidEvent);

            AddAvailableEvent(cFullyInheritedValidEvent, true);
            AddAvailableEvent(cPartiallyInheritedValidEvent, true);
            AddAvailableEvent(cNotInheritedValidEvent);

            return criteria;
        }

        public void AddDueDateCalc(ValidEvent validEvent, bool inherits = false)
        {
            if (validEvent.DueDateCalcs == null)
                validEvent.DueDateCalcs = new List<DueDateCalc>();
            
            validEvent.DueDateCalcs.Add(new DueDateCalcBuilder(DbContext).Create(validEvent));

            DbContext.SaveChanges();
        }

        public void AddRequiredEvent(ValidEvent validEvent,Event requiredEvent)
        {
            if (validEvent.RequiredEvents == null)
                validEvent.RequiredEvents = new List<RequiredEventRule>();

            var requiredEventRule = Insert(new RequiredEventRule(validEvent, requiredEvent));

            validEvent.RequiredEvents.Add(requiredEventRule);

            DbContext.SaveChanges();
        }
        
        public void AddAvailableEvent(DataEntryTask entry, bool inherits = false)
        {
            var aeCount = entry.AvailableEvents.Count;

            entry.AvailableEvents.Add(new AvailableEvent(entry, AddEvent(ExistingEvent)) {Inherited = inherits ? 1 : 0, DisplaySequence = (short) (aeCount + 1)});

            DbContext.SaveChanges();
        }

        public IEnumerable<int> AddValidEvents(Criteria criteria, int count)
        {
            for (var i = 0; i < count; i++)
            {
                var existingEvent = AddEvent(ExistingEvent);
                AddValidEvent(criteria, existingEvent);
                yield return existingEvent.Id;
            }
        }

        public class ScenarioData
        {
            public string CaseTypeName;
            public Criteria ChildCriteria;
            public int ChildCriteriaId;
            public Criteria Criteria;
            public int CriteriaId;
            public int EventId;
            public string EventName;
            public int EventId2;
            public Event ExistingEvent;
            public string PropertyTypeName;
            public int ValidEventId;
            public string ActionId;
            public int SecondEventId;
        }
    }
}