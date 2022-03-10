using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Mui;
using Inprotech.Web.Translation;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Mui
{
    public class ScreenLabelsControllerFacts
    {
        public class ViewDataMethod : FactBase
        {
            [Fact]
            public void ReturnsCultureAndTheirParentCulturesDefinedInTableCodes()
            {
                new TableCodeBuilder
                    {
                        UserCode = "ja"
                    }
                    .For(TableTypes.Language)
                    .Build()
                    .In(Db);

                var s = new ScreenLabelsControllerFixture(Db).Subject;
                var r = s.ViewData().ToArray();

                var r1 = r.First();
                var r2 = r.Last();

                Assert.Equal("ja", r1.Culture);
                Assert.Equal("ja-JP", r2.Culture);

                var ja = new CultureInfo("ja");
                var jaJp = new CultureInfo("ja-JP");

                Assert.Equal(ja.DisplayName + " (" + ja.Name + ")", r1.Description);
                Assert.Equal(jaJp.DisplayName + " (" + jaJp.Name + ")", r2.Description);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public async Task CombineTranslatableItemsFromSource()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     },
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria());

                Assert.Equal(2, r.Data.Count());
            }

            [Fact]
            public async Task OptionallyFilterByArea()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "a",
                         Area = "Test",
                         Default = "b",
                         ResourceKey = "screenlabels.area.test"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria
                {
                    Text = "Test"
                });

                Assert.Single(r.Data);
            }

            [Fact]
            public async Task OptionallyFilterByDefaultLabel()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "b",
                         Default = "b",
                         ResourceKey = "b"
                     },
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria
                {
                    Text = "a"
                });

                Assert.Single(r.Data);
            }

            [Fact]
            public async Task OptionallyFilterByResourceKey()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "b",
                         Default = "b",
                         ResourceKey = "b"
                     },
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria
                {
                    Text = "a"
                });

                Assert.Single(r.Data);
            }

            [Fact]
            public async Task OptionallyFilterByTranslatedText()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "b",
                         Default = "b",
                         ResourceKey = "b"
                     },
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria
                {
                    Text = "a"
                });

                Assert.Single(r.Data);
            }

            [Fact]
            public async Task OptionallyReturnAlreadyTranslatedItems()
            {
                var f = new ScreenLabelsControllerFixture(Db);
                f.TranslationSource1.Fetch(Arg.Any<string>())
                 .Returns(new[]
                 {
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a"
                     },
                     new TranslatableItem
                     {
                         Source = "a",
                         Default = "a",
                         ResourceKey = "a",
                         Translated = "blah"
                     }
                 });

                var r = await f.Subject.Search(new SearchCriteria
                {
                    IsRequiredTranslationsOnly = true
                });

                Assert.Single(r.Data);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public async Task CallSaveOnSource()
            {
                var changes = new ScreenLabelChanges();

                var f = new ScreenLabelsControllerFixture(Db);

                await f.Subject.Save(changes);

                f.TranslationSource1.Received(1).Save(changes).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class ScreenLabelsControllerFixture : IFixture<ScreenLabelsController>
        {
            public ScreenLabelsControllerFixture(InMemoryDbContext db)
            {
                TranslationSource1 = Substitute.For<ITranslationSource>();

                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                SiteConfiguration.DatabaseLanguageCode.Returns("en");

                ResourceFile = Substitute.For<IResourceFile>();

                Subject = new ScreenLabelsController(db,
                                                     SiteConfiguration,
                                                     TranslationSource1,
                                                     ResourceFile,
                                                     new CommonQueryService());
            }

            public ITranslationSource TranslationSource1 { get; set; }

            public ISiteConfiguration SiteConfiguration { get; set; }

            public IResourceFile ResourceFile { get; set; }

            public ScreenLabelsController Subject { get; }
        }
    }
}