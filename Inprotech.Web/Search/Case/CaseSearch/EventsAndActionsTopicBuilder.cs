using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using Action = Inprotech.Web.Picklists.Action;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class EventsAndActionsTopicBuilder : ITopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly EventNoteTypeController _eventNoteTypeController;
        readonly IActions _actions;

        public EventsAndActionsTopicBuilder(IDbContext dbContext, EventNoteTypeController eventNoteTypeController, IActions actions)
        {
            _dbContext = dbContext;
            _eventNoteTypeController = eventNoteTypeController;
            _actions = actions;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("eventsActions");

            var periodQuantity = filterCriteria.GetXPathNullableIntegerValue("Event/Period/Quantity");

            var dateRange = filterCriteria.GetXPathElement("Event/DateRange");

            var eventOperatorValue = filterCriteria.GetAttributeOperatorValueForXPathElement("Event", "Operator", Operators.EqualTo);
            dynamic eventOperator;
            dynamic evenWithInValue = null;

            if (periodQuantity != null && eventOperatorValue == "7")
            {
                eventOperator = periodQuantity > 0 ? "N" : "L";
                periodQuantity = Math.Abs(periodQuantity.Value);
                evenWithInValue = new { value = periodQuantity, type = filterCriteria.GetXPathStringValue("Event/Period/Type") };
            }
            else if (dateRange != null)
            {
                eventOperator = "sd";
            }
            else
            {
                eventOperator = eventOperatorValue;
            }

            var namesTopic = new EventsAndActionsTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                Event = GetEvents(filterCriteria.GetXPathStringValue("Event/EventKey")),
                EventOperator = eventOperator,
                EventForCompare = GetEvent(filterCriteria.GetXPathNullableIntegerValue("Event/EventKeyForCompare")),
                EventDatesOperator = eventOperator == "sd" ? eventOperatorValue : Operators.Between,
                EventWithinValue = evenWithInValue,
                StartDate = filterCriteria.GetXPathStringValue("Event/DateRange/From") != null ? Convert.ToDateTime(filterCriteria.GetXPathStringValue("Event/DateRange/From")) : (DateTime?)null,
                EndDate = filterCriteria.GetXPathStringValue("Event/DateRange/To") != null ? Convert.ToDateTime(filterCriteria.GetXPathStringValue("Event/DateRange/To")) : (DateTime?)null,
                OccurredEvent = filterCriteria.Element("Event")?.GetAttributeOperatorValue("ByEventDate") == "1",
                DueEvent = filterCriteria.Element("Event")?.GetAttributeOperatorValue("ByDueDate") == "1",
                IncludeClosedActions = filterCriteria.Element("Event")?.GetAttributeOperatorValue("IncludeClosedActions") == "1",
                ImportanceLevelOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("Event/ImportanceLevel", "Operator", Operators.Between),
                ImportanceLevelTo = filterCriteria.GetXPathStringValue("Event/ImportanceLevel/To"),
                ImportanceLevelFrom = filterCriteria.GetXPathStringValue("Event/ImportanceLevel/From"),
                ActionOperator = filterCriteria.GetAttributeOperatorValue("ActionKey", "Operator", Operators.EqualTo),
                ActionValue = GetActionByCode(filterCriteria.Element("ActionKey")?.GetStringValue()),
                ActionIsOpen = filterCriteria.Element("ActionKey")?.GetAttributeOperatorValue("IsOpen") == "1",
                IsRenewals = filterCriteria.Element("Event")?.GetAttributeOperatorValue("IsRenewalsOnly") == "1",
                IsNonRenewals = filterCriteria.Element("Event")?.GetAttributeOperatorValue("IsNonRenewalsOnly") == "1",
                EventNotesOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("Event/EventNoteText", "Operator", Operators.EqualTo),
                EventNotesText = filterCriteria.GetXPathStringValue("Event/EventNoteText"),
                EventNoteTypeOperator = filterCriteria.Element("EventNoteType")?.GetAttributeOperatorValue("Operator"),
                EventNoteType = _eventNoteTypeController.GetEventNoteTypeByKeys(filterCriteria.Element("EventNoteType")?.GetStringValue().StringToIntList(",").ToArray())
            };
            topic.FormData = namesTopic;
            return topic;
        }

        Event[] GetEvents(string keys)
        {
            var events = keys.StringToIntList(",");
            return _dbContext.Set<InprotechKaizen.Model.Cases.Events.Event>().Where(_ => events.Contains(_.Id))
                             .Select(_ => new Event
                             {
                                 Key = _.Id,
                                 Code = _.Code,
                                 Value = _.Description,
                                 MaxCycles = _.NumberOfCyclesAllowed,
                                 Importance = _.InternalImportance != null ? _.InternalImportance.Description : null,
                                 ImportanceLevel = _.InternalImportance != null ? _.InternalImportance.Level : null,
                                 EventCategory = _.Category != null ? _.Category.Name : null,
                                 EventGroup = _.Group != null ? _.Group.Name : null,
                                 EventNotesGroup = _.NoteGroup != null ? _.NoteGroup.Name : null
                             }).ToArray();
        }

        Event GetEvent(int? key)
        {
            if (key == null) return null;
            var data = GetEvents(key.ToString());
            return data.Any() ? data.First() : null;
        }

        Action GetActionByCode(string code)
        {
            var actiondata = _actions.GetActionByCode(code);
            if (actiondata == null) return null;
            return new Action(actiondata.Id, actiondata.Code, actiondata.Name, actiondata.Cycles, actiondata.ActionType, actiondata.ImportanceLevel, actiondata.IsDefaultJurisdiction);
        }

    }

    public class EventsAndActionsTopic
    {
        public int Id { get; set; }
        public dynamic EventOperator { get; set; }
        public Event[] Event { get; set; }
        public Event EventForCompare { get; set; }

        public string EventDatesOperator { get; set; }

        public dynamic EventWithinValue { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool OccurredEvent { get; set; }

        public bool DueEvent { get; set; }

        public bool IncludeClosedActions { get; set; }

        public string ImportanceLevelOperator { get; set; }

        public string ImportanceLevelFrom { get; set; }

        public string ImportanceLevelTo { get; set; }

        public bool IsRenewals { get; set; }

        public bool IsNonRenewals { get; set; }

        public string ActionOperator { get; set; }

        public Action ActionValue { get; set; }

        public bool ActionIsOpen { get; set; }

        public string EventNoteTypeOperator { get; set; }

        public EventNoteTypeModel[] EventNoteType { get; set; }

        public string EventNotesOperator { get; set; }

        public string EventNotesText { get; set; }

    }
}
