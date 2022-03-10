using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Translations;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;
using Newtonsoft.Json;

namespace Inprotech.Web.Translation
{
    public interface IDeltaPersister
    {
        Task UpdateDeltaForChanges(Dictionary<string, string> existing, ChangedTranslation[] translationChanges);

        Task ApplyDelta(string trasnlationFilePath);
    }

    public class DeltaPersister : IDeltaPersister
    {
        readonly ITranslationDeltaApplier _translationDeltaApplier;
        readonly string _languageCode;
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public DeltaPersister(string languageCode, IRepository repository, Func<DateTime> now, ITranslationDeltaApplier translationDeltaApplier)
        {
            _languageCode = languageCode;
            _repository = repository;
            _now = now;
            _translationDeltaApplier = translationDeltaApplier;
        }

        async Task<Dictionary<string, TranslatedValues>> GetCurrentDelta()
        {
            var data = await _repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == _languageCode);
            var deltaText = data?.Delta;

            return string.IsNullOrWhiteSpace(deltaText)
                ? new Dictionary<string, TranslatedValues>()
                : JsonConvert.DeserializeObject<Dictionary<string, TranslatedValues>>(deltaText);
        }

        async Task SaveDelta(Dictionary<string, TranslatedValues> delta)
        {
            var data = await _repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == _languageCode);
            if (data == null)
            {
                data = new TranslationDelta() { Culture = _languageCode };
                _repository.Set<TranslationDelta>().Add(data);
            }
            data.LastModified = _now();
            data.Delta = JsonConvert.SerializeObject(delta);
            await _repository.SaveChangesAsync();
        }

        public async Task UpdateDeltaForChanges(Dictionary<string, string> existing, ChangedTranslation[] translationChanges)
        {
            var currentDelta = await GetCurrentDelta();

            // Add new keys with old values
            var newKeys = translationChanges.Select(_ => _.Key).Except(currentDelta.Keys).ToArray();
            currentDelta.AddRange(newKeys.Select(k => new KeyValuePair<string, TranslatedValues>(k, new TranslatedValues(existing.ContainsKey(k) ? existing[k] : null,
                                                                                                                         translationChanges.Single(t => t.Key == k).Value))));

            // Loop through changes to update changed values 
            foreach (var change in translationChanges.Where(_ => !newKeys.Contains(_.Key)))
            {
                if (currentDelta.TryGetValue(change.Key, out TranslatedValues delta))
                {
                    delta.NewValue = change.Value;
                }
            }

            // Clean up keys which have same value as original
            var keysToClean = currentDelta.Where(_ => AreStringsSame(_.Value.OldValue, _.Value.NewValue)).Select(tc => tc.Key).ToList();
            keysToClean.ForEach(k => currentDelta.Remove(k));

            await SaveDelta(currentDelta);
        }

        public async Task ApplyDelta(string translationFilePath)
        {
            var data = await _repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == _languageCode);
            await _translationDeltaApplier.ApplyFor(data?.Delta, translationFilePath);
        }

        static bool AreStringsSame(string val1, string val2)
        {
            return (string.IsNullOrEmpty(val1) && string.IsNullOrEmpty(val2)) || string.Equals(val1, val2, StringComparison.InvariantCulture);
        }
    }
}