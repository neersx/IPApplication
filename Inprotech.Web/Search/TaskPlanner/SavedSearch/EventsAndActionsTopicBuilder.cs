using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Action = Inprotech.Web.Picklists.Action;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public class EventsAndActionsTopicBuilder : ITaskPlannerTopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IActions _actions;

        public EventsAndActionsTopicBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IActions actions)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _actions = actions;
        }

        public TaskPlannerSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new TaskPlannerSavedSearch.Topic("eventsAndActions")
            {
                FormData = new EventAndActions
                {
                    Event = new EventFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("EventKeys", "Operator"),
                        Value = GetEvents(filterCriteria.GetStringValue("EventKeys"))
                    },
                    EventCategory = new EventCategoryFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("EventCategoryKeys", "Operator"),
                        Value = GetEventCategories(filterCriteria.GetStringValue("EventCategoryKeys"))
                    },
                    EventGroup = new EventGroupFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("EventGroupKeys", "Operator"),
                        Value = GetEventGroups(filterCriteria.GetStringValue("EventGroupKeys"))
                    },
                    EventNoteType = new EventNoteTypeFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("EventNoteTypeKeys", "Operator"),
                        Value = GetEventNoteTypes(filterCriteria.GetStringValue("EventNoteTypeKeys"))
                    },
                    Action = new ActionFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValueForXPathElement("Actions/ActionKeys", "Operator", Operators.EqualTo),
                        Value = GetActions(filterCriteria.GetXPathStringValue("Actions/ActionKeys"))
                    },
                    EventNotes = new EventNotesFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValueForXPathElement("EventNoteText", "Operator", Operators.StartsWith),
                        Value = filterCriteria.GetStringValue("EventNoteText")
                    },
                    IsRenewals = filterCriteria.Element("Actions") == null || filterCriteria.Element("Actions").GetAttributeOperatorValue("IsRenewalsOnly") == "1",
                    IsNonRenewals = filterCriteria.Element("Actions") == null || filterCriteria.Element("Actions").GetAttributeOperatorValue("IsNonRenewalsOnly") == "1",
                    IsClosed = filterCriteria.Element("Actions")?.GetAttributeOperatorValue("IncludeClosed") == "1"
                }
            };

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
                                 Value = _.Description
                             }).ToArray();
        }

        EventCategory[] GetEventCategories(string keys)
        {
            var eventCategoryIds = keys.StringToIntList(",");
            var culture = _preferredCultureResolver.Resolve();

            var eventCategories = _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>()
                                            .Where(_ => eventCategoryIds.Contains(_.Id))
                                            .Select(_ => new EventCategory
                                            {
                                                Key = _.Id,
                                                Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                            }).ToArray();
            return eventCategories;
        }

        TableCodePicklistController.TableCodePicklistItem[] GetEventGroups(string keys)
        {
            var eventGroupIds = keys.StringToIntList(",");
            var culture = _preferredCultureResolver.Resolve();
            var matchingType = TableTypeHelper.MatchingType("eventgroup");

            return _dbContext.Set<TableCode>()
                      .Where(_ => _.TableTypeId == matchingType && eventGroupIds.Contains(_.Id))
                      .Select(_ => new TableCodePicklistController.TableCodePicklistItem
                      {
                          Key = _.Id,
                          Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                          Code =_.UserCode,
                          TypeId = _.TableTypeId
                      }).ToArray();
        }

        EventNoteTypeModel[] GetEventNoteTypes(string keys)
        {
            var eventNoteTypeIds = keys.StringToIntList(",");
            var culture = _preferredCultureResolver.Resolve();

            return _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventNoteType>()
                             .Where(e => eventNoteTypeIds.Contains(e.Id)).ToArray()
                             .Select(_ => new EventNoteTypeModel
                             {
                                 Key = _.Id.ToString(),
                                 Value = DbFuncs.GetTranslation(string.Empty, _.Description, _.DescriptionTId, culture),
                                 IsExternal = _.IsExternal
                             }).ToArray();
        }

        Action[] GetActions(string keys)
        {
            if (string.IsNullOrEmpty(keys)) return new Action[0];

            var actionKeys = keys.Split(',');

            return _actions.Get(string.Empty, string.Empty, string.Empty)
                           .Where(_ => actionKeys.Contains(_.Code))
                           .Select(_ => new Action(_.Id, _.Code, _.Name, _.Cycles, _.ActionType, _.ImportanceLevel,_.IsDefaultJurisdiction)).ToArray();
        }
    }

    public class EventAndActions
    {
        public EventFormData Event { get; set; }
        public EventCategoryFormData EventCategory { get; set; }
        public EventGroupFormData EventGroup { get; set; }
        public EventNoteTypeFormData EventNoteType { get; set; }
        public ActionFormData Action { get; set; }
        public EventNotesFormData EventNotes { get; set; }
        public bool IsRenewals { get; set; }
        public bool IsNonRenewals { get; set; }
        public bool IsClosed { get; set; }
    }

    public class EventFormData
    {
        public string Operator { get; set; }
        public Event[] Value { get; set; }
    }

    public class EventCategoryFormData
    {
        public string Operator { get; set; }
        public EventCategory[] Value { get; set; }
    }

    public class EventGroupFormData
    {
        public string Operator { get; set; }
        public TableCodePicklistController.TableCodePicklistItem[] Value { get; set; }
    }

    public class EventNoteTypeFormData
    {
        public string Operator { get; set; }
        public EventNoteTypeModel[] Value { get; set; }
    }

    public class ActionFormData
    {
        public string Operator { get; set; }
        public Action[] Value { get; set; }
    }

    public class EventNotesFormData
    {
        public string Operator { get; set; }
        public string Value { get; set; }
    }
}
