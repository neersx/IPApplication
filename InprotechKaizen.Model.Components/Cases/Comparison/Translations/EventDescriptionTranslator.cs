using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Translations
{
    public interface IEventDescriptionTranslator
    {
        IEnumerable<T> Translate<T>(IEnumerable<T> interim) where T : IEventDescriptionTranslatable;
    }

    public class EventDescriptionTranslator : IEventDescriptionTranslator
    {
        readonly string _culture;
        readonly IDbContext _dbContext;

        public EventDescriptionTranslator(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;

            _culture = preferredCultureResolver.Resolve();
        }

        public IEnumerable<T> Translate<T>(IEnumerable<T> interim) where T : IEventDescriptionTranslatable
        {
            if (interim == null) throw new ArgumentNullException(nameof(interim));

            var input = interim.ToArray();

            return input.Any() ? TranslateInternal(input) : input;
        }

        IEnumerable<T> TranslateInternal<T>(T[] interim) where T : IEventDescriptionTranslatable
        {
            if (interim == null) throw new ArgumentNullException(nameof(interim));

            var requiredEventControlKeys = RequiredEventControlKeys(interim);
            var requiredEventIds = RequiredEventIds(interim);
            var comparer = new InterimResultComparer();

            var t1 = from e in _dbContext.Set<Event>()
                     where requiredEventIds.Contains(e.Id)
                     select new InterimResult
                            {
                                Id = e.Id,
                                CriteriaId = null,
                                EventDescription = DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, _culture),
                                EventControlDescription = null
                            };

            var t2 = from ec in _dbContext.Set<ValidEvent>()
                     where requiredEventControlKeys.Contains(ec.EventId + "^" + ec.CriteriaId)
                     select new InterimResult
                            {
                                Id = ec.EventId,
                                CriteriaId = ec.CriteriaId,
                                EventDescription = null,
                                EventControlDescription = DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, _culture)
                            };

            var translations = t1.Union(t2).Distinct().ToDictionary(k => k, v => v.EventControlDescription ?? v.EventDescription, comparer);

            foreach (var item in interim)
            {
                if (item.EventNo == null)
                {
                    yield return item;
                    continue;
                }

                var matcher = new InterimResult
                              {
                                  Id = item.EventNo.GetValueOrDefault(),
                                  CriteriaId = item.CriteriaId
                              };

                item.SetTranslatedDescription(translations[matcher]);

                yield return item;
            }
        }

        static int[] RequiredEventIds<T>(T[] interim) where T : IEventDescriptionTranslatable
        {
            return (from i in interim
                    where i.CriteriaId == null && i.EventNo != null
                    select i.EventNo.Value)
                .ToArray();
        }

        static string[] RequiredEventControlKeys<T>(T[] interim) where T : IEventDescriptionTranslatable
        {
            return (from i in interim
                    where i.CriteriaId != null
                    select $"{i.EventNo}^{i.CriteriaId}")
                .Distinct()
                .ToArray();
        }

        public class InterimResult
        {
            public int Id { get; set; }

            public int? CriteriaId { get; set; }

            public string EventDescription { get; set; }

            public string EventControlDescription { get; set; }
        }

        public class InterimResultComparer : IEqualityComparer<InterimResult>
        {
            public bool Equals(InterimResult x, InterimResult y)
            {
                if (ReferenceEquals(x, null)) return false;

                if (ReferenceEquals(x, y)) return true;

                return x.Id == y.Id && x.CriteriaId == y.CriteriaId;
            }

            public int GetHashCode(InterimResult obj)
            {
                return new
                       {
                           obj.Id,
                           obj.CriteriaId
                       }.GetHashCode();
            }
        }
    }
}