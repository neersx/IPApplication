using System;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Translations;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class LookupCultureResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            void CreateDatabaseCulture(string culture)
            {
                new SiteControl {StringValue = culture ?? Fixture.String(), ControlId = SiteControls.DatabaseCulture}
                    .In(Db);
            }

            [Fact]
            public void IndicateTranslationsAreNotRequiredWhenRequestedCultureEqualsDatabaseCulture()
            {
                CreateDatabaseCulture("EN-AU");

                var subject = new LookupCultureResolver(Db);
                var result = subject.Resolve("EN-AU");

                Assert.True(result.NotApplicable);
            }

            [Fact]
            public void IndicateTranslationsAreNotRequiredWhenTranslationDataDoNotExistForTheCulture()
            {
                CreateDatabaseCulture("EN-AU");

                var subject = new LookupCultureResolver(Db);
                var result = subject.Resolve("PT-BR");

                Assert.True(result.NotApplicable);
            }

            [Fact]
            public void IndicateTranslationsAreNotRequriredWhenNoSpecifiedCulture()
            {
                var subject = new LookupCultureResolver(Db);

                Assert.True(subject.Resolve(null).NotApplicable);
            }

            [Fact]
            public void ReturnsFallbackCultureAsLookupCulture()
            {
                CreateDatabaseCulture("EN-AU");
                new TranslatedText {CultureId = "PT"}.In(Db);

                var subject = new LookupCultureResolver(Db);
                var result = subject.Resolve("pt-br");

                Assert.False(result.NotApplicable);
                Assert.Equal(0, string.Compare("pt", result.Fallback, StringComparison.OrdinalIgnoreCase));
            }

            [Fact]
            public void ReturnsRequestedCultureAsLookupCulture()
            {
                CreateDatabaseCulture("EN-AU");
                new TranslatedText {CultureId = "PT-BR"}.In(Db);

                var subject = new LookupCultureResolver(Db);
                var result = subject.Resolve("pt-br");

                Assert.False(result.NotApplicable);
                Assert.Equal(0, string.Compare("pt-br", result.Requested, StringComparison.OrdinalIgnoreCase));
            }
        }
    }
}