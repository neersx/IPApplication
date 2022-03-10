using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NarrativesPicklistControllerFacts
    {
        public class DefaultNarrativePicklist : FactBase
        {
            [Fact]
            public async Task MatchesOnCode()
            {
                var id = new Narrative {NarrativeCode = "abc", NarrativeTitle = "xyz"}.In(Db).NarrativeId;

                var f = new NarrativesPicklistFixture(Db);
                var r = (await f.Subject.Search(null, "a")).Data;

                Assert.Equal(id, r.Single().Key);
            }

            [Fact]
            public async Task MatchesOnTitle()
            {
                var id = new Narrative {NarrativeCode = "abc", NarrativeTitle = "xyz"}.In(Db).NarrativeId;
                var f = new NarrativesPicklistFixture(Db);
                var r = (await f.Subject.Search(null, "x")).Data;

                Assert.Equal(id, r.Single().Key);
            }

            [Fact]
            public async Task ReturnsExactCodeMatchesWhereAvailable()
            {
                new Narrative {NarrativeCode = "abcd", NarrativeTitle = "xyz"}.In(Db);
                new Narrative {NarrativeCode = "xyz", NarrativeTitle = "abc"}.In(Db);
                var id = new Narrative {NarrativeCode = "abc", NarrativeTitle = "xyz"}.In(Db).NarrativeId;
                var f = new NarrativesPicklistFixture(Db);
                var r = (await f.Subject.Search(null, "abc")).Data;
                Assert.Equal(id, r.Single().Key);
            }

            [Fact]
            public async Task ReturnsCodeContainsMatchesAndTitleContainsMatches()
            {
                new Narrative {NarrativeCode = "no match", NarrativeTitle = "123abx"}.In(Db);
                new Narrative {NarrativeCode = "containsMatch", NarrativeTitle = "xyzabc"}.In(Db);
                new Narrative {NarrativeCode = "123abc containsMatch", NarrativeTitle = "123abc"}.In(Db);
                new Narrative {NarrativeCode = "123abc containsMatch", NarrativeTitle = "123abc", NarrativeText = "abcdefg"}.In(Db);
                var first = new Narrative {NarrativeCode = "first", NarrativeTitle = "abcd"}.In(Db);
                var last = new Narrative {NarrativeCode = "abcd", NarrativeTitle = "last"}.In(Db);
                var next = new Narrative {NarrativeCode = "next", NarrativeTitle = "abcde"}.In(Db);

                var f = new NarrativesPicklistFixture(Db);
                var r = (await f.Subject.Search(null, "abc")).Data.ToArray();
                Assert.Equal(6, r.Length);
                Assert.Equal(first.NarrativeCode, r[0].Code);
                Assert.Equal(next.NarrativeCode, r[1].Code);
                Assert.Equal(last.NarrativeCode, r[5].Code);
            }
        }

        public class WithTranslatedText : FactBase
        {
            [Fact]
            public async Task ReturnsTranslatedTextWhereAvailableForCase()
            {
                var caseId = Fixture.Integer();
                var narrativeText = Fixture.String("default-text-");
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "no match", NarrativeTitle = "123abx", NarrativeText = narrativeText}.In(Db);
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "containsMatch", NarrativeTitle = "xyzabc", NarrativeText = narrativeText}.In(Db);
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "123abc containsMatch", NarrativeTitle = "123abc", NarrativeText = narrativeText}.In(Db);
                var first = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "first", NarrativeTitle = "abcd", NarrativeText = narrativeText}.In(Db);
                var last = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "abcd", NarrativeTitle = "last", NarrativeText = narrativeText}.In(Db);
                var next = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "next", NarrativeTitle = "abcde", NarrativeText = narrativeText}.In(Db);

                var f = new NarrativesPicklistFixture(Db);
                var translatedText = new Dictionary<short, string>
                {
                    {first.NarrativeId, "translated-narrative-text-first"},
                    {next.NarrativeId, "translated-narrative-text-next"},
                    {last.NarrativeId, "translated-narrative-text-last"}
                };
                f.TranslatedNarrative.For(Arg.Any<string>(), Arg.Any<IEnumerable<short>>(), caseId).Returns(translatedText);

                var r = (await f.Subject.Search(null, "abc", caseId)).Data.ToArray();

                Assert.Equal(5, r.Length);
                Assert.Equal(first.NarrativeCode, r[0].Code);
                Assert.Equal(next.NarrativeCode, r[1].Code);
                Assert.Equal(last.NarrativeCode, r[4].Code);
                Assert.Equal("translated-narrative-text-first", r[0].Text);
                Assert.Equal("translated-narrative-text-next", r[1].Text);
                Assert.Equal("translated-narrative-text-last", r[4].Text);
                Assert.Equal(narrativeText, r[2].Text);
                Assert.Equal(narrativeText, r[3].Text);
            }

            [Fact]
            public async Task ReturnsTranslatedTextWhereAvailableForDebtor()
            {
                var debtorKey = Fixture.Integer();
                var narrativeText = Fixture.String("default-text-");
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "no match", NarrativeTitle = "123abx", NarrativeText = narrativeText}.In(Db);
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "containsMatch", NarrativeTitle = "xyzabc", NarrativeText = narrativeText}.In(Db);
                new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "123abc containsMatch", NarrativeTitle = "123abc", NarrativeText = narrativeText}.In(Db);
                var first = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "first", NarrativeTitle = "abcd", NarrativeText = narrativeText}.In(Db);
                var last = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "abcd", NarrativeTitle = "last", NarrativeText = narrativeText}.In(Db);
                var next = new Narrative {NarrativeId = Fixture.Short(), NarrativeCode = "next", NarrativeTitle = "abcde", NarrativeText = narrativeText}.In(Db);

                var f = new NarrativesPicklistFixture(Db);
                var translatedText = new Dictionary<short, string>
                {
                    {first.NarrativeId, "translated-narrative-text-first"},
                    {next.NarrativeId, "translated-narrative-text-next"},
                    {last.NarrativeId, "translated-narrative-text-last"}
                };
                f.TranslatedNarrative.For(Arg.Any<string>(), Arg.Any<IEnumerable<short>>(), null, debtorKey).Returns(translatedText);

                var r = (await f.Subject.Search(null, "abc", null, debtorKey)).Data.ToArray();

                Assert.Equal(5, r.Length);
                Assert.Equal(first.NarrativeCode, r[0].Code);
                Assert.Equal(next.NarrativeCode, r[1].Code);
                Assert.Equal(last.NarrativeCode, r[4].Code);
                Assert.Equal("translated-narrative-text-first", r[0].Text);
                Assert.Equal("translated-narrative-text-next", r[1].Text);
                Assert.Equal("translated-narrative-text-last", r[4].Text);
                Assert.Equal(narrativeText, r[2].Text);
                Assert.Equal(narrativeText, r[3].Text);
            }
        }

        class NarrativesPicklistFixture : IFixture<NarrativesPicklistController>
        {
            public NarrativesPicklistFixture(InMemoryDbContext dbContext)
            {
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                TranslatedNarrative = Substitute.For<ITranslatedNarrative>();
                Subject = new NarrativesPicklistController(dbContext, preferredCultureResolver, TranslatedNarrative);
            }

            public ITranslatedNarrative TranslatedNarrative { get; }

            public NarrativesPicklistController Subject { get; }
        }
    }
}