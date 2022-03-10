using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail.CriteriaDetailEntry
{
    internal class CriteriaDetailDbSetup : DbSetup
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
        protected static readonly string ActionDescription = Fixture.Prefix("action");

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
            var count = (short) criteria.DataEntryTasks.Count;
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
            validEvent.DisplaySequence = (short) criteria.ValidEvents.Count;

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

        public void AddAvailableEvent(DataEntryTask entry, bool inherits = false)
        {
            var aeCount = entry.AvailableEvents.Count;

            entry.AvailableEvents.Add(new AvailableEvent(entry, AddEvent(ExistingEvent)) {Inherited = inherits ? 1 : 0, DisplaySequence = (short) (aeCount + 1)});

            DbContext.SaveChanges();
        }
    }
}