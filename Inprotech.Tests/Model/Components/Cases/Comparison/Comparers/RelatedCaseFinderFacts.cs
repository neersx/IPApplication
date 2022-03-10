using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using Xunit;
using RelatedCase = InprotechKaizen.Model.Components.Cases.Comparison.Models.RelatedCase;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class RelatedCaseFinderFacts
    {
        public class FindForMethod : FactBase
        {
            [Theory]
            [InlineData("11111111", "PCT11/11/1111")]
            [InlineData("11-11-11", "PCT11/11/11")]
            [InlineData("11A-1B1-1C1", "111111")]
            public void NumberMatchingLogicConsidersNumbersOnly(string inprotechNo, string importedNo)
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment(inprotechNo);

                var result = f.Subject.FindFor(CreateScenario("BR", importedNo, null, "BBB", Fixture.PastDate()));

                Assert.NotNull(result);
            }

            static RelatedCase CreateScenario(string country = "US", string officalNo = "111222", string registrationNo = "", string relationcode = "", DateTime? eventDate = null)
            {
                return new RelatedCase
                {
                    CountryCode = country,
                    Description = "Description",
                    EventDate = eventDate,
                    OfficialNumber = officalNo,
                    RegistrationNumber = registrationNo,
                    RelationshipCode = relationcode,
                    Status = "status"
                };
            }

            [Fact]
            void CheckOfficalNumbersMatch()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "333A/444", null, "BBB", Fixture.PastDate()));

                Assert.Equal("333444", result.MatchedOfficialNumber.OurValue);
                Assert.Equal("333A/444", result.MatchedOfficialNumber.TheirValue);
            }

            [Fact]
            public void ReturnsCaseWithMatchingRelation()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "454545", null, "BBB", Fixture.PastDate()));

                Assert.NotNull(result);

                Assert.Equal("454545", result.CaseRef.OfficialNumbers.First().Number);
                Assert.Equal("AU", result.CaseRef.Country.Id);
            }

            [Fact]
            public void ReturnsCaseWithNonMatchingRelation()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "454545", null, "CCC", Fixture.PastDate()));

                Assert.NotNull(result);

                Assert.Equal("454545", result.CaseRef.OfficialNumbers.First().Number);
                Assert.Equal("AU", result.CaseRef.Country.Id);
            }

            [Fact]
            public void ReturnsExternalCaseWithMatchingRelation()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "333222", null, "AAA", Fixture.PastDate()));

                Assert.NotNull(result);

                Assert.Equal("AAA", result.RelatedCase.Relation.Relationship);
                Assert.Equal("333222", result.RelatedCase.OfficialNumber);
                Assert.Equal("AU", result.RelatedCase.CountryCode);
                Assert.Equal(Fixture.FutureDate(), result.RelatedCase.PriorityDate);
            }

            [Fact]
            public void ReturnsExternalCaseWithNonmatchingRelation()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "333222", null, "CCC", Fixture.PastDate()));

                Assert.NotNull(result);

                Assert.Equal("AAA", result.RelatedCase.Relation.Relationship);
                Assert.Equal("333222", result.RelatedCase.OfficialNumber);
                Assert.Equal("AU", result.RelatedCase.CountryCode);
                Assert.Equal(Fixture.FutureDate(), result.RelatedCase.PriorityDate);
            }

            [Fact]
            public void ReturnsNoResultIfNoDataPresent()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(new RelatedCase());

                Assert.Null(result);
            }

            [Fact]
            public void ReturnsNoResultIfNomatchingOfficalNumbers()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("BR", "675789"));

                Assert.Null(result);
            }

            [Fact]
            void ReturnsOnlyUnmachedCases()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                f.Subject.FindFor(CreateScenario("AU", "333A/444", null, "BBB", Fixture.PastDate()));
                var result = f.Subject.FindFor(new CaseRelation("BBB", null));

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void ReturnsRelatedCasesWithRelation()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(new CaseRelation("AAA", null));

                Assert.Equal(4, result.Count());
            }

            [Fact]
            public void ReturnsRelationOfRelatedCase()
            {
                var f = new RelatedCaseFinderFixture(Db)
                    .WithPreparedEnvironment();

                var result = f.Subject.FindFor(CreateScenario("AU", "454545", null, "AAA", Fixture.PastDate()));

                Assert.NotNull(result.CaseRef);
                Assert.NotNull(result.RelatedCase);
                Assert.Equal("BBB", result.RelatedCase.Relation.Relationship);
            }
        }
    }

    public class RelatedCaseFinderFixture : IFixture<IRelatedCaseFinder>
    {
        readonly InMemoryDbContext _db;

        public RelatedCaseFinderFixture(InMemoryDbContext db)
        {
            _db = db;
            Subject = new RelatedCaseFinder(db);
        }

        public IRelatedCaseFinder Subject { get; }

        public RelatedCaseFinderFixture WithPreparedEnvironment(string relatedOfficalNo = null)
        {
            Subject.PrepareFor(CreateCase(relatedOfficalNo));

            return this;
        }

        Case CreateCase(string relatedOfficalNo = null)
        {
            MasterDataBuilder.BuildNumberTypeAndRelatedEvent(_db, "A", "Application", -4);
            MasterDataBuilder.BuildNumberTypeAndRelatedEvent(_db, "R", "Registration", -8);

            var caseRef = new InprotechCaseBuilder(_db, "AU")
                          .WithCaseEvent(-8, Fixture.PastDate())
                          .WithCaseEvent(-12, Fixture.PastDate())
                          .WithOfficialNumber(true, "333444", "R", Fixture.PastDate())
                          .WithOfficialNumber(true, "222333", "A", Fixture.PastDate())
                          .Build();

            var relation1 = MasterDataBuilder.BuildCaseRelation(_db, "AAA", -4);
            var relation2 = MasterDataBuilder.BuildCaseRelation(_db, "BBB", -4);

            return new InprotechCaseBuilder(_db)
                   .WithRelatedCaseEntity("US", "111222", relation1, Fixture.PastDate())
                   .WithRelatedCaseEntity("AU", "333222", relation1, Fixture.FutureDate())
                   .WithRelatedCaseEntity("US", "111444", relation2, Fixture.PastDate())
                   .WithRelatedCaseEntity("US", "454545", relation1, Fixture.PastDate())
                   .WithRelatedCaseEntity("BR", relatedOfficalNo, relation1, Fixture.PastDate())
                   .WithRelatedCaseEntity("6789", "AU", "454545", relation2, Fixture.FutureDate())
                   .WithRelatedCaseEntity(caseRef, relation2)
                   .Build().In(_db);
        }
    }
}