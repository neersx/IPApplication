using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/events")]
    public class EventsPicklistController : ApiController
    {
        readonly ICommonQueryService _commonQueryService;
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;
        readonly IEventsPicklistMaintenance _eventsPicklistMaintenance;
        readonly IEventMatcher _matcher;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public EventsPicklistController(IDbContext dbContext, IPreferredCultureResolver cultureResolver, IEventMatcher matcher, IEventsPicklistMaintenance eventsPicklistMaintenance, ICommonQueryService commonQueryService, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
            _matcher = matcher;
            _eventsPicklistMaintenance = eventsPicklistMaintenance;
            _commonQueryService = commonQueryService;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Event), ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public PagedResults Events([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", int? criteriaId = null, bool picklistSearch = false)
        {
            if (!picklistSearch && !string.IsNullOrWhiteSpace(search))
                criteriaId = null;

            var all = _commonQueryService.Filter(MatchingItems(search, criteriaId), queryParameters).ToArray();

            var result = Helpers.GetPagedResults(all, queryParameters, x => x.Key.ToString(), x => x.Value, search);
            result.Ids = Helpers.GetPagedResults(all, new CommonQueryParameters {SortDir = queryParameters?.SortDir, SortBy = queryParameters?.SortBy, Take = all.Length}, x => x.Key.ToString(), x => x.Value, search)
                                .Data.Select(_ => _.Key);

            return result;
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public IEnumerable<object> GetFilterDataForColumn(string search)
        {
            return GetFilterData(MatchingItems(search));
        }

        IEnumerable<Event> MatchingItems(string search, int? criteriaId = null)
        {
            return from e in _matcher.MatchingItems(search, criteriaId)
                   select new Event
                          {
                              Key = e.Key,
                              Code = e.Code,
                              Value = e.Value,
                              MaxCycles = e.MaxCycles,
                              Importance = e.Importance,
                              ImportanceLevel = e.ImportanceLevel,
                              Alias = e.Alias,
                              ValidEventDescription = e.ValidEventDescription,
                              EventCategory = e.EventCategory,
                              EventGroup = e.EventGroup,
                              EventNotesGroup = e.EventNotesGroup
                          };
        }

        static IEnumerable<object> GetFilterData(IEnumerable<Event> result)
        {
            var r = result.OrderBy(q => q.ImportanceLevel)
                          .Select(v => new {Code = v.Importance ?? string.Empty, Description = v.Importance ?? "None"})
                          .Distinct();
            return r;
        }

        [HttpGet]
        [Route("{eventId}")]
        public dynamic Event(int eventId)
        {
            var culture = _cultureResolver.Resolve();

            var data = _dbContext
                .Set<EntityModel.Event>()
                .Where(_ => _.Id == eventId)
                .Select(_ => new
                             {
                                 Data = new EventSaveDetails
                                        {
                                            Key = _.Id,
                                            Description = _.Description,
                                            Code = _.Code ?? string.Empty,
                                            RecalcEventDate = _.RecalcEventDate ?? false,
                                            IsAccountingEvent = _.IsAccountingEvent ?? false,
                                            SuppressCalculation = _.SuppressCalculation ?? false,
                                            Notes = _.Notes ?? string.Empty,
                                            MaxCycles = _.NumberOfCyclesAllowed,
                                            UnlimitedCycles = (_.NumberOfCyclesAllowed ?? 0) >= 9999,
                                            AllowPoliceImmediate = _.ShouldPoliceImmediate,
                                            Category = _.Category == null ? null : new EventCategory {Key = _.Category.Id, Name = DbFuncs.GetTranslation(_.Category.Name, null, _.Category.NameTId, culture), Description = DbFuncs.GetTranslation(_.Category.Name, null, _.Category.NameTId, culture)},
                                            ControllingAction = _.Action == null ? null : new Action {Code = _.Action.Code, Cycles = _.Action.NumberOfCyclesAllowed, Value = DbFuncs.GetTranslation(_.Action.Name, null, _.Action.NameTId, culture)},
                                            DraftCaseEvent = _.DraftEvent == null ? null : new Event {Code = _.DraftEvent.Code, Key = _.DraftEvent.Id, Value = DbFuncs.GetTranslation(_.DraftEvent.Description, null, _.DraftEventId, culture)},
                                            InternalImportance = _.ImportanceLevel,
                                            ClientImportance = _.ClientImportanceLevel,
                                            Group = _.Group == null ? null : new TableCodePicklistController.TableCodePicklistItem {Key = _.Group.Id, Value = DbFuncs.GetTranslation(_.Group.Name, null, _.Group.NameTId, culture)},
                                            NotesGroup = _.NoteGroup == null ? null : new TableCodePicklistController.TableCodePicklistItem {Key = _.NoteGroup.Id, Value = DbFuncs.GetTranslation(_.NoteGroup.Name, null, _.NoteGroup.NameTId, culture)},
                                            NotesSharedAcrossCycles = _.NotesSharedAcrossCycles ?? false
                                        }
                             })
                .SingleOrDefault();

            if (data == null)
            {
                throw Exceptions.NotFound("No matching event found");
            }

            CheckForAffectedEventControl(data);

            return data;
        }

        void CheckForAffectedEventControl(dynamic data)
        {
            var canUpdateProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected);
            var canUpdateUnprotectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules);
            var eventDetails = data.Data as EventSaveDetails;
            if (eventDetails == null) return;

            var updatableCriteria = from criteria in _dbContext.Set<Criteria>()
                                                               .WhereWorkflowCriteria()
                                                               .Where(_ => _.UserDefinedRule == null || _.UserDefinedRule == 0 && canUpdateProtectedRules || _.UserDefinedRule == 1 && canUpdateUnprotectedRules)
                                    join _ in _dbContext.Set<ValidEvent>() on criteria.Id equals _.CriteriaId
                                    where _.EventId == eventDetails.Key
                                    select new {_.EventId, _.Description};

            data.Data.HasUpdatableCriteria = updatableCriteria.Any();
            data.Data.IsDescriptionUpdatable = updatableCriteria.Any(_ => _.Description.Equals(eventDetails.Description, StringComparison.InvariantCultureIgnoreCase));
        }

        [HttpDelete]
        [Route("{eventId}")]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
        public dynamic Delete(int eventId)
        {
            return _eventsPicklistMaintenance.Delete(eventId);
        }

        [HttpPut]
        [Route("{eventId}")]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
        public dynamic Update(int eventId, EventSaveDetails saveEvent)
        {
            if (saveEvent == null) throw new ArgumentNullException(nameof(saveEvent));
            return _eventsPicklistMaintenance.Save(saveEvent, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
        public dynamic AddOrDuplicate(EventSaveDetails savableEvent)
        {
            if (savableEvent == null) throw new ArgumentNullException(nameof(savableEvent));
            return _eventsPicklistMaintenance.Save(savableEvent, Operation.Add);
        }

        [HttpGet]
        [Route("supportdata")]
        [NoEnrichment]
        public dynamic GetSupportData()
        {
            var importanceLevels = _dbContext.Set<Importance>().Select(v => new {Id = v.Level, Name = v.Description});
            var defaultImportanceLevel = _dbContext.Set<Importance>()
                                                   .ToList()
                                                   .Where(_ => new Regex(@"^\d+$").Match(_.Level).Success)
                                                   .Where(_ => Convert.ToInt32(_.Level) <= 5)
                                                   .Max(_ => Convert.ToInt32(_.Level))
                                                   .ToString();
            return new
                   {
                       importanceLevels,
                       defaultMaxCycles = 1,
                       defaultImportanceLevel
                   };
        }
    }

    public class EventSaveDetails
    {
        public int Key { get; set; }

        [Required]
        public string Description { get; set; }

        public string Code { get; set; }
        public bool? RecalcEventDate { get; set; }
        public bool? IsAccountingEvent { get; set; }
        public bool AllowPoliceImmediate { get; set; }
        public virtual EventCategory Category { get; set; }
        public string ClientImportance { get; set; }
        public virtual Action ControllingAction { get; set; }
        public virtual Event DraftCaseEvent { get; set; }
        public virtual TableCodePicklistController.TableCodePicklistItem NotesGroup { get; set; }
        public virtual TableCodePicklistController.TableCodePicklistItem Group { get; set; }
        public string InternalImportance { get; set; }

        [Required]
        public short? MaxCycles { get; set; }

        public bool UnlimitedCycles { get; set; }
        public string Notes { get; set; }
        public bool? SuppressCalculation { get; set; }
        public bool? NotesSharedAcrossCycles { get; set; }
        public bool? PropagateChanges { get; set; }
        public bool HasUpdatableCriteria { get; set; }
        public bool IsDescriptionUpdatable { get; set; }
    }

    public class Event
    {
        [PicklistKey]
        [DisplayName("EventNo")]
        [PreventCopy]
        [PicklistColumn(menu: true)]
        public int Key { get; set; }

        [Required]
        [MaxLength(10)]
        [DisplayName("Code")]
        [PicklistCode]
        [PicklistColumn(menu: true)]
        public string Code { get; set; }

        [Required]
        [MaxLength(100)]
        [PicklistDescription]
        [PicklistColumn]
        public string Value { get; set; }

        [DisplayName("Alias")]
        [PicklistColumn(false, menu: true)]
        public string Alias { get; set; }

        [DisplayName("MaxCycles")]
        [PicklistColumn(false, menu: true)]
        public short? MaxCycles { get; set; }

        [DisplayName("Importance")]
        [PicklistColumn(filterable: true, filterApi: "api/picklists/events", menu: true)]
        public string Importance { get; set; }

        [DisplayName("EventCategory")]
        [PicklistColumn(menu: true, hideByDefault: true)]
        public string EventCategory { get; set; }

        [DisplayName("EventGroup")]
        [PicklistColumn(menu: true, hideByDefault: true)]
        public string EventGroup { get; set; }

        [DisplayName("EventNotesGroup")]
        [PicklistColumn(menu: true, hideByDefault: true)]
        public string EventNotesGroup { get; set; }

        public string ImportanceLevel { get; set; }

        [PicklistColumn(false, menu: true)]
        public int CurrentCycle { get; set; }

        public IEnumerable<string> ValidEventDescription { get; set; }
    }
}