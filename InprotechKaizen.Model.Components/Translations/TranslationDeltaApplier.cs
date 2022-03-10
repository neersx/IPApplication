using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Translations
{
    public class TranslatedValues
    {
        public TranslatedValues(string oldValue, string newValue = null)
        {
            OldValue = oldValue;
            NewValue = newValue;
        }

        public string OldValue { get; set; }

        public string NewValue { get; set; }
    }

    public interface ITranslationDeltaApplier
    {
        Task ApplyFor(string translatedDeltaPath, string translationFilePath);
        Task<List<string>> ApplyFor(string deltaContent, string translationFilePath, Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool> canUpdate, bool clearMismatchedDelta);
    }

    class TranslationDeltaApplier : ITranslationDeltaApplier
    {
        public async Task ApplyFor(string deltaContent, string translationFilePath)
        {
            await ApplyFor(deltaContent, translationFilePath, (allTranslations, translationEntry) => true, false);
        }

        public async Task<List<string>> ApplyFor(string deltaContent, string translationFilePath, Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool> canUpdate, bool clearMismatchedDelta)
        {
            var misMatchedKeys = new List<string>();
            if (string.IsNullOrEmpty(deltaContent))
                return misMatchedKeys;
            if (!File.Exists(translationFilePath))
                CopyMissingTranslationFile(deltaContent, translationFilePath);
            else
                misMatchedKeys = await UpdateLocalTranslation(deltaContent, translationFilePath, canUpdate, clearMismatchedDelta);

            return misMatchedKeys;
        }

        async Task<List<string>> UpdateLocalTranslation(string deltaContent, string translationFilePath, Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool> canUpdate, bool clearMismatchedDelta)
        {
            var translationContent = await ReadFile(translationFilePath);

            var jsonFlatten = JsonUtility.FlattenHierarchy(translationContent);
            var delta = JsonConvert.DeserializeObject<Dictionary<string, TranslatedValues>>(deltaContent);
            var misMatchedKeys = new List<string>();

            foreach (var translation in delta)
            {
                if (canUpdate(jsonFlatten, translation))
                    jsonFlatten[translation.Key] = translation.Value.NewValue;
                else if (clearMismatchedDelta)
                    misMatchedKeys.Add(translation.Key);
            }

            // Normalization is required to help manage the merge process 
            // that will occur when the json file is 
            // sent back to us to implement in the product.
            await WriteFile(translationFilePath, JsonUtility.NormalizeJsonString(JsonUtility.Expand(jsonFlatten)));

            return misMatchedKeys;
        }

        static async Task<string> ReadFile(string path)
        {
            using (var stream = new StreamReader(path))
            {
                return await stream.ReadToEndAsync();
            }
        }

        static async Task WriteFile(string path, string data)
        {
            using (var stream = new StreamWriter(path) { AutoFlush = true })
            {
                await stream.WriteAsync(data);
            }
        }
        void CopyMissingTranslationFile(string deltaContent, string translationFilePath)
        {
            var delta = JsonConvert.DeserializeObject<Dictionary<string, TranslatedValues>>(deltaContent);
            var jsonFlatten = delta.ToDictionary(k => k.Key, v => v.Value.NewValue);

            File.WriteAllText(translationFilePath, JsonUtility.Expand(jsonFlatten));
        }
    }
}