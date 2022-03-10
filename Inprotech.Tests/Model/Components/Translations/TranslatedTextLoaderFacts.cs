using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class TranslatedTextLoaderFacts : FactBase
    {
        const int Tid = 1;
        const string RequestedCultureId = "requested";
        const string FallbackCultureId = "fallback";

        TranslatedText BuildTranslatedText(int tid, string cultureId, string translatedText = null)
        {
            return new TranslatedText
            {
                Tid = tid,
                CultureId = cultureId,
                HasSourceChanged = false,
                LongText = translatedText ?? cultureId + " translated text"
            };
        }

        [Fact]
        public void ShouldGetFallbackTranslatedTextIfOnlyFallbackCultureIsPresent()
        {
            var fallback = BuildTranslatedText(Tid, FallbackCultureId);
            fallback.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid});

            Assert.Equal(fallback.LongText, r[Tid]);
        }

        [Fact]
        public void ShouldGetMultipleTranslatedTextsIfPresentForRequestedTids()
        {
            const int tid2 = 2;

            var requested = BuildTranslatedText(Tid, RequestedCultureId);
            requested.In(Db);

            var fallback = BuildTranslatedText(Tid, FallbackCultureId);
            fallback.In(Db);

            var additional = BuildTranslatedText(tid2, RequestedCultureId);
            additional.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid, tid2});

            Assert.Equal(requested.LongText, r[Tid]);
            Assert.Equal(additional.LongText, r[tid2]);
        }

        [Fact]
        public void ShouldGetOnlyOneResultForASingleRequestedTid()
        {
            var requested = BuildTranslatedText(Tid, RequestedCultureId);
            requested.In(Db);

            var fallback = BuildTranslatedText(Tid, FallbackCultureId);
            fallback.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid});

            Assert.Equal(1, r.Count);
        }

        [Fact]
        public void ShouldGetRequestedTranslatedTextIfBothRequestedAndFallbackCulturesArePresent()
        {
            var requested = BuildTranslatedText(Tid, RequestedCultureId);
            requested.In(Db);

            var fallback = BuildTranslatedText(Tid, FallbackCultureId);
            fallback.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid});

            Assert.Equal(requested.LongText, r[Tid]);
        }

        [Fact]
        public void ShouldGetTranslatedText()
        {
            var requested = BuildTranslatedText(Tid, RequestedCultureId);
            requested.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid});

            Assert.Equal(requested.LongText, r[Tid]);
        }

        [Fact]
        public void ShouldGetTwoResultsForTwoRequestedTids()
        {
            const int tid2 = 2;

            var requested = BuildTranslatedText(Tid, RequestedCultureId);
            requested.In(Db);

            var fallback = BuildTranslatedText(Tid, FallbackCultureId);
            fallback.In(Db);

            var additional = BuildTranslatedText(tid2, RequestedCultureId);
            additional.In(Db);

            var loader = new TranslatedTextLoader(Db);

            var r = loader.Load(new LookupCulture(RequestedCultureId, FallbackCultureId), new[] {Tid, tid2});

            Assert.Equal(2, r.Count);
        }
    }
}