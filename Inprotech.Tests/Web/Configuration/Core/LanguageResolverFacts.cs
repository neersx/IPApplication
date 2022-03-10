using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class LanguageResolverFacts : FactBase
    {
        public class LanguageResolverFixture : IFixture<LanguageResolver>
        {
            public LanguageResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new LanguageResolver(DbContext, PreferredCultureResolver);

                SetupData(db);
            }

            public IDbContext DbContext { get; }

            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public LanguageResolver Subject { get; }

            void SetupData(InMemoryDbContext db)
            {
                new TableCodeBuilder {TableType = (int)TableTypes.Language, UserCode = "en", Description = "English", TableCode = 1}.Build().In(db);
                new TableCodeBuilder {TableType = (int)TableTypes.Language, UserCode = "ab-CD", Description = "Arabic", TableCode = 2}.Build().In(db);
                new TableCodeBuilder {TableType = (int)TableTypes.Language, UserCode = "ab", Description = "Arabic 2", TableCode = 3}.Build().In(db);
                new TableCodeBuilder {TableType = (int)TableTypes.Language, UserCode = "no", Description = "Norwegian", TableCode = 4}.Build().In(db);
                new TableCodeBuilder {TableType = (int)TableTypes.Language, UserCode = "ZH-CHS", Description = "Chinese", TableCode = 5}.Build().In(db);
            }
        }

        public class ResolveMethod : FactBase
        {
            [Theory]
            [InlineData("en-GB", 1)]
            [InlineData("ab-CD", 2)]
            [InlineData("NB-NO", 4)]
            [InlineData("ZH-CN", 5)]
            public void ShouldFindTheCorrectCulture(string culture, int languageId)
            {
                var f = new LanguageResolverFixture(Db);

                f.PreferredCultureResolver.Resolve().Returns(culture);
                var r = f.Subject.Resolve();
                
                Assert.NotNull(r);
                Assert.Equal(languageId,r);
            }

            [Fact]
            public void ShouldReturnNullIfCultureNotFound()
            {
                var f = new LanguageResolverFixture(Db);
                f.PreferredCultureResolver.Resolve().Returns("abcd");

                var r = f.Subject.Resolve();

                Assert.Null(r);
            }
        }
    }
}