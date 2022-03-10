using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Web.Translation
{
    public interface ITranslationSource
    {
        Task<IEnumerable<TranslatableItem>> Fetch(string culture);

        Task Save(ScreenLabelChanges changes);

        string ExportStartPath { get; }

        string Name { get; }
    }

    public class TranslationSource : ITranslationSource
    {
        readonly IDefaultResourceExtractor _defaultResourceExtractor;
        readonly IResourceFile _resourceFile;
        readonly Func<string, IDeltaPersister> _deltaPreserverFactory;

        public TranslationSource(IDefaultResourceExtractor defaultResourceExtractor, IResourceFile resourceFile, Func<string, IDeltaPersister> deltaPreserverFactory)
        {
            _defaultResourceExtractor = defaultResourceExtractor;
            _resourceFile = resourceFile;
            _deltaPreserverFactory = deltaPreserverFactory;
        }

        public async Task<IEnumerable<TranslatableItem>> Fetch(string culture)
        {
            var basePath = _resourceFile.BasePath;
            var requestPath = Path.Combine(basePath, string.Format(KnownPaths.TranslationsFilePattern, culture));

            var translated = new Dictionary<string, string>();

            if (_resourceFile.Exists(requestPath))
            {
                var contents = await _resourceFile.ReadAsync(requestPath);
                translated = JsonUtility.FlattenHierarchy(contents);
            }

            var translatables = (await _defaultResourceExtractor.Extract()).ToArray();

            foreach (var t in translated)
            {
                var translatable = translatables.SingleOrDefault(_ => _.ResourceKey == t.Key);
                if (translatable != null)
                    translatable.Translated = t.Value;
            }

            return translatables;
        }

        public async Task Save(ScreenLabelChanges changes)
        {
            var translations = changes.Translations.CondorTranslations()
                                      .WithoutCondorPrefix()
                                      .ToArray();
            if (!translations.Any())
                return;

            var basePath = _resourceFile.BasePath;
            var resourcePath = Path.Combine(basePath, string.Format(KnownPaths.TranslationsFilePattern, changes.LanguageCode));
            var existing = new Dictionary<string, string>();

            if (_resourceFile.Exists(resourcePath))
            {
                var content = await _resourceFile.ReadAsync(resourcePath);
                existing = JsonUtility.FlattenHierarchy(content);
            }

            existing.AddRange(translations.Select(_ => _.Key)
                                          .Except(existing.Keys)
                                          .Select(_ => new KeyValuePair<string, string>(_, null))
                             );

            //Store delta
            var deltaPreserver = _deltaPreserverFactory(changes.LanguageCode);
            await deltaPreserver.UpdateDeltaForChanges(existing, translations);

            //Apply Delta
            await deltaPreserver.ApplyDelta(resourcePath);
            
        }

        public string ExportStartPath => Path.Combine(_resourceFile.BasePath, KnownPaths.TranslationsPath);

        public string Name => "condor";
    }
}