using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class LanguageSettingsProviderFacts : FactBase
    {
        public LanguageSettingsProviderFacts()
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
        }

        [Fact]
        public async Task DoesNotReturnWithoutValue()
        {
            var f = Subject();
            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Empty(r);
        }

        [Fact]
        public async Task ReturnsLanguageData()
        {
            var f = Subject();
            SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns(123);
            new TableCode(123, (short)TableTypes.Language, "Spanish").In(Db);

            Setting("EnglishFirm", false);
            Setting("en");
            Setting("de");
            Setting("en");

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(3, r.Length);
            Assert.Equal("Spanish", r.Single(_ => _.Name == AnalyticsEventCategories.LanguageDb).Value);
            Assert.Equal("EnglishFirm", r.Single(_ => _.Name == AnalyticsEventCategories.LanguageFirm).Value);
            Assert.Equal("en (2); de (1)", r.Single(_ => _.Name == AnalyticsEventCategories.LanguageUsers).Value);
        }

        LanguageSettingsProvider Subject() => new LanguageSettingsProvider(Db, SiteControlReader);

        ISiteControlReader SiteControlReader { get; }

        void Setting(string value, bool createUser = true)
        {
            new SettingValues()
            {
                SettingId = KnownSettingIds.PreferredCulture,
                CharacterValue = value,
                User = createUser ? new User().In(Db) : null
            }.In(Db);
        }
    }
}