using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class RelatedParentCasesResolverFacts : FactBase
    {
        readonly string[] _relationshipCodes = 
        {
            KnownRelations.PctParentApp,
            KnownRelations.EarliestPriority
        };

        [Fact]
        public void ReturnsAtMostOneRelatedParentPerCasePerType()
        {
            var case1 = CreateCase();
            var case2 = CreateCase();

            //Case 1
            var relCase1 = new RelatedCase(case1.Id, KnownRelations.PctParentApp, Fixture.String())
            {
                PriorityDate = Fixture.Date()
            };
            var relCase4 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.FutureDate()
            };
            var relCase5 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.PastDate()
            };

            //Case2
            var relCase2 = new RelatedCase(case2.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.FutureDate()
            };
            var relCase3 = new RelatedCase(case2.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.PastDate()
            };

            new[]
            {
                relCase1,
                relCase4,
                relCase5,
                relCase2,
                relCase3
            }.In(Db);

            var cases = new[]
            {
                case1,
                case2
            };

            var subject = new ParentRelatedCasesFixture(Db).Subject;
            var relatedParents = subject.Resolve(cases.Select(_ => _.Id).ToArray(), _relationshipCodes).ToList();

            //Correct Records are returned
            Assert.Equal(3, relatedParents.Count());
            Assert.Equal(relatedParents[0].CaseKey, case1.Id);
            Assert.Equal(relatedParents[1].CaseKey, case1.Id);
            Assert.Equal(relatedParents[2].CaseKey, case2.Id);

            Assert.Equal(relatedParents[0].CountryCode, relCase1.CountryCode);
            Assert.Equal(relatedParents[1].CountryCode, relCase5.CountryCode);
            Assert.Equal(relatedParents[2].CountryCode, relCase3.CountryCode);

            Assert.Equal(relatedParents[0].Relationship, KnownRelations.PctParentApp);
            Assert.Equal(relatedParents[1].Relationship, KnownRelations.EarliestPriority);
            Assert.Equal(relatedParents[2].Relationship, KnownRelations.EarliestPriority);

            //Earliest Dates are returned
            Assert.Equal(relatedParents[0].Date, relCase1.PriorityDate);
            Assert.Equal(relatedParents[1].Date, relCase3.PriorityDate);
            Assert.Equal(relatedParents[2].Date, relCase5.PriorityDate);
        }

        [Fact]
        public void ReturnRelationshipsWithDatesBeforeNullDates()
        {
            var case1 = CreateCase();

            //Case 1
            var relCase1 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = null
            };

            //Case2
            var relCase2 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.FutureDate()
            };

            new[]
            {
                relCase1,
                relCase2
            }.In(Db);

            var cases = new[]
            {
                case1
            }.In(Db);

            var subject = new ParentRelatedCasesFixture(Db).Subject;
            var relatedParents = subject.Resolve(cases.Select(_ => _.Id).ToArray(), _relationshipCodes).ToList();

            //Only One record returned per pair
            Assert.Single(relatedParents);

            //Null dates are after all dates
            Assert.Equal(relatedParents[0].Date, relCase2.PriorityDate);
        }

        [Fact]
        public void ReturnNullDateRecordIfNoneWithDates()
        {
            var relationshipCodeResolver = Substitute.For<IRelationshipCodeResolver>();
            relationshipCodeResolver.ResolveMapping(Arg.Any<string[]>()).Returns(new Dictionary<string, string>());

            var case1 = CreateCase();
            var case2 = CreateCase();

            //Case 1
            var relCase1 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = null
            };

            //Case2
            var relCase2 = new RelatedCase(case2.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = Fixture.FutureDate()
            };

            new[]
            {
                relCase1,
                relCase2
            }.In(Db);

            var cases = new[]
            {
                case1,
                case2
            }.In(Db);

            var subject = new ParentRelatedCasesFixture(Db).Subject;
            var relatedParents = subject.Resolve(cases.Select(_ => _.Id).ToArray(), _relationshipCodes).ToList();

            //Only One record returned per pair
            Assert.Equal(2, relatedParents.Count());

            //Null dates are after all dates
            Assert.Equal(relatedParents[0].Date, relCase1.PriorityDate);
            Assert.Equal(relatedParents[1].Date, relCase2.PriorityDate);
        }

        [Fact]
        public void ReturnAnyRelationshipIfOnlyMultipleRecordsWithNullDates()
        {
            var case1 = CreateCase();

            //Case 1
            var relCase1 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = null
            };

            //Case2
            var relCase2 = new RelatedCase(case1.Id, KnownRelations.EarliestPriority, Fixture.String())
            {
                PriorityDate = null
            };

            new[]
            {
                relCase1,
                relCase2
            }.In(Db);

            var cases = new[]
            {
                case1
            }.In(Db);

            var subject = new ParentRelatedCasesFixture(Db).Subject;
            var relatedParents = subject.Resolve(cases.Select(_ => _.Id).ToArray(), _relationshipCodes).ToList();

            //Only One record returned per pair
            Assert.Single(relatedParents);

            //Null dates are after all dates
            Assert.Equal(relatedParents[0].Date, relCase1.PriorityDate);
        }

        [Fact]
        public void NoCasePullsRelatedCaseCountryCode()
        {
            var case1 = CreateCase();

            var relCase1 = new RelatedCase(case1.Id, KnownRelations.PctParentApp, Fixture.String())
            {
                PriorityDate = Fixture.Date()
            };

            new[]
            {
                relCase1
            }.In(Db);

            var subject = new ParentRelatedCasesFixture(Db).Subject;

            var relatedParents = subject.Resolve(new[] { case1.Id }, _relationshipCodes).ToList();

            Assert.Single(relatedParents);
            Assert.Equal(relatedParents[0].CountryCode, relCase1.CountryCode);
        }

        [Fact]
        public void CaseLinkageUseParentCaseCountryCode()
        {
            var case1 = CreateCase();
            var case2 = CreateCase();

            var relCase1 = new RelatedCase(case1.Id, KnownRelations.PctParentApp, Fixture.String())
            {
                PriorityDate = Fixture.Date(),
                RelatedCaseId = case2.Id
            };

            new[]
            {
                relCase1
            }.In(Db);

            var cases = new[]
            {
                case1,
                case2
            }.In(Db);

            var subject = new ParentRelatedCasesFixture(Db).Subject;

            var relatedParents = subject.Resolve(cases.Select(_ => _.Id).ToArray(), _relationshipCodes).ToList();

            Assert.Single(relatedParents);

            Assert.Equal(relatedParents[0].CountryCode, case2.CountryId);
        }

        static Case CreateCase()
        {
            return new Case
            {
                Id = Fixture.Integer(),
                CountryId = Fixture.String(),
                CurrentOfficialNumber = Fixture.String()
            };
        }

        public class ParentRelatedCasesFixture : IFixture<ParentRelatedCases>
        {
            public ParentRelatedCases Subject
            {
                get;
            }

            public ParentRelatedCasesFixture(InMemoryDbContext db)
            {
                new CaseRelation(KnownRelations.PctParentApp, null).In(db);
                new CaseRelation(KnownRelations.EarliestPriority, null).In(db);
                Subject = new ParentRelatedCases(db);
            }
        }

    }
}
