using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Translations;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Web.Picklists
{
    public interface ICaseEventMatcher
    {
        IEnumerable<MatchedEvent> MatchingItems(int caseId, string search = null, string actionId = null);
    }

    public class CaseEventMatcher : ICaseEventMatcher
    {
        readonly IDbContext _dbContext;
        readonly string _culture;
        readonly bool _requireTranslation;

        public CaseEventMatcher(IDbContext dbContext, IPreferredCultureResolver cultureResolver, ILookupCultureResolver lookupCultureResolver)
        {
            _culture = cultureResolver.Resolve();
            var lookupCulture = lookupCultureResolver.Resolve(_culture);
            _requireTranslation = !lookupCulture.NotApplicable;
            _dbContext = dbContext;
        }

        public IEnumerable<MatchedEvent> MatchingItems(int caseId, string search = null, string actionId = null)
        {
            var eventWithMaxCycle = _dbContext.Set<CaseEvent>().AsNoTracking().Where(_ => _.CaseId == caseId)
                                              .GroupBy(_ => _.EventNo, (i, events) => events.OrderByDescending(e => e.Cycle))
                                              .Select(m => m.FirstOrDefault());

            var caseEvents = from e in _dbContext.Set<EntityModel.Event>().AsNoTracking()
                  join em in eventWithMaxCycle on e.Id equals em.EventNo
                  join oa in _dbContext.Set<OpenAction>().AsNoTracking().Where(_ => actionId == null || _.ActionId == actionId) on em.CaseId equals oa.CaseId
                  join ec in _dbContext.Set<ValidEvent>().AsNoTracking() on oa.CriteriaId equals ec.CriteriaId
                  where ec.EventId == em.EventNo
                  select new CaseEventDetailInterim
                  {
                      Event = e,
                      CaseEventMaxCycle = em.Cycle,
                      ValidDescription = _requireTranslation ? DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, _culture) : ec.Description,
                      TranslatedDescription = _requireTranslation ? DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, _culture) : e.Description,
                      Importance = e.InternalImportance != null ? _requireTranslation ? DbFuncs.GetTranslation(e.InternalImportance.Description, null, e.InternalImportance.DescriptionTId, _culture) : e.InternalImportance.Description : null,
                      ImportanceLevel = e.InternalImportance != null ? e.InternalImportance.Level : null
                  };

            if (string.IsNullOrWhiteSpace(search))
            {
                return EventsDataSet(caseEvents.ToArray()).Distinct(new MatchedEventComparer());
            }

            var isSearchNumeric = int.TryParse(search, out int number);

            var q1 = EventsDataSet(caseEvents.Where(_ => _.Event.Code == search && _.Event.Id != number).ToArray());
            var q2 = EventsDataSet(caseEvents.Where(_ => _.TranslatedDescription.Contains(search) || _.ValidDescription.Contains(search)).ToArray());
            var q3 = q1.Union(q2, new MatchedEventComparer());

            if (isSearchNumeric)
            {
                var exactEventNoMatch = EventsDataSet(caseEvents.Where(_ => _.Event.Id == number).ToArray());
                var startingEventNoMatch = EventsDataSet(caseEvents.Where(_ => _.Event.Id.ToString().StartsWith(number.ToString()) && _.Event.Id != number).ToArray());
                q3 = startingEventNoMatch.Concat(q3);
                q3 = exactEventNoMatch.Concat(q3);
            }

            var result = q3.OrderBy(x => GetMatchOrder(x, search))
                           .ThenBy(_ => _.Value);

            return result.ToArray();
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
        IEnumerable<MatchedEvent> EventsDataSet(IEnumerable<CaseEventDetailInterim> interim)
        {
            if (!_requireTranslation)
            {
                return interim.Select(_ => new MatchedEvent
                {
                    Key = _.Event.Id,
                    Code = _.Event.Code,
                    Value = _.ValidDescription ?? _.TranslatedDescription,
                    MaxCycles = _.Event.NumberOfCyclesAllowed,
                    Importance = _.Importance,
                    ImportanceLevel = _.ImportanceLevel,
                    CurrentCycle = _.CaseEventMaxCycle
                }).OrderBy(v => v.Value);
            }

            return interim.Select(_ => new MatchedEvent
            {
                Key = _.Event.Id,
                Code = _.Event.Code,
                Value = _.ValidDescription ?? _.TranslatedDescription,
                MaxCycles = _.Event.NumberOfCyclesAllowed,
                Importance = _.Importance,
                ImportanceLevel = _.ImportanceLevel,
                CurrentCycle = _.CaseEventMaxCycle
            }).OrderBy(v => v.Value);
        }

        class CaseEventDetailInterim
        {
            public EntityModel.Event Event { get; set; }

            public int CaseEventMaxCycle { get; set; }

            public string ValidDescription {get; set;}
            public string TranslatedDescription {get; set;}
            public string Importance {get; set;}
            public string ImportanceLevel { get; set; }
        }
    }
}
