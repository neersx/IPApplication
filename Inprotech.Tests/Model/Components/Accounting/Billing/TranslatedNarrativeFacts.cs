using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class TranslatedNarrativeFacts
    {
        public class ForSingleMethod : FactBase
        {
            [Fact]
            public async Task ShouldUsePassedInLanguageIdIfAvailable()
            {
                var languageId = Fixture.Short();

                var n = new Narrative
                {
                    NarrativeText = "hello"
                }.In(Db);

                var narrative = new NarrativeTranslation
                {
                    LanguageId = languageId,
                    NarrativeId = n.NarrativeId,
                    TranslatedText = Fixture.String()
                }.In(Db);

                var f = new TranslatedNarrativeFixture(Db)
                    .WithNarrativeTranslate(true);

                var result = await f.Subject.For("en", n.NarrativeId, languageId: languageId);

                Assert.Equal(narrative.TranslatedText, result);

                f.BillingLanguageResolver.DidNotReceiveWithAnyArgs()
                 .Resolve(Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnBaseNarrativeTextIfBillingLanguageNotResolved()
            {
                var n = new Narrative
                {
                    NarrativeText = "hello"
                }.In(Db);

                new NarrativeTranslation
                {
                    LanguageId = Fixture.Short(),
                    NarrativeId = n.NarrativeId,
                    TranslatedText = Fixture.String()
                }.In(Db);

                var f = new TranslatedNarrativeFixture(Db)
                        .WithNarrativeTranslate(true)
                        .ResolvesBillingLanguageTo(null);

                var result = await f.Subject.For("en", n.NarrativeId);

                Assert.Equal("hello", result);
            }

            [Fact]
            public async Task ShouldReturnNarrativeWithBestBillingLanguage()
            {
                var nameLanguage = new NameLanguageBuilder(Db).BuildNameOnlyLanguage();

                var baseNarrative = new Narrative().In(Db);

                var narrative = new NarrativeTranslation
                {
                    LanguageId = nameLanguage.LanguageId,
                    NarrativeId = baseNarrative.NarrativeId,
                    TranslatedText = Fixture.String()
                }.In(Db);

                var other = new NarrativeTranslation
                {
                    LanguageId = nameLanguage.LanguageId + 1, // not matched
                    NarrativeId = baseNarrative.NarrativeId,
                    TranslatedText = Fixture.String()
                }.In(Db);

                var f = new TranslatedNarrativeFixture(Db)
                        .WithNarrativeTranslate(true)
                        .ResolvesBillingLanguageTo(nameLanguage);

                var result = await f.Subject.For("en", baseNarrative.NarrativeId, null, nameLanguage.NameId);

                Assert.Equal(narrative.TranslatedText, result);
                Assert.NotEqual(other.TranslatedText, result);
            }
        }

        public class TranslatedNarrativeFixture : IFixture<TranslatedNarrative>
        {
            public TranslatedNarrativeFixture(InMemoryDbContext db)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                BillingLanguageResolver = Substitute.For<IBillingLanguageResolver>();
                Subject = new TranslatedNarrative(db, SiteControlReader, BillingLanguageResolver);
            }

            public ISiteControlReader SiteControlReader { get; }
            public IBillingLanguageResolver BillingLanguageResolver { get; }
            public TranslatedNarrative Subject { get; }

            public TranslatedNarrativeFixture ResolvesBillingLanguageTo(NameLanguage nameLanguage)
            {
                BillingLanguageResolver.Resolve(null)
                                       .ReturnsForAnyArgs(nameLanguage?.LanguageId);

                return this;
            }

            public TranslatedNarrativeFixture WithNarrativeTranslate(bool on)
            {
                SiteControlReader.Read<bool>(SiteControls.NarrativeTranslate)
                                 .Returns(on);

                return this;
            }
        }
    }
}