using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Integration.DataVerification;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using RelatedCase = InprotechKaizen.Model.Components.Cases.Comparison.Models.RelatedCase;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class RelatedCaseResultBuilderFacts
    {
        public class BuildForMethod : FactBase
        {
            RelatedCase CreateScenario(string country = "US", string officalNo = "111222", string registrationNo = "", string relationcode = "", DateTime? eventDate = null)
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

            CaseRelation GetRelation(string description = "AAA")
            {
                return Db.Set<CaseRelation>().FirstOrDefault(_ => _.Relationship == description);
            }

            RelatedCaseDetails CreateRelatedCaseDetails(string country = "US", string officialNo = "111222", string relation = "AAA")
            {
                var caseRef = new InprotechCaseBuilder(Db, country)
                              .WithCaseEvent(-8, Fixture.PastDate())
                              .WithCaseEvent(-12, Fixture.PastDate())
                              .WithOfficialNumber(true, officialNo, "R", Fixture.PastDate())
                              .WithOfficialNumber(true, "222333", "A", Fixture.PastDate())
                              .WithStatus()
                              .Build();

                var relatedCase = new InprotechKaizen.Model.Cases.RelatedCase(0, country, null, GetRelation(relation), caseRef.Id);

                return new RelatedCaseDetails(relatedCase, caseRef, new Value<string> { OurValue = officialNo, TheirValue = officialNo });
            }

            RelatedCaseDetails CreateRelatedEntityDetails(string country = "US", string officialNo = "111222", string relation = "AAA")
            {
                var relatedCase = new InprotechKaizen.Model.Cases.RelatedCase(0, country, officialNo, GetRelation(relation))
                {
                    PriorityDate = Fixture.PastDate()
                }.In(Db);

                return new RelatedCaseDetails(relatedCase, null, new Value<string> { OurValue = officialNo, TheirValue = officialNo });
            }

            [Fact]
            void ReturnsResultDataForExternalCase()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var scenario = CreateScenario();
                var relation = GetRelation();
                var relatedCaseDetails = CreateRelatedEntityDetails("US", "222333");

                var r = f.Subject.BuildFor(scenario, relation, relatedCaseDetails);

                Assert.Equal("AAA", r.RelationshipCode.OurValue);
                Assert.Equal("US", r.CountryCode.OurValue);
                Assert.Equal(-8, r.EventId.OurValue);
                Assert.Equal("Event", r.EventDescription.OurValue);
                Assert.Equal("222333", r.OfficialNumber.OurValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
            }

            [Fact]
            void ReturnsResultDataForOnlyExternalCase()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var scenario = CreateScenario();
                var relation = GetRelation();
                var relatedCaseDetails = CreateRelatedEntityDetails("US", "222333");

                var r = f.Subject.BuildFor(scenario, relation, relatedCaseDetails);

                Assert.Equal("AAA", r.RelationshipCode.OurValue);
                Assert.Equal("US", r.CountryCode.OurValue);
                Assert.Equal(-8, r.EventId.OurValue);
                Assert.Equal("Event", r.EventDescription.OurValue);
                Assert.Equal("222333", r.OfficialNumber.OurValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
            }

            [Fact]
            void ReturnsResultForCaseRef()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var scenario = CreateScenario();
                var relation = GetRelation();
                var relatedCaseDetails = CreateRelatedEntityDetails("US", "222333");

                var r = f.Subject.BuildFor(scenario, relation, relatedCaseDetails);

                Assert.Equal("AAA", r.RelationshipCode.OurValue);
                Assert.Equal("US", r.CountryCode.OurValue);
                Assert.Equal(-8, r.EventId.OurValue);
                Assert.Equal("Event", r.EventDescription.OurValue);
                Assert.Equal("222333", r.OfficialNumber.OurValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
            }

            [Fact]
            void ReturnsResultForImportedRecord()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var scenario = CreateScenario("US", "111222", string.Empty, "AAA", Fixture.PastDate());
                var relation = GetRelation();

                var r = f.Subject.BuildFor(scenario, relation, null);

                Assert.Equal("AAA", r.RelationshipCode.TheirValue);
                Assert.Equal("US", r.CountryCode.TheirValue);
                Assert.Equal(-8, r.EventId.TheirValue);
                Assert.Equal("Event", r.EventDescription.TheirValue);
                Assert.Equal("111222", r.OfficialNumber.TheirValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.TheirValue);
                Assert.Equal("status", r.ParentStatus.TheirValue);
            }

            [Fact]
            void ReturnsResultOnlyCaseRef()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var r = f.Subject.BuildFor(CreateRelatedCaseDetails("US", "222333"));

                Assert.Equal("AAA", r.RelationshipCode.OurValue);
                Assert.Equal("US", r.CountryCode.OurValue);
                Assert.Equal(-8, r.EventId.OurValue);
                Assert.Equal("Event", r.EventDescription.OurValue);
                Assert.Equal("222333", r.OfficialNumber.OurValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
            }

            [Fact]
            void ReturnsResultWithDifferencesEvaluated()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var scenario = CreateScenario("US", "333444", null, "AAA", Fixture.FutureDate());
                var relation = GetRelation();
                var relatedCaseDetails = CreateRelatedCaseDetails("US", "333444", "BAS");

                var r = f.Subject.BuildFor(scenario, relation, relatedCaseDetails);

                Assert.Equal("BAS", r.RelationshipCode.OurValue);
                Assert.Equal("AAA", r.RelationshipCode.TheirValue);
                Assert.Equal(true, r.RelationshipCode.Different);

                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
                Assert.Equal(Fixture.FutureDate(), r.PriorityDate.TheirValue);
                Assert.Equal(true, r.PriorityDate.Different);
            }

            [Fact]
            void ReturnsResultWithSimilarityEvaluated()
            {
                var f = new RelatedCaseResultBuilderFixture(Db);

                var r = f.Subject.BuildFor(CreateScenario("US", "333444", null, "AAA", Fixture.PastDate()), GetRelation(), CreateRelatedEntityDetails("US", "333444"));

                Assert.Equal("AAA", r.RelationshipCode.OurValue);
                Assert.Equal("AAA", r.RelationshipCode.TheirValue);
                Assert.Equal(false, r.RelationshipCode.Different);

                Assert.Equal(Fixture.PastDate(), r.PriorityDate.OurValue);
                Assert.Equal(Fixture.PastDate(), r.PriorityDate.TheirValue);
                Assert.Equal(false, r.PriorityDate.Different);
            }
        }

        public class BuildMethod : FactBase
        {
            Case CreateScenario()
            {
                return new Case
                {
                    Id = Fixture.Integer()
                };
            }

            VerifiedRelatedCase CreateRelatedCase()
            {
                return new VerifiedRelatedCase()
                {
                    CountryCode = Fixture.String(),
                    RelationshipCode = Fixture.String(),
                    OfficialNumber = Fixture.String()
                };
            }

            [Fact]
            public void ShouldReturnCountryCodeVerifiedStatus()
            {
                var cases = new[]
                {
                    CreateRelatedCase().MatchedValue(),
                    CreateRelatedCase().DifferentValue()
                };

                var parentRelatedCases = cases.Select(x => x.ParentRelatedCase);
                var f = new RelatedCaseResultBuilderFixture(Db, parentRelatedCases);

                var r = f.Subject.Build(CreateScenario(), cases.Select(x => x.VerifiedRelatedCase).ToArray()).ToList();

                Assert.Equal(2, r.Count());
                Assert.False(r.First().CountryCode.Different);
                Assert.True(r.Last().CountryCode.Different);
            }

            [Fact]
            public void ShouldReturnPriorityDateVerifiedStatus()
            {
                var cases = new[]
                {
                    CreateRelatedCase().MatchedValue(),
                    CreateRelatedCase().DifferentValue()
                };

                var parentRelatedCases = cases.Select(x => x.ParentRelatedCase);
                var f = new RelatedCaseResultBuilderFixture(Db, parentRelatedCases);

                var r = f.Subject.Build(CreateScenario(), cases.Select(x => x.VerifiedRelatedCase).ToArray()).ToList();

                Assert.Equal(2, r.Count());
                Assert.False(r.First().PriorityDate.Different);
                Assert.True(r.Last().PriorityDate.Different);
            }

            [Fact]
            public void ShouldOfficialNumberVerifiedStatus()
            {
                var cases = new[]
                {
                    CreateRelatedCase().MatchedValue(),
                    CreateRelatedCase().DifferentValue()
                };

                var parentRelatedCases = cases.Select(x => x.ParentRelatedCase);
                var f = new RelatedCaseResultBuilderFixture(Db, parentRelatedCases);

                var r = f.Subject.Build(CreateScenario(), cases.Select(x => x.VerifiedRelatedCase).ToArray()).ToList();

                Assert.Equal(2, r.Count());
                Assert.False(r.First().OfficialNumber.Different);
                Assert.True(r.Last().OfficialNumber.Different);
            }

            [Fact]
            public void ShouldReturnValidEventDescription()
            {
                var cases = new[]
                {
                    CreateRelatedCase().MatchedValue(Fixture.Integer(), Fixture.Integer()),
                    CreateRelatedCase().DifferentValue()
                };

                var parentRelatedCases = cases.Select(x => x.ParentRelatedCase);
                var f = new RelatedCaseResultBuilderFixture(Db, parentRelatedCases);
                var eventDescription = Fixture.String();
                var validEvent = new ValidEvent(cases[0].ParentRelatedCase.RelationId, cases[0].ParentRelatedCase.EventId ?? 0, eventDescription);
                f.ValidEventResolver.Resolve(Arg.Any<int>(), Arg.Any<int>())
                 .Returns(validEvent);
                validEvent.In(Db);

                var r = f.Subject.Build(CreateScenario(), cases.Select(x => x.VerifiedRelatedCase).ToArray()).ToList();

                Assert.Equal(2, r.Count());
                Assert.Equal(r.First().EventDescription.OurValue, eventDescription);
                Assert.Equal(r.Last().EventDescription.OurValue, string.Empty);
            }

            [Fact]
            public void ShouldReturnRelatedCaseDetails()
            {
                var c1 = CreateRelatedCase().DifferentValue();

                var cases = new[]
                {
                    c1
                };

                var parentRelatedCases = cases.Select(x => x.ParentRelatedCase);
                var f = new RelatedCaseResultBuilderFixture(Db, parentRelatedCases);

                var r = f.Subject.Build(CreateScenario(), cases.Select(x => x.VerifiedRelatedCase).ToArray()).ToList();

                Assert.Single(r);
                Assert.Equal(r.First().OfficialNumber.OurValue, c1.VerifiedRelatedCase.InputOfficialNumber);
                Assert.Equal(r.First().OfficialNumber.TheirValue, c1.VerifiedRelatedCase.OfficialNumber);

                Assert.Equal(r.First().RelatedCaseRef, c1.ParentRelatedCase.RelatedCaseRef);
                Assert.Equal(r.First().RelatedCaseRef, c1.ParentRelatedCase.RelatedCaseRef);
                Assert.Equal(r.First().EventId.OurValue, c1.ParentRelatedCase.EventId);

                Assert.Equal(r.First().OfficialNumber.OurValue, c1.VerifiedRelatedCase.InputOfficialNumber);
                Assert.Equal(r.First().OfficialNumber.TheirValue, c1.VerifiedRelatedCase.OfficialNumber);

                Assert.Equal(r.First().RelationshipCode.OurValue, c1.VerifiedRelatedCase.RelationshipCode);
                Assert.Equal(r.First().RelationshipCode.TheirValue, c1.VerifiedRelatedCase.RelationshipCode);
            }
        }
    }

    class VerifiedRelatedCaseModel
    {
        public ParentRelatedCase ParentRelatedCase { get; set; }
        public VerifiedRelatedCase VerifiedRelatedCase { get; set; }
    }
    static class VerifiedRelatedCaseExtensionMethods
    {
        public static VerifiedRelatedCaseModel MatchedValue(this VerifiedRelatedCase relCase, int? relCaseId = null, int? eventId = null)
        {
            relCase.CountryCodeVerified = true;
            relCase.EventDateVerified = true;
            relCase.OfficialNumberVerified = true;
            return new VerifiedRelatedCaseModel()
            {
                ParentRelatedCase = new ParentRelatedCase()
                {
                    Number = relCase.InputOfficialNumber,
                    Date = relCase.InputEventDate,
                    CountryCode = relCase.CountryCode,
                    Relationship = relCase.RelationshipCode,
                    RelatedCaseId = relCaseId,
                    EventId = eventId
                },
                VerifiedRelatedCase = relCase
            };
        }
        public static VerifiedRelatedCaseModel DifferentValue(this VerifiedRelatedCase relCase, int? relCaseId = null, int? eventId = null)
        {
            relCase.CountryCodeVerified = false;
            relCase.EventDateVerified = false;
            relCase.OfficialNumberVerified = false;

            return new VerifiedRelatedCaseModel()
            {
                ParentRelatedCase = new ParentRelatedCase()
                {
                    Number = relCase.InputOfficialNumber,
                    Date = relCase.InputEventDate,
                    CountryCode = relCase.CountryCode,
                    Relationship = relCase.RelationshipCode,
                    RelatedCaseId = relCaseId,
                    EventId = eventId
                },
                VerifiedRelatedCase = relCase
            };
        }
    }

    internal class RelatedCaseResultBuilderFixture : IFixture<IRelatedCaseResultBuilder>
    {
        readonly InMemoryDbContext _db;

        public RelatedCaseResultBuilderFixture(InMemoryDbContext db, IEnumerable<ParentRelatedCase> parentRelatedCases = null)
        {
            _db = db;
            ValidEventResolver = Substitute.For<IValidEventResolver>();
            ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<int>()).Returns((ValidEvent)null);

            ParentRelatedCases = Substitute.For<IParentRelatedCases>();
            if (parentRelatedCases != null)
                ParentRelatedCases.Resolve(Arg.Any<int[]>(), Arg.Any<string[]>())
                 .Returns(parentRelatedCases);

            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            SetMasterData();

            Subject = new RelatedCaseResultBuilder(_db, ValidEventResolver, PreferredCultureResolver, ParentRelatedCases);
        }

        public IValidEventResolver ValidEventResolver { get; }

        public IParentRelatedCases ParentRelatedCases { get; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public IRelatedCaseResultBuilder Subject { get; }

        void SetMasterData()
        {
            new SiteControl(SiteControls.EarliestPriority, "BAS").In(_db);
            MasterDataBuilder.BuildNumberTypeAndRelatedEvent(_db, "A", "Application", -4);
            MasterDataBuilder.BuildCaseRelation(_db, "AAA", -8);
            MasterDataBuilder.BuildCaseRelation(_db, "BAS", -12);
        }
    }
}