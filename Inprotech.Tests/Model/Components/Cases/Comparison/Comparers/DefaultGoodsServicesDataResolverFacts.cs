using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.System.Utilities;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using GoodsServices = InprotechKaizen.Model.Components.Cases.Comparison.Models.GoodsServices;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class DefaultGoodsServicesDataResolverFacts
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
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class9, Constants.ShortText)
                                    .Build();

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = classNumber,
                    Text = Constants.ShortText
                };

                var result = f.Subject.Resolve(Build(inprotechCase), new[] {_scenarioBuilder.Build()}, inprotechCase.Id);

                Assert.NotNull(result.Single());
            }

            [Theory]
            [InlineData("90")]
            [InlineData("090")]
            [InlineData("0090")]
            public void DoesNotMatchWithTrailingZeros(string classNumber)
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class9, Constants.ShortText)
                                    .Build();

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = classNumber,
                    Text = Constants.ShortText
                };

                var result = f.Subject.Resolve(Build(inprotechCase), new[] {_scenarioBuilder.Build()}, inprotechCase.Id);

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void LogParseDateError()
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class9, Constants.ShortText)
                                    .WithClassFirstUse(Constants.Class9)
                                    .Build();

                f.UseDateComparer
                 .Compare(Arg.Any<DateTime?>(), Arg.Any<string>())
                 .Returns(new FirstUsedDate
                 {
                     ParseError = "bad date from tsdr"
                 });

                f.Subject.Resolve(Build(inprotechCase),Enumerable.Empty<ComparisonScenario<GoodsServices>>(), inprotechCase.Id);

                f.Logger.ReceivedWithAnyArgs(1).Warning(null);

                f.UseDateComparer.Received(2).Compare(Arg.Any<DateTime?>(), Arg.Any<string>());
            }

            [Fact]
            public void ReturnsAll()
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class9, Constants.ShortText)
                                    .Build();

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = Constants.Class1,
                    Text = Constants.VeryShortText
                };

                var comparisonResult = f.Subject.Resolve(Build(inprotechCase), new[] {_scenarioBuilder.Build()}, inprotechCase.Id);

                Assert.Equal(2, comparisonResult.Count());
            }

            [Fact]
            public void ReturnsFirstUseDates()
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                            .WithCaseText(Constants.Class9, Constants.ShortText)
                            .WithClassFirstUse(Constants.Class9)
                            .Build();

                var result = f.Subject.Resolve(Build(inprotechCase), Enumerable.Empty<ComparisonScenario<GoodsServices>>(), inprotechCase.Id);

                var r = result.Single();

                Assert.Equal(Constants.Class9, r.Class.OurValue);
                Assert.Equal(Fixture.PastDate(), r.FirstUsedDate.OurValue);
                Assert.Equal(Fixture.Today(), r.FirstUsedDateInCommerce.OurValue);

                f.UseDateComparer.Received(2).Compare(Arg.Any<DateTime?>(), Arg.Any<string>());
            }

            [Fact]
            public void ReturnsInprotechGoodsServices()
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class24, Constants.ShortText)
                                    .Build();

                var cr = f.Subject.Resolve(Build(inprotechCase), Enumerable.Empty<ComparisonScenario<GoodsServices>>(), inprotechCase.Id);

                var r = cr.Single();

                Assert.Equal(Constants.Class24, r.Class.OurValue);
                Assert.Equal(Constants.ShortText, r.Text.OurValue);

                Assert.Null(r.Class.TheirValue);
                Assert.Null(r.Text.TheirValue);

                Assert.Null(r.FirstUsedDate.OurValue);
                Assert.Null(r.FirstUsedDate.TheirValue);

                Assert.Null(r.FirstUsedDateInCommerce.OurValue);
                Assert.Null(r.FirstUsedDateInCommerce.TheirValue);
            }

            [Fact]
            public void ReturnsInprotechGoodsServicesFirstWhenUnmatched()
            {
                var f = new DefaultGoodsServicesDataResolverFixture(Db);

                var inprotechCase = new InprotechCaseBuilder(Db)
                                    .WithCaseText(Constants.Class24, Constants.ShortText)
                                    .Build();

                _scenarioBuilder.GoodsServices = new GoodsServices
                {
                    Class = Constants.Class1,
                    Text = Constants.VeryShortText
                };

                var comparisonResult = f.Subject.Resolve(Build(inprotechCase), new[] {_scenarioBuilder.Build()}, inprotechCase.Id).ToArray();

                var inprotech = comparisonResult.First();
                var imported = comparisonResult.Last();

                Assert.NotEqual(imported, inprotech);

                Assert.Equal(Constants.Class24, inprotech.Class.OurValue);
                Assert.Null(inprotech.Class.TheirValue);

                Assert.Equal(Constants.Class1, imported.Class.TheirValue);
                Assert.Null(imported.Class.OurValue);
            }

            static IEnumerable<CaseText> Build(Case inprotechCase)
            {
                var goodsAndServices = inprotechCase.GoodsAndServices()
                                                    .GroupBy(t => t.Class)
                                                    .Select(g => g.OrderBy(_ => _.Language).ThenByDescending(t => t.Number).First())
                                                    .ToArray();

                foreach (var g in goodsAndServices.Where(g => g.Language != null))
                {
                    g.ShortText = string.Empty;
                    g.LongText = string.Empty;
                }

                return goodsAndServices;
            }
        }

        public class DefaultGoodsServicesDataResolverFixture : IFixture<DefaultGoodsServicesDataResolver>
        {
            public DefaultGoodsServicesDataResolverFixture(InMemoryDbContext db)
            {
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

                UseDateComparer = Substitute.For<IUseDateComparer>();
                UseDateComparer.Compare(Arg.Any<DateTime?>(), Arg.Any<string>())
                               .Returns(
                                        x => new FirstUsedDate
                                        {
                                            OurValue = (DateTime?) x[0]
                                        });

                Logger = Substitute.For<IBackgroundProcessLogger<GoodsServicesComparer>>();

                Subject = new DefaultGoodsServicesDataResolver(db, UseDateComparer, classStringComparer, Logger, HtmlAsPlainText);
            }

            public IHtmlAsPlainText HtmlAsPlainText { get; set; }

            public IBackgroundProcessLogger<GoodsServicesComparer> Logger { get; set; }

            public IUseDateComparer UseDateComparer { get; set; }

            public DefaultGoodsServicesDataResolver Subject { get; }
        }
    }
}