using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using InprotechKaizen.Model.Components.Translations;
using Newtonsoft.Json;
using FileSystem = Inprotech.Setup.Core.FileSystem;
using IFileSystem = Inprotech.Setup.Core.IFileSystem;

namespace Inprotech.Setup.Actions
{
    public class RestoreTranslationChanges : ISetupActionAsync
    {
        readonly IFileSystem _fileSystem;
        readonly ITranslationDeltaApplier _translationDeltaApplier;
        readonly ITranslationDeltaDb _translationDeltaDb;
        readonly bool _isUpdate;
        string _integrationConnectionString;
        public string Description { get; } = "Restore custom translations";
        public bool ContinueOnException { get; } = true;

        public RestoreTranslationChanges(bool isUpdate, IFileSystem fileSystem, ITranslationDeltaApplier translationDeltaApplier, ITranslationDeltaDb translationDeltaDb)
        {
            _isUpdate = isUpdate;
            _fileSystem = fileSystem;
            _translationDeltaApplier = translationDeltaApplier;
            _translationDeltaDb = translationDeltaDb;
        }

        public RestoreTranslationChanges(bool isUpdate = false) : this(isUpdate, new FileSystem(), new TranslationDeltaApplier(),new TranslationDeltaDb())
        {

        }

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            Task.Run(() => RunAsync(context, eventStream));
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            _integrationConnectionString = (string)ctx["IntegrationAdministrationConnectionString"];

            var storageLocalizationPath = Path.Combine(ctx.StorageLocation, "translations_delta");
            var inprotechServerLocalizationPath = Path.Combine(ctx.InstancePath, Constants.InprotechServer.TranslationFolder);

            ValidateFolder(inprotechServerLocalizationPath);
            await Migration(storageLocalizationPath, eventStream.PublishInformation);

            if (_isUpdate)
                await Resync(inprotechServerLocalizationPath, eventStream.PublishInformation);
            else
                await Restore(inprotechServerLocalizationPath, eventStream.PublishInformation);
        }

        async Task Restore(string inprotechServerLocalizationPath, Action<string> notify = null)
        {
            await Process(inprotechServerLocalizationPath,
                          (allTranslations, translationEntry) => !allTranslations.ContainsKey(translationEntry.Key) || (allTranslations.ContainsKey(translationEntry.Key) && allTranslations[translationEntry.Key] == translationEntry.Value.OldValue),
                          notify,
                          true);
        }

        async Task Resync(string inprotechServerLocalizationPath, Action<string> notify = null)
        {
            await Process(inprotechServerLocalizationPath,
                          (allTranslations, translationEntry) => true,
                          notify,
                          false);
        }

        async Task Process(string inprotechServerLocalizationPath, Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool> canUpdate, Action<string> notify, bool clearMismatchedDelta)
        {
            foreach (var data in _translationDeltaDb.GetTranslationDelta(_integrationConnectionString))
            {
                notify?.Invoke($"Restoring Translation for culture {data.Culture}");
                var translationFilePath = Path.Combine(inprotechServerLocalizationPath, $"translations_{data.Culture}.json");
                var misMatchedKeys = await _translationDeltaApplier.ApplyFor(data.Delta, translationFilePath, canUpdate, clearMismatchedDelta);
                if (clearMismatchedDelta)
                    await UpdateDelta(data.Culture, data.Delta, misMatchedKeys);
            }
        }

        async Task UpdateDelta(string culture, string deltaContent, List<string> misMatchedKeys)
        {
            if (misMatchedKeys.Any())
            {
                var delta = JsonConvert.DeserializeObject<Dictionary<string, TranslatedValues>>(deltaContent);
                misMatchedKeys.ForEach(_ => delta.Remove(_));

                await _translationDeltaDb.UpdateTranslationDelta(_integrationConnectionString, culture, JsonConvert.SerializeObject(delta));
            }
        }

        void ValidateFolder(string inprotechServerLocalizationPath)
        {
            if (!_fileSystem.DirectoryExists(inprotechServerLocalizationPath))
                throw new Exception("Localization folder not found");
        }

        async Task Migration(string storageLocalizationPath, Action<string> notify)
        {
            if (_isUpdate)
                return;
            if (!_fileSystem.DirectoryExists(storageLocalizationPath))
                return;

            var translatedDeltas = _fileSystem.GetFiles(storageLocalizationPath);

            foreach (var translatedDeltaPath in translatedDeltas)
            {
                var name = Path.GetFileNameWithoutExtension(translatedDeltaPath);
                notify?.Invoke($"Migrating Translation for culture {name}");
                var deltaContent = _fileSystem.ReadAllText(translatedDeltaPath);
                if (ValidateDelata(name, deltaContent))
                {
                    await _translationDeltaDb.InsertTranslationDelta(_integrationConnectionString, name, deltaContent);
                    _fileSystem.DeleteFile(translatedDeltaPath);
                }
            }

            bool ValidateDelata(string culture, string deltaContent)
            {
                try
                {
                    return JsonConvert.DeserializeObject<Dictionary<string, TranslatedValues>>(deltaContent).Any();
                }
                catch (Exception e)
                {
                    notify?.Invoke($"Error Migrating Translation for culture {culture} Error is:{e.Message}");
                }

                return false;
            }
        }
    }
}