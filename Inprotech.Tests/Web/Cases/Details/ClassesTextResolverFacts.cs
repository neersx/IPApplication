using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ClassesTextResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            public const int CaseId = 1;
            void SetupData()
            {
                new CaseTextBuilder {CaseId = CaseId, Class = "01", Text= "Text For Class 01", TextNumber = 1, TextTypeId = KnownTextTypes.GoodsServices}.Build().In(Db);
                new CaseTextBuilder {CaseId = CaseId, Class = "01", Text= "Text For Class 01 Latest", TextNumber = 2, TextTypeId = KnownTextTypes.GoodsServices}.Build().In(Db);
                new CaseTextBuilder {CaseId = CaseId, Class = "01", Text= "English Text For Class 01", TextNumber = 3, TextTypeId = KnownTextTypes.GoodsServices, Language = 4704}.Build().In(Db);
                new CaseTextBuilder {CaseId = CaseId, Class = "01", Text= "English Text For Class 01 Latest", TextNumber = 4, TextTypeId = KnownTextTypes.GoodsServices, Language = 4704}.Build().In(Db);
                new CaseTextBuilder {CaseId = CaseId, Class = "02", Text= "English Text For Class 02 Latest", TextNumber = 1, TextTypeId = KnownTextTypes.GoodsServices, Language = 4700}.Build().In(Db);
            }

            [Fact]
            public void ReturnCaseTextWithMaxSequenceAndNullLanguageIfLanguageIsNull()
            {
                SetupData();

                var f = new ClassesTextResolverFixture(Db);
                f.LanguageResolver.Resolve().ReturnsForAnyArgs((int?)null);
                f.SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns((int?)null);
                
                var r = f.Subject.Resolve("01", CaseId);

                Assert.Equal("Text For Class 01 Latest", r.GsText);
                Assert.True(r.HasMultipleLanguageClassText);
            }

            [Fact]
            public void ReturnCaseTextWithMaxSequenceAndNullLanguageIfSiteControlLanguageIsNotNull()
            {
                SetupData();

                var f = new ClassesTextResolverFixture(Db);
                f.LanguageResolver.Resolve().ReturnsForAnyArgs((int?)null);
                f.SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns(4704);
                
                var r = f.Subject.Resolve("01", CaseId);

                Assert.Equal("English Text For Class 01 Latest", r.GsText);
                Assert.True(r.HasMultipleLanguageClassText);
            }

            [Fact]
            public void ReturnCaseTextWithMaxSequenceAndNullLanguageIfLanguageIsNotNull()
            {
                SetupData();

                var f = new ClassesTextResolverFixture(Db);
                f.LanguageResolver.Resolve().ReturnsForAnyArgs(4704);
                f.SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns((int?)null);
                
                var r = f.Subject.Resolve("01", CaseId);

                Assert.Equal("English Text For Class 01 Latest", r.GsText);
                Assert.True(r.HasMultipleLanguageClassText);
            }

            [Fact]
            public void ReturnCaseTextWithMaxSequenceAndNullLanguageIfLanguageNotFound()
            {
                SetupData();

                var f = new ClassesTextResolverFixture(Db);
                f.LanguageResolver.Resolve().ReturnsForAnyArgs(4702);
                f.SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns(4702);
                
                var r = f.Subject.Resolve("01", CaseId);

                Assert.Equal("Text For Class 01 Latest", r.GsText);
                Assert.True(r.HasMultipleLanguageClassText);
            }

            [Fact]
            public void ReturnHasMultipleLanguageClassTextShouldBeSetToFalseIfOnlyOneLanguageTextExists()
            {
                SetupData();

                var f = new ClassesTextResolverFixture(Db);
                f.LanguageResolver.Resolve().ReturnsForAnyArgs(4700);
                f.SiteControlReader.Read<int?>(SiteControls.LANGUAGE).Returns((int?)null);
                
                var r = f.Subject.Resolve("02", CaseId);

                Assert.Equal("English Text For Class 02 Latest", r.GsText);
                Assert.False(r.HasMultipleLanguageClassText);
            }
        }

        public class ClassesTextResolverFixture : IFixture<ClassesTextResolver>
        {
            public ClassesTextResolverFixture(InMemoryDbContext dbContext)
            {
                LanguageResolver = Substitute.For<ILanguageResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new ClassesTextResolver(LanguageResolver, SiteControlReader, dbContext);
            }

            public ClassesTextResolver Subject { get; }

            public ILanguageResolver LanguageResolver { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
        }
    }
}