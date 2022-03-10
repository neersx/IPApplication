using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class CriticalDatesPriorityInfoResolverFacts
    {
        public class PriorityDetailsScenario
        {
            readonly InMemoryDbContext _db;

            public PriorityDetailsScenario(InMemoryDbContext db)
            {
                _db = db;

                CreateThisCase();

                CreateEventIncludedInCriticalDatesActionCriteria();
            }

            public Case Case { get; set; }

            public Case PriorityCase { get; set; }

            public CaseRelation EarliestPriorityRelation { get; set; }

            public Criteria CriticalDatesCriteria { get; set; }

            Case CreatePriorityCase()
            {
                return new CaseBuilder
                {
                    Country = new CountryBuilder
                    {
                        Name = Fixture.String("Priority")
                    }.Build().In(_db)
                }.Build().In(_db);
            }

            void CreateThisCase()
            {
                Case = new CaseBuilder
                {
                    Country = new CountryBuilder
                    {
                        Name = Fixture.String("ThisCase")
                    }.Build().In(_db)
                }.Build().In(_db);
            }

            void CreateEventIncludedInCriticalDatesActionCriteria()
            {
                CriticalDatesCriteria = new CriteriaBuilder
                {
                    Action = new ActionBuilder().Build().In(_db)
                }.Build().In(_db);

                var ve = new ValidEventBuilder().For(CriticalDatesCriteria, new EventBuilder().Build().In(_db)).Build().In(_db);

                CriticalDatesCriteria.ValidEvents.Add(ve);
            }

            public PriorityDetailsScenario WithEarliestPriorityRelationConfigured(string relationship = "BAS", int? fromEventId = null, int? toEventId = null, int? displayEventId = null)
            {
                new SiteControl(SiteControls.EarliestPriority)
                {
                    StringValue = relationship
                }.In(_db);

                EarliestPriorityRelation = new CaseRelation
                {
                    Relationship = relationship
                }.In(_db);

                EarliestPriorityRelation.SetFlags(true);

                var priorityEvent = CriticalDatesCriteria.ValidEvents.Single().Event;

                EarliestPriorityRelation.SetEvents(fromEventId ?? priorityEvent.Id, toEventId ?? priorityEvent.Id, displayEventId);

                return this;
            }

            public PriorityDetailsScenario WithPriorityCase()
            {
                PriorityCase = CreatePriorityCase();
                return this;
            }

            public PriorityDetailsScenario WithPriorityEventOccurred(Case @case = null, Event priorityEvent = null, DateTime? priorityDate = null)
            {
                var caseWithPriorityEvent = @case ?? Case;
                var occurredDate = priorityDate ?? Fixture.PastDate();

                new CaseEventBuilder
                    {
                        CaseId = caseWithPriorityEvent.Id,
                        Cycle = 1,
                        Event = priorityEvent ?? CriticalDatesCriteria.ValidEvents.Single().Event
                    }
                    .AsEventOccurred(occurredDate)
                    .BuildForCase(caseWithPriorityEvent)
                    .In(_db);

                return this;
            }

            public PriorityDetailsScenario WithPriorityNumber(string number)
            {
                PriorityCase.OfficialNumbers.Add(
                                                 new OfficialNumberBuilder
                                                 {
                                                     Case = PriorityCase,
                                                     IsCurrent = 1,
                                                     OfficialNo = number,
                                                     NumberType = new NumberTypeBuilder
                                                     {
                                                         Code = KnownNumberTypes.Application
                                                     }.Build().In(_db)
                                                 }.Build().In(_db));

                return this;
            }
        }

        public class Resolve : FactBase
        {
            readonly string _culture = Fixture.String();

            readonly User _user = new User(Fixture.String(), false);

            readonly IExternalPatentInfoLinkResolver _externalPatentInfoLinkResolver = Substitute.For<IExternalPatentInfoLinkResolver>();

            readonly CriticalDatesMetadata _meta = new CriticalDatesMetadata
            {
                CaseId = Fixture.Integer(),
                Action = Fixture.String(),
                RenewalAction = Fixture.String(),
                ImportanceLevel = Convert.ToInt16(Fixture.Short(9)),
                CriteriaNo = Fixture.Integer()
            };

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public async Task ShouldLimitEventsToConsiderForExternalUsers(bool toEventAvailableToExternalUser, bool expectNonNullReturn)
            {
                const bool isExternal = true;

                var priorityDate = DateTime.Today;
                var priorityCaseOfficialNumber = Fixture.String();

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                scenario
                    .WithPriorityCase()
                    .WithPriorityEventOccurred(scenario.PriorityCase, priorityDate: priorityDate)
                    .WithPriorityNumber(priorityCaseOfficialNumber);

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                if (toEventAvailableToExternalUser)
                {
                    new FilteredUserEvent
                    {
                        EventNo = scenario.EarliestPriorityRelation.ToEventId.GetValueOrDefault()
                    }.In(Db);
                }

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(new User(Fixture.String(), isExternal), _culture, _meta);

                if (expectNonNullReturn)
                {
                    Assert.Equal(scenario.PriorityCase.Country.Id, _meta.EarliestPriorityCountryId);
                    Assert.Equal(scenario.PriorityCase.Country.Name, _meta.EarliestPriorityCountry);
                    Assert.Equal(priorityCaseOfficialNumber, _meta.EarliestPriorityNumber);
                    Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
                    Assert.Equal(priorityDate, _meta.EarliestPriorityDate);
                }
                else
                {
                    Assert.Null(_meta.EarliestPriorityCountryId);
                    Assert.Null(_meta.EarliestPriorityCountry);
                    Assert.Null(_meta.EarliestPriorityNumber);
                    Assert.Null(_meta.PriorityEventNo);
                    Assert.Null(_meta.EarliestPriorityDate);
                }
            }

            [Fact]
            public async Task ShouldConsiderAllRelationshipsThatSharesTheHaveTheEarliestDateFlagSetOn()
            {
                (string CountryId, string CountryName, string OfficialNumber, DateTime Date) CreatePriorityClaimRelationship(string prefix, int caseId, int? earliestEventId, DateTime date)
                {
                    var otherPriorityClaimRelation = new CaseRelation
                    {
                        Relationship = Fixture.String(prefix)
                    }.In(Db);

                    otherPriorityClaimRelation.SetFlags(true);
                    otherPriorityClaimRelation.ToEventId = earliestEventId;

                    var priorityClaimCountry = new CountryBuilder
                    {
                        Name = Fixture.String(prefix)
                    }.Build().In(Db);

                    var officialNumber = Fixture.String(prefix);
                    new RelatedCase(caseId, priorityClaimCountry.Id, officialNumber, otherPriorityClaimRelation)
                    {
                        PriorityDate = date
                    }.In(Db);

                    return (priorityClaimCountry.Id, priorityClaimCountry.Name, officialNumber, date);
                }

                var priorityDate = DateTime.Today;

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                CreatePriorityClaimRelationship("Other-1", scenario.Case.Id, scenario.EarliestPriorityRelation.ToEventId, DateTime.Today.AddDays(-1));
                CreatePriorityClaimRelationship("Other-2", scenario.Case.Id, scenario.EarliestPriorityRelation.ToEventId, DateTime.Today.AddDays(-2));
                var c = CreatePriorityClaimRelationship("Other-3", scenario.Case.Id, scenario.EarliestPriorityRelation.ToEventId, priorityDate);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Equal(c.CountryId, _meta.EarliestPriorityCountryId);
                Assert.Equal(c.CountryName, _meta.EarliestPriorityCountry);
                Assert.Equal(c.OfficialNumber, _meta.EarliestPriorityNumber);
                Assert.Equal(c.Date, _meta.EarliestPriorityDate);
                Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
            }

            [Fact]
            public async Task ShouldConsiderFromEventInTargetCase()
            {
                var priorityDate = DateTime.Today;
                var priorityCaseOfficialNumber = Fixture.String();

                var alternateEventToRecordPriority = new EventBuilder().Build().In(Db);

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured(fromEventId: alternateEventToRecordPriority.Id)
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                scenario
                    .WithPriorityCase()
                    .WithPriorityEventOccurred(scenario.PriorityCase, alternateEventToRecordPriority, priorityDate)
                    .WithPriorityNumber(priorityCaseOfficialNumber);

                var priorityCaseCountryId = scenario.PriorityCase.Country.Id;
                var priorityCaseCountry = scenario.PriorityCase.Country.Name;

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Equal(priorityCaseCountryId, _meta.EarliestPriorityCountryId);
                Assert.Equal(priorityCaseCountry, _meta.EarliestPriorityCountry);
                Assert.Equal(priorityCaseOfficialNumber, _meta.EarliestPriorityNumber);
                Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
                Assert.Equal(priorityDate, _meta.EarliestPriorityDate);
            }

            [Fact]
            public async Task ShouldResolveEarliestPriorityDisplayEvent()
            {
                var displayEventNo = Fixture.Integer();

                new PriorityDetailsScenario(Db)
                    .WithEarliestPriorityRelationConfigured(displayEventId: displayEventNo);

                await new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver).Resolve(_user, _culture, _meta);

                Assert.Equal(displayEventNo, _meta.DefaultPriorityEventNo);
            }

            [Fact]
            public async Task ShouldResolveEarliestPriorityFromEventIfDisplayEventNotFound()
            {
                var fromEventNo = Fixture.Integer();

                new PriorityDetailsScenario(Db)
                    .WithEarliestPriorityRelationConfigured(displayEventId: null, fromEventId: fromEventNo);

                await new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver).Resolve(_user, _culture, _meta);

                Assert.Equal(fromEventNo, _meta.DefaultPriorityEventNo);
            }

            [Fact]
            public async Task ShouldResolveExternalPatentInfoUri()
            {
                new PriorityDetailsScenario(Db)
                    .WithEarliestPriorityRelationConfigured();

                await new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver).Resolve(_user, _culture, _meta);

                Uri uri;
                _externalPatentInfoLinkResolver.ReceivedWithAnyArgs(1).Resolve(null, null, null, out uri);
            }

            [Fact]
            public async Task ShouldResolvePriorityDetailsFromRelatedExternalCase()
            {
                var priorityDate = DateTime.Today;

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                var country = new CountryBuilder
                {
                    Name = Fixture.String()
                }.Build().In(Db);

                var priorityCaseCountryId = country.Id;
                var priorityCaseCountry = country.Name;
                var priorityCaseOfficialNumber = Fixture.String();

                new RelatedCase(scenario.Case.Id, priorityCaseCountryId, priorityCaseOfficialNumber, scenario.EarliestPriorityRelation)
                {
                    PriorityDate = priorityDate
                }.In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Equal(priorityCaseCountryId, _meta.EarliestPriorityCountryId);
                Assert.Equal(priorityCaseCountry, _meta.EarliestPriorityCountry);
                Assert.Equal(priorityCaseOfficialNumber, _meta.EarliestPriorityNumber);
                Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
                Assert.Equal(priorityDate, _meta.EarliestPriorityDate);
            }

            [Fact]
            public async Task ShouldResolvePriorityEventFromRelatedInternalCaseAndItsApplicationNumber()
            {
                var priorityDate = DateTime.Today;
                var priorityCaseOfficialNumber = Fixture.String();

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                scenario
                    .WithPriorityCase()
                    .WithPriorityEventOccurred(scenario.PriorityCase, priorityDate: priorityDate)
                    .WithPriorityNumber(priorityCaseOfficialNumber);

                var priorityCaseCountryId = scenario.PriorityCase.Country.Id;
                var priorityCaseCountry = scenario.PriorityCase.Country.Name;

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Equal(priorityCaseCountryId, _meta.EarliestPriorityCountryId);
                Assert.Equal(priorityCaseCountry, _meta.EarliestPriorityCountry);
                Assert.Equal(priorityCaseOfficialNumber, _meta.EarliestPriorityNumber);
                Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
                Assert.Equal(priorityDate, _meta.EarliestPriorityDate);
            }

            [Fact]
            public async Task ShouldResolvePriorityEventFromRelatedInternalCaseAndItsCurrentOfficialNumber()
            {
                var priorityDate = DateTime.Today;

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate)
                               .WithPriorityCase();

                scenario.WithPriorityEventOccurred(scenario.PriorityCase, priorityDate: priorityDate);

                var priorityCaseCountryId = scenario.PriorityCase.Country.Id;
                var priorityCaseCountry = scenario.PriorityCase.Country.Name;
                var priorityCaseOfficialNumber = scenario.PriorityCase.CurrentOfficialNumber = Fixture.String();

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Equal(priorityCaseCountryId, _meta.EarliestPriorityCountryId);
                Assert.Equal(priorityCaseCountry, _meta.EarliestPriorityCountry);
                Assert.Equal(priorityCaseOfficialNumber, _meta.EarliestPriorityNumber);
                Assert.Equal(scenario.EarliestPriorityRelation.ToEventId, _meta.PriorityEventNo);
                Assert.Equal(priorityDate, _meta.EarliestPriorityDate);
            }

            [Fact]
            public async Task ShouldReturnEmptyIfPriorityDateNotMatchingTargetCaseDate()
            {
                var priorityDate = DateTime.Today;
                var targetCasePriorityDate = Fixture.PastDate();
                var priorityCaseOfficialNumber = Fixture.String();

                var scenario = new PriorityDetailsScenario(Db)
                               .WithEarliestPriorityRelationConfigured()
                               .WithPriorityEventOccurred(priorityDate: priorityDate);

                scenario
                    .WithPriorityCase()
                    .WithPriorityEventOccurred(scenario.PriorityCase, priorityDate: targetCasePriorityDate)
                    .WithPriorityNumber(priorityCaseOfficialNumber);

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Null(_meta.EarliestPriorityCountryId);
                Assert.Null(_meta.EarliestPriorityCountry);
                Assert.Null(_meta.EarliestPriorityNumber);
                Assert.Null(_meta.PriorityEventNo);
                Assert.Null(_meta.EarliestPriorityDate);
            }

            [Fact]
            public async Task ShouldReturnEmptyIfPriorityEventNotExistInCase()
            {
                var priorityDate = DateTime.Today;
                var priorityCaseOfficialNumber = Fixture.String();

                var scenario = new PriorityDetailsScenario(Db)
                    .WithEarliestPriorityRelationConfigured();

                scenario
                    .WithPriorityCase()
                    .WithPriorityEventOccurred(scenario.PriorityCase, priorityDate: priorityDate)
                    .WithPriorityNumber(priorityCaseOfficialNumber);

                new RelatedCase(scenario.Case.Id, null, null, scenario.EarliestPriorityRelation, scenario.PriorityCase.Id).In(Db);

                _meta.CaseId = scenario.Case.Id;
                _meta.CriteriaNo = scenario.CriticalDatesCriteria.Id;

                var subject = new CriticalDatesPriorityInfoResolver(Db, _externalPatentInfoLinkResolver);

                await subject.Resolve(_user, _culture, _meta);

                Assert.Null(_meta.EarliestPriorityCountryId);
                Assert.Null(_meta.EarliestPriorityCountry);
                Assert.Null(_meta.EarliestPriorityNumber);
                Assert.Null(_meta.PriorityEventNo);
                Assert.Null(_meta.EarliestPriorityDate);
            }
        }
    }
}