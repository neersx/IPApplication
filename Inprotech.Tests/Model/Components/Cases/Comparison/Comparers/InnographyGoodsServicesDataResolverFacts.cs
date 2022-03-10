using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;
using GoodsServices = InprotechKaizen.Model.Components.Cases.Comparison.Models.GoodsServices;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class InnographyGoodsServicesDataResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            readonly GoodsServicesComparisonScenarioBuilder _scenarioBuilder =
                new GoodsServicesComparisonScenarioBuilder();

            [Theory]
            [InlineData("9")]
            [InlineData("09")]
            [InlineData("009")]
            public void MatchWithLeadingZeros(string classNumber)
            {
                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = classNumber,
                    Text = Constants.ShortText
                };

                var result = f.Subject.Resolve(Build(Db, Constants.Class9), new[] {_scenarioBuilder.Build()});

                Assert.NotNull(result.Single());
            }

            [Theory]
            [InlineData("90")]
            [InlineData("090")]
            [InlineData("0090")]
            public void DoesNotMatchWithTrailingZeros(string classNumber)
            {
                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = classNumber,
                    Text = Constants.ShortText
                };

                var result = f.Subject.Resolve(Build(Db, Constants.Class9), new[] {_scenarioBuilder.Build()});

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void ReturnsAll()
            {
                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = Constants.Class1,
                    Text = Constants.VeryShortText
                };

                var comparisonResult = f.Subject.Resolve(Build(Db, Constants.Class9), new[] {_scenarioBuilder.Build()});

                Assert.Equal(2, comparisonResult.Count());
            }

            [Fact]
            public void ReturnsTexWithDefaultLanguage()
            {
                var defaultLanguage = Fixture.String();

                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = Constants.Class9,
                    Text = Constants.VeryShortText,
                    LanguageCode = Fixture.String()
                };

                var secondScenario = new GoodsServicesComparisonScenarioBuilder
                {
                    GoodsServices = new GoodsServices
                    {
                        Class = Constants.Class9, 
                        Text = Constants.ShortText, 
                        LanguageCode = defaultLanguage
                    }
                };

                new TableCodeBuilder {UserCode = defaultLanguage, TableCode = 1}.For(TableTypes.Language).Build().In(Db);

                var comparisonResult = f.Subject.Resolve(Build(Db, Constants.Class9),
                                                         new[] {_scenarioBuilder.Build(), secondScenario.Build()}, null, defaultLanguage).ToArray();

                var result = comparisonResult.Single();

                Assert.NotNull(result);
                
                Assert.Equal(Constants.Class9, result.Class.OurValue);
                Assert.Equal(Constants.VeryShortText, result.Text.OurValue);
                Assert.Equal(defaultLanguage, result.Language.OurValue.Code);
                Assert.Equal(defaultLanguage, result.Language.TheirValue.Code);

            }

            [Fact]
            public void ReturnsInprotechGoodsServices()
            {
                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                var cr = f.Subject.Resolve(Build(Db, Constants.Class24), Enumerable.Empty<ComparisonScenario<GoodsServices>>());

                var r = cr.Single();

                Assert.Equal(Constants.Class24, r.Class.OurValue);
                Assert.Equal(Constants.VeryShortText, r.Text.OurValue);

                Assert.Null(r.Class.TheirValue);
                Assert.Null(r.Text.TheirValue);
            }

            [Fact]
            public void ReturnsInprotechGoodsServicesFirstWhenUnmatched()
            {
                var f = new InnographyGoodsServicesDataResolverFixture(Db);

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = Constants.Class1,
                    Text = Constants.VeryShortText
                };

                var comparisonResult = f.Subject.Resolve(Build(Db, Constants.Class24), new[] {_scenarioBuilder.Build()}).ToArray();

                var inprotech = comparisonResult.First();
                var imported = comparisonResult.Last();

                Assert.NotEqual(imported, inprotech);

                Assert.Equal(Constants.Class24, inprotech.Class.OurValue);
                Assert.Null(inprotech.Class.TheirValue);

                Assert.Equal(Constants.Class1, imported.Class.TheirValue);
                Assert.Null(imported.Class.OurValue);
            }

            static IEnumerable<CaseText> Build(InMemoryDbContext db, string classKey)
            {
                var inprotechCase = new InprotechCaseBuilder(db)
                                    .WithCaseText(classKey, Constants.ShortText, 0, 1)
                                    .WithCaseText(classKey, Constants.VeryShortText, 1, 1)
                                    .WithCaseText(classKey, Constants.ShortText)
                                    .WithCaseText(classKey, Constants.VeryShortText, 1)
                                    .Build();

                return inprotechCase.GoodsAndServices()
                                                    .GroupBy(t => new {t.Class, t.Language})
                                                    .Select(g => g.OrderByDescending(_ => _.Number).First())
                                                    .ToArray();
            }
        }

        public class InnographyGoodsServicesDataResolverFixture : IFixture<InnographyGoodsServicesDataResolver>
        {
            public InnographyGoodsServicesDataResolverFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                HtmlAsPlainText = Substitute.For<IHtmlAsPlainText>();
                HtmlAsPlainText.Retrieve(Arg.Any<string>()).Returns(h => (string) h[0]);

                var classStringComparer = Substitute.For<IClassStringComparer>();
                classStringComparer.Equals(Arg.Any<string>(), Arg.Any<string>())
                                   .Returns(x =>
                                   {
                                       var a = ((string) x[0] ?? string.Empty).TrimStart('0');
                                       var b = ((string) x[1] ?? string.Empty).TrimStart('0');

                                       return string.Compare(a, b, StringComparison.CurrentCultureIgnoreCase) == 0;
                                   });

                Subject = new InnographyGoodsServicesDataResolver(db,classStringComparer, HtmlAsPlainText, PreferredCultureResolver);
            }

            public IHtmlAsPlainText HtmlAsPlainText { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public InnographyGoodsServicesDataResolver Subject { get; }
        }
    }
}