using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Integration.DataVerification;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases;
using RelatedCase = InprotechKaizen.Model.Components.Cases.Comparison.Models.RelatedCase;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class ParentRelatedCasesComparerFacts
    {
        public class CompareMethod : FactBase
        {
            readonly RelatedCaseComparisonScenarioBuilder _scenarioBuilder = new RelatedCaseComparisonScenarioBuilder();

            static RelatedCase NewRelatedCase(string country = "US", string officialNo = "111222")
            {
                return new RelatedCase
                {
                    CountryCode = country,
                    Description = "Description",
                    EventDate = Fixture.PastDate(),
                    OfficialNumber = officialNo,
                    RegistrationNumber = "R33333",
                    RelationshipCode = "AAA",
                    Status = "Status received"
                };
            }

            [Fact]
            public void ReturnsNoResultForZeroImportedRelatedCases()
            {
                var f = new ParentRelatedCasesComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                            .WithOfficialNumber(true, "11111", "A")
                            .Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, Enumerable.Empty<ComparisonScenario<RelatedCase>>(), cr);

                Assert.Null(cr.ParentRelatedCases);
            }

            [Fact]
            public void ReturnsResultByComparingWithInprotechCase()
            {
                var relatedCase = new InprotechCaseBuilder(Db, "US")
                                  .WithOfficialNumber(true, "111222", "A", Fixture.FutureDate())
                                  .Build();

                var f = new ParentRelatedCasesComparerFixture(Db)
                    .ReturnsCase(relatedCase, "AAA");

                var @case = new InprotechCaseBuilder(Db).Build();

                _scenarioBuilder.RelatedCase = NewRelatedCase();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, cr);

                Assert.Single(cr.ParentRelatedCases);

                Assert.Equal("US", cr.ParentRelatedCases.First().CountryCode.TheirValue);
                Assert.Equal(Fixture.PastDate(), cr.ParentRelatedCases.First().PriorityDate.TheirValue);

                Assert.Equal("US", cr.ParentRelatedCases.First().CountryCode.OurValue);
                Assert.Null(cr.ParentRelatedCases.First().PriorityDate.OurValue);
            }

            [Fact]
            public void ReturnsResultByComparingWithInprotechRelatedCase()
            {
                var f = new ParentRelatedCasesComparerFixture(Db)
                    .ReturnsRelatedCase("AAA");

                var @case = new InprotechCaseBuilder(Db).Build();

                _scenarioBuilder.RelatedCase = NewRelatedCase();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, cr);

                Assert.Single(cr.ParentRelatedCases);

                Assert.Equal("US", cr.ParentRelatedCases.First().CountryCode.TheirValue);
                Assert.Equal(Fixture.PastDate(), cr.ParentRelatedCases.First().PriorityDate.TheirValue);

                Assert.Equal(Fixture.PastDate(), cr.ParentRelatedCases.First().PriorityDate.TheirValue);
            }

            [Fact]
            public void ReturnsResultWithInprotechDataAsSeprateRecord()
            {
                var f = new ParentRelatedCasesComparerFixture(Db)
                    .ReturnsCasesForRelation("EP", "AAA", "AB333567", Fixture.PastDate().AddDays(-2));

                var @case = new InprotechCaseBuilder(Db)
                    .Build();
                _scenarioBuilder.RelatedCase = NewRelatedCase();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, cr);

                Assert.Equal(2, cr.ParentRelatedCases.Count());

                Assert.Equal("111222", cr.ParentRelatedCases.First().OfficialNumber.TheirValue);
                Assert.Equal("US", cr.ParentRelatedCases.First().CountryCode.TheirValue);
                Assert.Equal(Fixture.PastDate(), cr.ParentRelatedCases.First().PriorityDate.TheirValue);

                Assert.Null(cr.ParentRelatedCases.First().OfficialNumber.OurValue);

                Assert.Equal("AB333567", cr.ParentRelatedCases.Last().OfficialNumber.OurValue);
                Assert.Equal("EP", cr.ParentRelatedCases.Last().CountryCode.OurValue);
                Assert.Equal(Fixture.PastDate().AddDays(-2), cr.ParentRelatedCases.Last().PriorityDate.OurValue);

                Assert.Null(cr.ParentRelatedCases.Last().OfficialNumber.TheirValue);
            }

            [Fact]
            public void ReturnsResultWithOnlyImportedData()
            {
                var f = new ParentRelatedCasesComparerFixture(Db);

                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                _scenarioBuilder.RelatedCase = NewRelatedCase();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, cr);

                Assert.Single(cr.ParentRelatedCases);

                Assert.Equal("111222", cr.ParentRelatedCases.First().OfficialNumber.TheirValue);
                Assert.Equal("US", cr.ParentRelatedCases.First().CountryCode.TheirValue);
                Assert.Equal(Fixture.PastDate(), cr.ParentRelatedCases.First().PriorityDate.TheirValue);

                Assert.Null(cr.ParentRelatedCases.First().OfficialNumber.OurValue);
            }

            [Fact]
            public void ReturnsUnmachedCasesForRelationOnlyOnce()
            {
                var f = new ParentRelatedCasesComparerFixture(Db)
                    .ReturnsCasesForRelation("EP", "AAA", "AB333567", Fixture.PastDate().AddDays(-2));

                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                _scenarioBuilder.RelatedCase = NewRelatedCase();
                var case1 = _scenarioBuilder.Build();

                _scenarioBuilder.RelatedCase = NewRelatedCase("US", "1112223");
                var case2 = _scenarioBuilder.Build();

                var cr = new ComparisonResult(Fixture.String());

                f.Subject.Compare(@case, new[] {case1, case2}, cr);

                Assert.Equal(3, cr.ParentRelatedCases.Count());

                Assert.Equal("AB333567", cr.ParentRelatedCases.Last().OfficialNumber.OurValue);
                Assert.Equal("EP", cr.ParentRelatedCases.Last().CountryCode.OurValue);
                Assert.Equal(Fixture.PastDate().AddDays(-2), cr.ParentRelatedCases.Last().PriorityDate.OurValue);

                Assert.Null(cr.ParentRelatedCases.Last().OfficialNumber.TheirValue);
            }
        }
    }

    public class ParentRelatedCasesComparerFixture : IFixture<ISpecificComparer>
    {
        readonly InMemoryDbContext _db;

        public ParentRelatedCasesComparerFixture(InMemoryDbContext db)
        {
            _db = db;
            RelatedCaseFinder = Substitute.For<IRelatedCaseFinder>();
            ParentRelatedCases = Substitute.For<IParentRelatedCases>();
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();

            RelatedCaseResultBuilder = new RelatedCaseResultBuilder(db, new ValidEventResolver(db), cultureResolver, ParentRelatedCases);

            Subject = new ParentRelatedCasesComparer(db, RelatedCaseFinder, RelatedCaseResultBuilder);

            SetMasterData();
        }

        public IRelatedCaseFinder RelatedCaseFinder { get; }

        public IRelatedCaseResultBuilder RelatedCaseResultBuilder { get; }

        public IParentRelatedCases ParentRelatedCases { get; }

        public ISpecificComparer Subject { get; }

        public ParentRelatedCasesComparerFixture ReturnsCasesForRelation(string country, string relationId = "Relation", string officialNo = "333444", DateTime? dateTime = null)
        {
            var caseRelation = _db.Set<Case.CaseRelation>()
                                  .SingleOrDefault(_ => _.Relationship == relationId)
                               ?? new Case.CaseRelation(relationId, null).In(_db);

            var relatedCase = new Case.RelatedCase(1, country, officialNo, caseRelation)
            {
                PriorityDate = dateTime
            }.In(_db);

            RelatedCaseFinder.FindFor(Arg.Any<Case.CaseRelation>())
                             .Returns(new[] {new RelatedCaseDetails(relatedCase, null, null)});

            return this;
        }

        public ParentRelatedCasesComparerFixture ReturnsCase(Case.Case @case, string relationId = "Relation")
        {
            var caseRelation = _db.Set<Case.CaseRelation>()
                                  .SingleOrDefault(_ => _.Relationship == relationId)
                               ?? new Case.CaseRelation(relationId, null).In(_db);

            var relatedCase = new Case.RelatedCase(1, @case.Country.Id, string.Empty, caseRelation);

            RelatedCaseFinder.FindFor(Arg.Any<RelatedCase>())
                             .Returns(new RelatedCaseDetails(relatedCase, @case, new Value<string>()));

            return this;
        }

        public ParentRelatedCasesComparerFixture ReturnsRelatedCase(string relationId = "Relation", string countryCode = "US", string officialNumber = "111222")
        {
            var caseRelation = _db.Set<Case.CaseRelation>()
                                  .SingleOrDefault(_ => _.Relationship == relationId)
                               ?? new Case.CaseRelation(relationId, null).In(_db);

            var relatedCase = new Case.RelatedCase(1, countryCode, officialNumber, caseRelation)
            {
                PriorityDate = Fixture.PastDate()
            };

            RelatedCaseFinder.FindFor(Arg.Any<RelatedCase>())
                             .Returns(new RelatedCaseDetails(relatedCase, null, new Value<string>()));

            return this;
        }

        void SetMasterData()
        {
            new SiteControl(SiteControls.EarliestPriority, "BAS").In(_db);
            MasterDataBuilder.BuildNumberTypeAndRelatedEvent(_db, "A", "Application", -4);
            MasterDataBuilder.BuildCaseRelation(_db, "AAA", 0);
        }
    }
}