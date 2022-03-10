using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class ImportanceLevelResolverFacts : FactBase
    {
        [Theory]
        [InlineData(null)]
        [InlineData(1)]
        [InlineData(3)]
        [InlineData(5)]
        public void GetValidImportanceLevelForInternalUserReturnsInputValue(int? importanceLevel)
        {
            var f = new ImportanceLevelResolverFixture(Db)
                .WithUser();

            Assert.Equal(importanceLevel, f.Subject.GetValidImportanceLevel(importanceLevel));
        }

        [Theory]
        [InlineData(null, 4)]
        [InlineData(1, 4)]
        [InlineData(4, 4)]
        [InlineData(5, 5)]
        public void GetValidImportanceLevelForExternalUser(int? importanceLevel, int expectation)
        {
            var defaultImportanceLevel = 4;
            var f = new ImportanceLevelResolverFixture(Db)
                    .WithUser(true)
                    .WithSiteControlValue(SiteControls.ClientImportance, defaultImportanceLevel);

            Assert.Equal(expectation, f.Subject.GetValidImportanceLevel(importanceLevel));
        }

        class ImportanceLevelResolverFixture : IFixture<ImportanceLevelResolver>
        {
            public ImportanceLevelResolverFixture(InMemoryDbContext db)
            {
                Db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                var preferredCulture = Substitute.For<IPreferredCultureResolver>();
                preferredCulture.Resolve().Returns("en");
                Subject = new ImportanceLevelResolver(Db, SecurityContext, SiteControlReader, preferredCulture);
            }

            InMemoryDbContext Db { get; }
            ISecurityContext SecurityContext { get; }
            ISiteControlReader SiteControlReader { get; }

            public ImportanceLevelResolver Subject { get; }

            public ImportanceLevelResolverFixture WithUser(bool isExternal = false)
            {
                return WithUser(new User(Fixture.String(), isExternal));
            }

            public ImportanceLevelResolverFixture WithUser(User user)
            {
                SecurityContext.User.Returns(user);
                return this;
            }

            public ImportanceLevelResolverFixture WithSiteControlValue<T>(string siteControl, T value)
            {
                SiteControlReader.Read<T>(siteControl).Returns(value);
                return this;
            }
        }

        [Fact]
        public void ResolveImportanceLevelForExternallUser()
        {
            var f = new ImportanceLevelResolverFixture(Db)
                    .WithUser(true)
                    .WithSiteControlValue(SiteControls.ClientImportance, 4);
            Assert.Equal(4, f.Subject.Resolve());
        }

        [Fact]
        public void ResolveImportanceLevelForInternalUser()
        {
            var f = new ImportanceLevelResolverFixture(Db)
                    .WithUser()
                    .WithSiteControlValue(SiteControls.EventsDisplayed, 4);
            Assert.Equal(4, f.Subject.Resolve());
        }

        [Fact]
        public void ResolveImportanceLevelFromUserProfile()
        {
            var f = new ImportanceLevelResolverFixture(Db)
                .WithUser(new User("abc", false, new Profile(2, "profile") {ProfileAttributes = {new ProfileAttribute(new Profile(3, "profile"), ProfileAttributeType.MinimumImportanceLevel, "4")}}));
            Assert.Equal(4, f.Subject.Resolve());
        }

        [Fact]
        public async Task ReturnsNumericImportanceLevels()
        {
            var f = new ImportanceLevelResolverFixture(Db);
            new Importance("10", "abc").In(Db);
            new Importance("11", "def").In(Db);
            new Importance("1", "abcvdsd").In(Db);
            new Importance("5", "abcgdfsgdsg").In(Db);
            new Importance("1b", "stringid").In(Db);

            var r = (await f.Subject.GetImportanceLevels()).ToList();

            Assert.Equal(4, r.Count);
            Assert.Equal(1, r.First().LevelNumeric);
        }
    }
}