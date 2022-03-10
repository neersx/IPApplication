using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using InprotechKaizen.Model.Components.Cases.Events;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using ComparisonModels = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class NumbersComparerFacts
    {
        public class CompareMethod : FactBase
        {
            readonly OfficialNumberComparisonScenarioBuilder _scenarioBuilder =
                new OfficialNumberComparisonScenarioBuilder();

            readonly MatchingNumberEventComparisonScenarioBuilder _matchingEventBuilder =
                new MatchingNumberEventComparisonScenarioBuilder();

            [Fact]
            public void ReturnComparedData()
            {
                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .Build();

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Number = "2222",
                    NumberType = "A",
                    Code = "Application"
                };

                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    Id = -4,
                    EventCode = "Application"
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Single(cr.OfficialNumbers);

                Assert.Equal("Application", cr.OfficialNumbers.First().NumberType);

                Assert.Equal("11111", cr.OfficialNumbers.First().Number.OurValue);
                Assert.Equal("2222", cr.OfficialNumbers.First().Number.TheirValue);
                Assert.Equal(true, cr.OfficialNumbers.First().Number.Different);
                Assert.Equal(true, cr.OfficialNumbers.First().Number.Updateable);

                Assert.Equal("A", cr.OfficialNumbers.First().MappedNumberTypeId);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
            }

            [Fact]
            public void ReturnComparedDataWithEventDates()
            {
                DateTime? dateTime1 = new DateTime(2015, 12, 11);
                DateTime? dateTime2 = new DateTime(2015, 1, 3);

                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .WithCaseEvent(-4, dateTime1)
                            .Build();

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Code = "Application",
                    Number = "2222",
                    NumberType = "A",
                    EventDate = dateTime2
                };
                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    EventDate = dateTime2,
                    EventCode = "Application",
                    Id = -4
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Single(cr.OfficialNumbers);
                Assert.Equal("Application", cr.OfficialNumbers.First().NumberType);

                Assert.Equal(dateTime1, cr.OfficialNumbers.First().EventDate.OurValue);
                Assert.Equal(dateTime2, cr.OfficialNumbers.First().EventDate.TheirValue);
                Assert.Equal(true, cr.OfficialNumbers.First().Number.Different);
                Assert.Equal(true, cr.OfficialNumbers.First().Number.Updateable);

                Assert.Equal("A", cr.OfficialNumbers.First().MappedNumberTypeId);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
            }

            [Fact]
            public void ReturnComparedDataWithMatchingData()
            {
                DateTime? dateTime = new DateTime(2015, 12, 11);

                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "1111", "A")
                            .WithCaseEvent(-4, dateTime)
                            .Build();

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Code = "Application",
                    Number = "1111",
                    NumberType = "A",
                    EventDate = dateTime
                };
                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    EventDate = dateTime,
                    EventCode = "Application",
                    Id = -4
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Single(cr.OfficialNumbers);
                Assert.Equal("Application", cr.OfficialNumbers.First().NumberType);

                Assert.Equal("1111", cr.OfficialNumbers.First().Number.OurValue);
                Assert.Equal("1111", cr.OfficialNumbers.First().Number.TheirValue);
                Assert.Equal(false, cr.OfficialNumbers.First().Number.Different);
                Assert.Equal(false, cr.OfficialNumbers.First().Number.Updateable);

                Assert.Equal(dateTime, cr.OfficialNumbers.First().EventDate.OurValue);
                Assert.Equal(dateTime, cr.OfficialNumbers.First().EventDate.TheirValue);
                Assert.Equal(false, cr.OfficialNumbers.First().Number.Different);
                Assert.Equal(false, cr.OfficialNumbers.First().Number.Updateable);

                Assert.Equal("A", cr.OfficialNumbers.First().MappedNumberTypeId);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
            }

            [Fact]
            public void ReturnComparedDataWithoutUnmatchedData()
            {
                DateTime? dateTime1 = new DateTime(2015, 12, 11);
                DateTime? dateTime2 = new DateTime(2014, 12, 11);

                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "2222", "R")
                            .WithCaseEvent(-4, dateTime1)
                            .Build();

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Code = "Application",
                    Number = "1111",
                    NumberType = "A",
                    EventDate = dateTime2
                };
                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    EventDate = dateTime2,
                    EventCode = "Application",
                    Id = -4
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Single(cr.OfficialNumbers);
                Assert.Equal("A", cr.OfficialNumbers.First().MappedNumberTypeId);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
            }

            [Fact]
            public void ReturnsFirstCycleForMatchingCaseEvent()
            {
                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .WithCaseEvent(-4, Fixture.PastDate())
                            .Build();

                @case.OfficialNumbers.First().NumberId = 888;

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Code = "Application",
                    Number = "2222",
                    NumberType = "A"
                };

                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    EventCode = "Application",
                    Id = -4
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Equal(888, cr.OfficialNumbers.First().Id);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
                Assert.Equal(1, cr.OfficialNumbers.First().Cycle.GetValueOrDefault());
            }

            [Fact]
            public void ReturnsInprotechNumberAndEventIds()
            {
                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .Build();

                @case.OfficialNumbers.First().NumberId = 888;

                _scenarioBuilder.OfficialNumber = new ComparisonModels.OfficialNumber
                {
                    Code = "Application",
                    Number = "2222",
                    NumberType = "A"
                };
                _matchingEventBuilder.Event = new ComparisonModels.MatchingNumberEvent
                {
                    EventCode = "Application",
                    Id = -4
                };

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new ComparisonScenario[]
                {
                    _scenarioBuilder.Build(),
                    _matchingEventBuilder.Build()
                }, cr);

                Assert.Equal("A", cr.OfficialNumbers.First().MappedNumberTypeId);
                Assert.Equal(888, cr.OfficialNumbers.First().Id);
                Assert.Equal(-4, cr.OfficialNumbers.First().EventNo);
            }

            [Fact]
            public void ReturnsNoResultForZeroImportedNumbers()
            {
                var f = new NumbersComparerFixture(Db)
                    .ReturnsValidEvent();

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, Enumerable.Empty<ComparisonScenario<InprotechKaizen.Model.Components.Cases.Comparison.Models.OfficialNumber>>(), cr);

                Assert.Empty(cr.OfficialNumbers);
            }
        }

        public class NumbersComparerFixture : IFixture<NumbersComparer>
        {
            readonly InMemoryDbContext _db;

            public NumbersComparerFixture(InMemoryDbContext db)
            {
                _db = db;
                ValidEventResolver = Substitute.For<IValidEventResolver>();

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                var translator = Substitute.For<IEventDescriptionTranslator>();
                translator.Translate<InprotechKaizen.Model.Components.Cases.Comparison.Results.OfficialNumber>(null)
                          .ReturnsForAnyArgs(x => x[0]);

                Subject = new NumbersComparer(db, ValidEventResolver, cultureResolver, translator);

                SetMasterData();
            }

            public IValidEventResolver ValidEventResolver { get; set; }

            public NumbersComparer Subject { get; }

            public NumbersComparerFixture ReturnsValidEvent(string description = "valid description")
            {
                ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>())
                                  .Returns(new ValidEventBuilder
                                  {
                                      Description = description
                                  }.Build());
                return this;
            }

            void SetMasterData()
            {
                MasterDataBuilder.BuildNumberTypeAndRelatedEvent(_db, "A", "Application", -4);
            }
        }
    }
}