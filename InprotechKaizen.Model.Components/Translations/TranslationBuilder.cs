using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;

namespace InprotechKaizen.Model.Components.Translations
{
    public interface ITranslationBuilder
    {
        ITranslationBuilder Culture(string culture);
        ITranslationBuilder Include(Type type, IEnumerable<object> items);
        ITranslationBuilder Reset();
        ITranslation Build();
    }

    internal class TranslationBuilder : ITranslationBuilder
    {
        readonly ILookupCultureResolver _lookupCultureResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITidColumnLoader _tidColumnLoader;
        readonly ITranslatedTextLoader _translatedTextLoader;
        readonly ITranslationMetadataLoader _translationMetadataLoader;
        readonly Dictionary<Type, IEnumerable<object>> _typeToEntities = new Dictionary<Type, IEnumerable<object>>();

        string _culture;

        public TranslationBuilder(
            IPreferredCultureResolver preferredCultureResolver,
            ILookupCultureResolver lookupCultureResolver,
            ITranslationMetadataLoader translationMetadataLoader,
            ITidColumnLoader tidColumnLoader,
            ITranslatedTextLoader translatedTextLoader)
        {
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");
            if (lookupCultureResolver == null) throw new ArgumentNullException("lookupCultureResolver");
            if (translationMetadataLoader == null) throw new ArgumentNullException("translationMetadataLoader");
            if (tidColumnLoader == null) throw new ArgumentNullException("tidColumnLoader");
            if (translatedTextLoader == null) throw new ArgumentNullException("translatedTextLoader");

            _preferredCultureResolver = preferredCultureResolver;
            _lookupCultureResolver = lookupCultureResolver;
            _translationMetadataLoader = translationMetadataLoader;
            _tidColumnLoader = tidColumnLoader;
            _translatedTextLoader = translatedTextLoader;
        }

        public ITranslationBuilder Culture(string culture)
        {
            if (culture == null) throw new ArgumentNullException("culture");

            _culture = culture;

            return this;
        }

        public ITranslationBuilder Include(Type type, IEnumerable<object> items)
        {
            if (!_typeToEntities.ContainsKey(type))
            {
                _typeToEntities[type] = new List<object>();
            }

            ((List<object>) _typeToEntities[type]).AddRange(items);

            return this;
        }

        public ITranslationBuilder Reset()
        {
            _typeToEntities.Clear();

            return this;
        }

        public ITranslation Build()
        {
            if (_culture == null)
            {
                _culture = _preferredCultureResolver.Resolve();
            }

            var lookupCulture = _lookupCultureResolver.Resolve(_culture);

            if (lookupCulture.NotApplicable || !_typeToEntities.Any())
            {
                return new DefaultTranslation();
            }

            var metadata = _translationMetadataLoader.Load(_typeToEntities.Keys);

            var entityToTids = _tidColumnLoader.Load(_typeToEntities, metadata.ToDictionary(a => a.Key, b => b.Value.Select(c => c.TidColumn)));

            var tids = entityToTids.SelectMany(a => a.Value.Values);

            var translatedText = _translatedTextLoader.Load(lookupCulture, tids);

            var tidToColumns = metadata.ToDictionary(
                                                     a => a.Key,
                                                     a => a.Value.ToDictionary(
                                                                               b => b.TidColumn,
                                                                               b => b.ShortColumn ?? b.LongColumn) as IDictionary<string, string>);

            return new Translation(Assemble(entityToTids, tidToColumns, translatedText));
        }

        static IDictionary<object, IDictionary<string, string>> Assemble(
            IDictionary<object, IDictionary<string, int>> entityToTids,
            IDictionary<Type, IDictionary<string, string>> tidToColumns,
            IDictionary<int, string> translatedTextMap)
        {
            var result = new Dictionary<object, IDictionary<string, string>>();

            foreach (var a in entityToTids)
            {
                var r = new Dictionary<string, string>();

                foreach (var b in a.Value)
                {
                    if (!translatedTextMap.ContainsKey(b.Value)) continue;

                    r[tidToColumns[Components.Translations.Utilities.GetEntityType(a.Key)][b.Key]] = translatedTextMap[b.Value];
                }

                result[a.Key] = r;
            }

            return result;
        }
    }
}