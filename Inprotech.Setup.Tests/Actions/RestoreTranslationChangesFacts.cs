using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using InprotechKaizen.Model.Components.Translations;
using NSubstitute;
using Xunit;
using IFileSystem = Inprotech.Setup.Core.IFileSystem;

namespace Inprotech.Setup.Tests.Actions
{
    public class RestoreTranslationChangesFacts
    {
        public RestoreTranslationChangesFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new SetupContext
            {
                InstancePath = InstancePath,
                StorageLocation = "Content"
            };
            _context.Add("IntegrationAdministrationConnectionString", "integ");
        }

        const string InstancePath = "Path";
        readonly IEventStream _eventStream;
        readonly SetupContext _context;
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly ITranslationDeltaApplier _translationDeltaApplier = Substitute.For<ITranslationDeltaApplier>();
        readonly ITranslationDeltaDb _translationDeltaDb = Substitute.For<ITranslationDeltaDb>();

        RestoreTranslationChanges NewSubject(bool isUpdate = false)
        {
            return new RestoreTranslationChanges(isUpdate, _fileSystem, _translationDeltaApplier, _translationDeltaDb);
        }

        void BasicSetup(string translationFolderPath, IEnumerable<TranslationDeltaDb.TranslationDelta> delta)
        {
            _fileSystem.DirectoryExists(translationFolderPath).Returns(true);
            _translationDeltaDb.GetTranslationDelta(Arg.Any<string>()).Returns(delta);
        }

        void MigrationSetup(string translationFolderPath, IEnumerable<TranslationDeltaDb.TranslationDelta> delta, string delataStoragePath, string storageFolderDeltaFile, string deltaFileContent = "{}")
        {
            BasicSetup(translationFolderPath, delta);
            _fileSystem.DirectoryExists(delataStoragePath).Returns(true);
            _fileSystem.GetFiles(delataStoragePath).Returns(new[] {storageFolderDeltaFile});
            _fileSystem.ReadAllText(storageFolderDeltaFile).Returns(deltaFileContent);
        }

        void ProcessSetup(string translationFolderPath, TranslationDeltaDb.TranslationDelta delta)
        {
            BasicSetup(translationFolderPath, new[] {delta});
            _translationDeltaDb.GetTranslationDelta(Arg.Any<string>()).Returns(new[] {delta});
        }

        string DelataContent => "{\"Any.key\":{\"OldValue\":null,\"NewValue\":\"Translation\"}}";

        [Fact]
        public void ShouldContinueOnException()
        {
            Assert.True(new RestoreTranslationChanges().ContinueOnException);
        }

        [Fact]
        public async Task ShouldMigrateDeltaToDb()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            var storageLocalizationPath = Path.Combine(_context.StorageLocation, "translations_delta");
            var filePath = "en.json";
            MigrationSetup(translationPath, new TranslationDeltaDb.TranslationDelta[0], storageLocalizationPath, filePath, DelataContent);

            await NewSubject().RunAsync(_context, _eventStream);

            await _translationDeltaDb.Received(1).InsertTranslationDelta(_context["IntegrationAdministrationConnectionString"].ToString(), "en", DelataContent);
            _fileSystem.Received(1).DeleteFile(filePath);
        }

        [Fact]
        public async Task ShouldNotMigrateForUpdate()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            BasicSetup(translationPath, new TranslationDeltaDb.TranslationDelta[0]);

            await NewSubject(true).RunAsync(_context, _eventStream);

            _fileSystem.Received(1).DirectoryExists(translationPath);
            _fileSystem.DidNotReceiveWithAnyArgs().GetFiles(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldRestoreTranslationRemovingAnyMismatchedEnteries()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            ProcessSetup(translationPath, new TranslationDeltaDb.TranslationDelta("en", DelataContent));
            _translationDeltaApplier.ApplyFor(DelataContent, Arg.Any<string>(), Arg.Any<Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool>>(), true).Returns(new List<string> {"Any.key"});

            await NewSubject().RunAsync(_context, _eventStream);

            await _translationDeltaApplier
                  .Received(1)
                  .ApplyFor(DelataContent, Path.Combine(translationPath, "translations_en.json"), Arg.Any<Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool>>(), true);

            await _translationDeltaDb.Received(1).UpdateTranslationDelta(Arg.Any<string>(), "en", "{}");
        }

        [Fact]
        public async Task ShouldTryMigrationIfNotUpdate()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            var storageLocalizationPath = Path.Combine(_context.StorageLocation, "translations_delta");

            MigrationSetup(translationPath, new TranslationDeltaDb.TranslationDelta[0], storageLocalizationPath, string.Empty);

            await NewSubject().RunAsync(_context, _eventStream);

            _fileSystem.Received(1).DirectoryExists(translationPath);
            _fileSystem.Received(1).DirectoryExists(storageLocalizationPath);
            _fileSystem.Received(1).GetFiles(storageLocalizationPath);
        }

        [Fact]
        public async Task ThrowsExceptionIfTranslationFolderDoesntExist()
        {
            try
            {
                await new RestoreTranslationChanges().RunAsync(_context, _eventStream);
                Assert.Equal(1, 2); //This should not be executed
            }
            catch (Exception exp)
            {
                Assert.Equal("Localization folder not found", exp.Message);
            }
        }

        [Fact]
        public async Task UpdateShouldResyncTranslation()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            ProcessSetup(translationPath, new TranslationDeltaDb.TranslationDelta("en", DelataContent));

            await NewSubject(true).RunAsync(_context, _eventStream);

            await _translationDeltaApplier
                  .Received(1)
                  .ApplyFor(DelataContent, Path.Combine(translationPath, "translations_en.json"), Arg.Any<Func<Dictionary<string, string>, KeyValuePair<string, TranslatedValues>, bool>>(), false);
        }

        [Fact]
        public async Task ValidatesContentOfDeltaBeforeMigration()
        {
            var translationPath = Path.Combine(InstancePath, Constants.InprotechServer.TranslationFolder);
            var storageLocalizationPath = Path.Combine(_context.StorageLocation, "translations_delta");
            var filePath = "en.json";
            MigrationSetup(translationPath, new TranslationDeltaDb.TranslationDelta[0], storageLocalizationPath, filePath, "wrongJson");

            await NewSubject().RunAsync(_context, _eventStream);

            _fileSystem.Received(1).GetFiles(storageLocalizationPath);
            _fileSystem.Received(1).ReadAllText(filePath);
            await _translationDeltaDb.DidNotReceiveWithAnyArgs().InsertTranslationDelta(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>());
            _fileSystem.DidNotReceiveWithAnyArgs().DeleteFile(storageLocalizationPath);
        }
    }
}