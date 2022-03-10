using System.Collections.Generic;
using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Integration.Translations;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Translation;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Translation
{
    public class DeltaPersisterFacts : FactBase
    {
        readonly Dictionary<string, string> _existing = new Dictionary<string, string>
        {
            {"Arya", "Stark"},
            {"John", "Snow"}
        };

        readonly ChangedTranslation[] _changes =
        {
            new ChangedTranslation {Key = "Arya", Value = "NoFace"},
            new ChangedTranslation {Key = "Cersei", Value = "Lannister"}
        };

        [Fact]
        public async Task AddKeysNotAlreadyPresent()
        {
            var culture = "file culture";
            var currentDeltaContent = new Dictionary<string, TranslatedValues>
            {
                {"John", new TranslatedValues("Snow", "Targaryan")}
            };

            var result = new Dictionary<string, TranslatedValues>
            {
                {"John", new TranslatedValues("Snow", "Targaryan")},
                {"Arya", new TranslatedValues("Stark", "NoFace")},
                {"Cersei", new TranslatedValues(null, "Lannister")}
            };

            var f = new DeltaPersisterFixture(culture, Db)
                .WithCurrentDelta(JsonConvert.SerializeObject(currentDeltaContent), culture);

            await f.Subject.UpdateDeltaForChanges(_existing, _changes);

            f.Repository.Received(2).Set<TranslationDelta>();
            await f.Repository.Received(1).SaveChangesAsync();

            var savedValues = await f.Repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == culture);

            Assert.Equal(JsonConvert.SerializeObject(result), savedValues?.Delta);
        }

        [Fact]
        public async Task CallsToApplyDelta()
        {
            const string translationsFilePath = "translationsFilePath";
            const string culture = "en";

            var f = new DeltaPersisterFixture(culture, Db)
                .WithCurrentDelta("{}", culture);

            await f.Subject.ApplyDelta(translationsFilePath);

            f.TranslationDeltaApplier.Received(1).ApplyFor("{}", translationsFilePath).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ReadsCurrentDeltaFile()
        {
            var currentDeltaContent = new Dictionary<string, TranslatedValues>
            {
                {"SomeKey", new TranslatedValues("o", "n")}
            };
            const string culture = "someculturevalue";

            var f = new DeltaPersisterFixture(culture, Db)
                .WithCurrentDelta(JsonConvert.SerializeObject(currentDeltaContent), culture);

            await f.Subject.UpdateDeltaForChanges(_existing, _changes);

            f.Repository.Received(2).Set<TranslationDelta>();
            await f.Repository.Received(1).SaveChangesAsync();
        }

        [Fact]
        public async Task RemovesKeysWhichAreNoMoreDelta()
        {
            const string culture = "file culture";
            var currentDeltaContent = new Dictionary<string, TranslatedValues>
            {
                {"Arya", new TranslatedValues("Stark", "Sansa")}
            };

            var result = new Dictionary<string, TranslatedValues>
            {
                {"Arya", new TranslatedValues("Stark", "NoFace")},
                {"Cersei", new TranslatedValues(null, "Lannister")}
            };

            var f = new DeltaPersisterFixture(culture, Db)
                .WithCurrentDelta(JsonConvert.SerializeObject(currentDeltaContent), culture);

            await f.Subject.UpdateDeltaForChanges(_existing, _changes);

            f.Repository.Received(2).Set<TranslationDelta>();
            await f.Repository.Received(1).SaveChangesAsync();

            var savedValues = await f.Repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == culture);

            Assert.Equal(JsonConvert.SerializeObject(result), savedValues?.Delta);
        }

        [Fact]
        public async Task UpdatesKeysAlreadyPresent()
        {
            const string culture = "file culture";
            var currentDeltaContent = new Dictionary<string, TranslatedValues>
            {
                {"Arya", new TranslatedValues("Stark", "Sansa")}
            };

            ChangedTranslation[] changes =
            {
                new ChangedTranslation {Key = "Arya", Value = "Stark"}
            };

            var f = new DeltaPersisterFixture(culture, Db)
                .WithCurrentDelta(JsonConvert.SerializeObject(currentDeltaContent), culture);

            await f.Subject.UpdateDeltaForChanges(_existing, changes);

            f.Repository.Received(2).Set<TranslationDelta>();
            await f.Repository.Received(1).SaveChangesAsync();

            var savedValues = await f.Repository.Set<TranslationDelta>().SingleOrDefaultAsync(_ => _.Culture == culture);

            Assert.Equal("{}", savedValues?.Delta);
        }
    }

    internal class DeltaPersisterFixture : IFixture<IDeltaPersister>
    {
        public DeltaPersisterFixture(string culture, InMemoryDbContext db)
        {
            Repository = db;
            TranslationDeltaApplier = Substitute.For<ITranslationDeltaApplier>();
            Subject = new DeltaPersister(culture, Repository, Fixture.Today, TranslationDeltaApplier);
        }

        public InMemoryDbContext Repository { get; }

        public ITranslationDeltaApplier TranslationDeltaApplier { get; }

        public IDeltaPersister Subject { get; }

        public DeltaPersisterFixture WithCurrentDelta(string content, string culture)
        {
            new TranslationDelta
            {
                Delta = content,
                Culture = culture
            }.In(Repository);

            return this;
        }
    }
}