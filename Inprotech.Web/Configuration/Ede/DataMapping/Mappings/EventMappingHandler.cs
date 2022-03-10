using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public class EventMapping : Mapping<int?>
    {
    }

    public class EventMappingHandler : IMappingHandler
    {
        readonly IDbContext _dbContext;
        readonly IMappings _mappings;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public EventMappingHandler(IDbContext dbContext, IMappings mappings, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _mappings = mappings;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<Mapping> FetchBy(int? systemId, int structure)
        {
            if (systemId == null) throw new ArgumentNullException(nameof(systemId));

            var culture = _preferredCultureResolver.Resolve();
            var mappings = _mappings.Fetch(systemId, structure,
                                           (m, o) => new EventMapping
                                                     {
                                                         Id = m.Id,
                                                         NotApplicable = m.IsNotApplicable,
                                                         InputDesc = m.InputCode ?? m.InputDescription,
                                                         Output = new Output<int?>
                                                                  {
                                                                      Key = string.IsNullOrWhiteSpace(o) ? (int?) null : int.Parse(o)
                                                                  }
                                                     })
                                    .Cast<EventMapping>()
                                    .ToArray();

            var uniqueEventIds = mappings
                .Where(_ => _.Output.Key.HasValue)
                .Select(_ => _.Output.Key.Value);

            var translatedEvents =
                (from e in _dbContext.Set<Event>()
                 where uniqueEventIds.Contains(e.Id)
                 select new
                        {
                            e.Id,
                            Description = DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture)
                        })
                .ToDictionary(k => k.Id,v => v.Description);

            foreach (var mapping in mappings)
            {
                string description;
                if (mapping.Output.Key.HasValue &&
                    translatedEvents.TryGetValue(mapping.Output.Key.Value, out description))
                {
                    mapping.Output.Value = description;
                }

                yield return mapping;
            }
        }

        public bool TryValidate(DataSource dataSource, MapStructure mapStructure, Mapping mapping, out IEnumerable<string> errors)
        {
            if (dataSource == null) throw new ArgumentNullException(nameof(dataSource));
            if (mapStructure == null) throw new ArgumentNullException(nameof(mapStructure));
            if (mapping == null) throw new ArgumentNullException(nameof(mapping));

            errors = Enumerable.Empty<string>();

            if (!string.IsNullOrWhiteSpace(mapping.OutputValueId))
            {
                var e = (EventMapping) mapping;
                if (!_dbContext.Set<Event>().Any(_ => _.Id == e.Output.Key))
                {
                    errors = CreateValidationError("invalid-output-value");
                    return false;
                }
            }

            return true;
        }

        public Type MappingType => typeof(EventMapping);

        static IEnumerable<string> CreateValidationError(string messageCode)
        {
            return new[]
                   {
                       messageCode
                   };
        }
    }
}