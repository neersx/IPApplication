using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Translations;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Web.Picklists
{
    public interface IEventMatcher
    {
        IEnumerable<MatchedEvent> MatchingItems(string search = null, int? criteriaId = null);
    }

    public class EventMatcher : IEventMatcher
    {
        readonly IDbContext _dbContext;
        readonly string _culture;
        readonly bool _requireTranslation;
        readonly LookupCulture _lookupCulture;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly ISecurityContext _securityContext;

        public EventMatcher(IDbContext dbContext, IPreferredCultureResolver cultureResolver, ILookupCultureResolver lookupCultureResolver, IImportanceLevelResolver importanceLevelResolver, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _importanceLevelResolver = importanceLevelResolver;
            _culture = cultureResolver.Resolve();
            _lookupCulture = lookupCultureResolver.Resolve(_culture);
            _requireTranslation = !_lookupCulture.NotApplicable;
            _securityContext = securityContext;
        }

        // It supports filter by criteriaId which is only used by workflows, in the future we should refactor this to cater for more filters
        public IEnumerable<MatchedEvent> MatchingItems(string search = null, int? criteriaId = null)
        {
            var events = _dbContext.Set<EntityModel.Event>().AsQueryable();

            if (_securityContext.User.IsExternalUser)
            {
                var filteredIds = FilterOnImportanceLevel();
                events = events.Where(_ => filteredIds.Contains(_.Id));
            }

            if (criteriaId != null)
            {
                var ids = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId.Value).Select(_ => _.EventId).ToArray();
                events = events.Where(_ => ids.Contains(_.Id));

                if (string.IsNullOrWhiteSpace(search))
                    return GetValidEvents(events.Where(_ => ids.Contains(_.Id)), search, criteriaId);
            }

            if (string.IsNullOrWhiteSpace(search))
            {
                return EventsDataSet(events);
            }

            var isSearchNumeric = int.TryParse(search, out int number);

            var q1 = EventsDataSet(events.Where(_ => _.Code == search && _.Id != number)).ToArray();
            var q2 = GetValidEvents(events, search, criteriaId);
            var q3 = q1.Union(q2, new MatchedEventComparer());

            if (isSearchNumeric)
            {
                var exactEventNoMatch = EventsDataSet(events.Where(_ => _.Id == number)).ToArray();
                var startingEventNoMatch = EventsDataSet(events.Where(_ => _.Id.ToString().StartsWith(number.ToString()) && _.Id != number)).ToArray();
                q3 = startingEventNoMatch.Concat(q3);
                q3 = exactEventNoMatch.Concat(q3);
            }

            var result = q3.OrderBy(x => GetMatchOrder(x, search))
                           .ThenBy(_ => _.Value);

            return result;
        }

        List<int> FilterOnImportanceLevel()
        {
            var defaultImportanceLevel = _importanceLevelResolver.Resolve();
            return _dbContext.Set<EntityModel.Event>().Where(_ => _.ClientImportance != null).ToList().Select(_ => new {_.Id, _.ClientImportanceLevel})
                             .Where(_ => new Regex(@"^\d+$").Match(_.ClientImportanceLevel).Success && Convert.ToInt32(_.ClientImportanceLevel) >= defaultImportanceLevel).Select(_ => _.Id).ToList();
        }

        SearchGroup GetMatchOrder(MatchedEvent e, string search)
        {
            if (!string.IsNullOrEmpty(search))
            {
                if (e.Code == search) return SearchGroup.ExactCodeMatch;

                if (int.TryParse(search, out int number) && e.Key == number) return SearchGroup.ExactEventNoMatch;
                if (int.TryParse(search, out int startWithNumber) && e.Key.ToString().StartsWith(startWithNumber.ToString())) return SearchGroup.StartWithEventNoMatch;

                if (e.Value.Equals(search, StringComparison.InvariantCultureIgnoreCase)) return SearchGroup.ExactDescriptionMatch;
                if (e.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0) return SearchGroup.ContainsDescriptionMatch;
            }

            return SearchGroup.None;
        }

        IEnumerable<MatchedEvent> GetValidEvents(IQueryable<EntityModel.Event> events, string search, int? criteriaId)
        {
            var filteredEvents = events;

            if (!string.IsNullOrEmpty(search))
            {
                if (!_requireTranslation)
                {
                    filteredEvents = events.Where(et => et.Description.Contains(search)
                                                        || et.ValidEvents.Any(ve => ve.Description.Contains(search)));
                }
                else
                {
                    var matchedEvents = _dbContext.Set<EntityModel.Event>().Where(et => DbFuncs.GetTranslation(et.Description, null, et.DescriptionTId, _culture).Contains(search)).Select(_ => _.Id);
                    var validEventsSet = _dbContext.Set<ValidEvent>().Where(ve => DbFuncs.GetTranslation(ve.Description, null, ve.DescriptionTId, _culture).Contains(search)).Select(_ => _.EventId);
                    var combinedEvents = matchedEvents.Concat(validEventsSet).Distinct().ToArray();
                    filteredEvents = events.Where(_ => combinedEvents.Contains(_.Id));
                }
            }

            var data = EventsDataSetWithValidEvent(filteredEvents, criteriaId).ToArray();
            foreach (var ev in data)
            {
                if (ev.ValidEventDescription.Any(_ => !string.IsNullOrEmpty(_)))
                    ev.Alias = string.Join("; ", ev.ValidEventDescription.Where(_ => ev.Value.Trim() != _));
            }

            return data;
        }

        IEnumerable<MatchedEvent> EventsDataSet(IQueryable<EntityModel.Event> e)
        {
            if (!_requireTranslation)
            {
                return e.Select(_ => new MatchedEvent
                {
                    Key = _.Id,
                    Code = _.Code,
                    Value = _.Description,
                    MaxCycles = _.NumberOfCyclesAllowed,
                    Importance = _securityContext.User.IsExternalUser ? _.ClientImportance != null ? _.ClientImportance.Description : null :
                        _.InternalImportance != null ? _.InternalImportance.Description : null,
                    ImportanceLevel = _securityContext.User.IsExternalUser ? _.ClientImportance != null ? _.ClientImportance.Level : null :
                        _.InternalImportance != null ? _.InternalImportance.Level : null,
                    EventCategory = _.Category != null ? _.Category.Name : null,
                    EventGroup = _.Group != null ? _.Group.Name : null,
                    EventNotesGroup = _.NoteGroup != null ? _.NoteGroup.Name : null
                }).OrderBy(v => v.Value);
            }

            return e.Select(_ => new MatchedEvent
            {
                Key = _.Id,
                Code = _.Code,
                Value = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture),
                MaxCycles = _.NumberOfCyclesAllowed,
                Importance = _securityContext.User.IsExternalUser ? _.ClientImportance != null ? DbFuncs.GetTranslation(_.ClientImportance.Description, null, _.ClientImportance.DescriptionTId, _culture) : null :
                    _.InternalImportance != null ? DbFuncs.GetTranslation(_.InternalImportance.Description, null, _.InternalImportance.DescriptionTId, _culture) : null,
                ImportanceLevel = _securityContext.User.IsExternalUser ? _.ClientImportance != null ? _.ClientImportance.Level : null :
                    _.InternalImportance != null ? _.InternalImportance.Level : null,
                EventCategory = _.Category != null ? DbFuncs.GetTranslation(_.Category.Name, null, _.Category.NameTId, _culture) : null,
                EventGroup = _.Group != null ? DbFuncs.GetTranslation(_.Group.Name, null, _.Group.NameTId, _culture) : null,
                EventNotesGroup = _.NoteGroup != null ? DbFuncs.GetTranslation(_.NoteGroup.Name, null, _.NoteGroup.NameTId, _culture) : null
            }).OrderBy(v => v.Value);
        }

        IEnumerable<MatchedEvent> EventsDataSetWithValidEvent(IQueryable<EntityModel.Event> e, int? criteriaId)
        {
            if (!_requireTranslation)
            {
                return e.Select(_ => new MatchedEvent
                {
                    Key = _.Id,
                    Code = _.Code,
                    Value = _.Description,
                    MaxCycles = _.NumberOfCyclesAllowed,
                    Importance = _.InternalImportance != null ? _.InternalImportance.Description : null,
                    ImportanceLevel = _.InternalImportance != null ? _.InternalImportance.Level : null,
                    EventCategory = _.Category != null ? _.Category.Name : null,
                    EventGroup = _.Group != null ? _.Group.Name : null,
                    EventNotesGroup = _.NoteGroup != null ? _.NoteGroup.Name : null,
                    ValidEventDescription = _.ValidEvents
                                             .Where(v => criteriaId != null && v.CriteriaId == criteriaId || criteriaId == null)
                                             .Select(v => v.Description)
                                             .Distinct()
                }).OrderBy(v => v.Value);
            }

            return e.Select(_ => new MatchedEvent
            {
                Key = _.Id,
                Code = _.Code,
                Value = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture),
                MaxCycles = _.NumberOfCyclesAllowed,
                Importance = _.InternalImportance != null ? DbFuncs.GetTranslation(_.InternalImportance.Description, null, _.InternalImportance.DescriptionTId, _culture) : null,
                ImportanceLevel = _.InternalImportance != null ? _.InternalImportance.Level : null,
                EventCategory = _.Category != null ? DbFuncs.GetTranslation(_.Category.Name, null, _.Category.NameTId, _culture) : null,
                EventGroup = _.Group != null ? DbFuncs.GetTranslation(_.Group.Name, null, _.Group.NameTId, _culture) : null,
                EventNotesGroup = _.NoteGroup != null ? DbFuncs.GetTranslation(_.NoteGroup.Name, null, _.NoteGroup.NameTId, _culture) : null,
                ValidEventDescription = _.ValidEvents
                                         .Where(v => criteriaId != null && v.CriteriaId == criteriaId || criteriaId == null)
                                         .Select(v => DbFuncs.GetTranslation(v.Description, null, v.DescriptionTId, _culture))
                                         .Distinct()
            }).OrderBy(v => v.Value);
        }
    }

    public class MatchedEvent
    {
        public MatchedEvent()
        {
            ValidEventDescription = new string[0];
        }

        public int Key { get; set; }

        public string Code { get; set; }

        public string Value { get; set; }

        public string Alias { get; set; }

        public short? MaxCycles { get; set; }

        public string Importance { get; set; }

        public string ImportanceLevel { get; set; }

        public IEnumerable<string> ValidEventDescription { get; set; }

        public string EventCategory { get; set; }

        public string EventGroup { get; set; }

        public string EventNotesGroup { get; set; }

        public int CurrentCycle { get; set; }
    }

    public enum SearchGroup
    {
        ExactEventNoMatch = 1,
        StartWithEventNoMatch = 2,
        ExactCodeMatch = 3,
        ExactDescriptionMatch = 4,
        ContainsDescriptionMatch = 5,

        None = 6
    }

    public class MatchedEventComparer : IEqualityComparer<MatchedEvent>
    {
        public bool Equals(MatchedEvent e1, MatchedEvent e2)
        {
            return e1.Key == e2.Key;
        }

        public int GetHashCode(MatchedEvent e)
        {
            return e.Key;
        }
    }
}