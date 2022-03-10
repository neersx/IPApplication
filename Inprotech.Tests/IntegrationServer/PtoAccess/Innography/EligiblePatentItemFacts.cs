using System.Collections.Generic;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class EligiblePatentItemFacts
    {
        public class EligiblePatentItemsFixture : IFixture<EligiblePatentItems>
        {
            readonly IMappedParentRelatedCasesResolver _mappedParentRelatedCasesResolver = Substitute.For<IMappedParentRelatedCasesResolver>();

            public EligiblePatentItemsFixture(InMemoryDbContext db)
            {
                TypeCodeResolver = Substitute.For<ITypeCodeResolver>();
                EventMappingsResolver = Substitute.For<IEventMappingsResolver>();

                Subject = new EligiblePatentItems(db, TypeCodeResolver, _mappedParentRelatedCasesResolver, EventMappingsResolver);
            }

            public ITypeCodeResolver TypeCodeResolver { get; }

            public IEventMappingsResolver EventMappingsResolver { get; }

            public EligiblePatentItems Subject { get; }
        }

        public class ResolveMethod : FactBase
        {
            [Fact]
            public void MapsTypeCodeToCase()
            {
                var fixture = new EligiblePatentItemsFixture(Db);
                var caseId = Fixture.Integer();
                var caseId2 = Fixture.Integer();
                var caseId3 = Fixture.Integer();

                fixture.TypeCodeResolver.GetTypeCodes().Returns(new List<InnographyTypeCode>
                {
                    new InnographyTypeCode {CaseId = caseId, TypeCode = "EPPAT1"},
                    new InnographyTypeCode {CaseId = caseId3, TypeCode = "EPPAT3"}
                }.AsQueryable());

                fixture.EventMappingsResolver.Resolve(Arg.Any<string[]>(), Arg.Any<string>())
                       .Returns(new Dictionary<string, IQueryable<CaseEvent>>
                       {
                           { Events.Application,  new List<CaseEvent>().AsQueryable() },
                           { Events.Publication,  new List<CaseEvent>().AsQueryable() },
                           { Events.RegistrationOrGrant,  new List<CaseEvent>().AsQueryable() },
                           { Events.GrantPublication,  new List<CaseEvent>().AsQueryable() }
                       });

                new EligibleCaseItem
                {
                    CaseKey = caseId,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                new EligibleCaseItem
                {
                    CaseKey = caseId2,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                new EligibleCaseItem
                {
                    CaseKey = caseId3,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                var eligibleInnographyItems = fixture.Subject.Retrieve(caseId, caseId2, caseId3).ToList();

                Assert.Equal(3, eligibleInnographyItems.Count());
                Assert.Null(eligibleInnographyItems[1].TypeCode);
                Assert.Equal("EPPAT1", eligibleInnographyItems.First().TypeCode);
                Assert.Equal("EPPAT3", eligibleInnographyItems.Last().TypeCode);
            }

            [Fact]
            public void ReturnCasesRequested()
            {
                var a = new EligibleCaseItem
                {
                    CaseKey = 1,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                var b = new EligibleCaseItem
                {
                    CaseKey = 2,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                var c = new EligibleCaseItem
                {
                    CaseKey = 3,
                    PropertyType = KnownPropertyTypes.Patent
                }.In(Db);

                new CpaGlobalIdentifier
                {
                    Id = Fixture.Integer(),
                    CaseId = 3,
                    InnographyId = "20"
                }.In(Db);

                var fixture = new EligiblePatentItemsFixture(Db);
                fixture.EventMappingsResolver.Resolve(Arg.Any<string[]>(), Arg.Any<string>())
                       .Returns(new Dictionary<string, IQueryable<CaseEvent>>
                       {
                           { Events.Application,  new List<CaseEvent>().AsQueryable() },
                           { Events.Publication,  new List<CaseEvent>().AsQueryable() },
                           { Events.RegistrationOrGrant,  new List<CaseEvent>().AsQueryable() },
                           { Events.GrantPublication,  new List<CaseEvent>().AsQueryable() }
                       });

                var subject = fixture.Subject;

                var r = subject.Retrieve(1, 3).ToList();

                Assert.NotEmpty(r);

                Assert.Equal(a.CaseKey, r.First().CaseKey);

                Assert.Equal(c.CaseKey, r.Last().CaseKey);

                Assert.Empty(r.Where(_ => _.CaseKey == b.CaseKey));
            }

            [Fact]
            public void ReturnsMappedApplicationFilingDateCycle1()
            {
                var caseId = Fixture.Integer();
                var mappedEventId = Fixture.Integer();
                new SourceMappedEvents("Application", mappedEventId).In(Db);

                var relevantEvent = new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 1,
                    EventDate = Fixture.PastDate()
                }.Build().In(Db);
                new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 2,
                    EventDate = Fixture.Today()
                }.Build().In(Db);

                new EligibleCaseItem
                {
                    CaseKey = caseId
                }.In(Db);

                var fixture = new EligiblePatentItemsFixture(Db);
                fixture.EventMappingsResolver.Resolve(Arg.Any<string[]>(), Arg.Any<string>())
                       .Returns(new Dictionary<string, IQueryable<CaseEvent>>
                       {
                           { 
                               Events.Application,  new List<CaseEvent>
                               {
                                   relevantEvent   
                               }.AsQueryable()
                           },
                           {
                               Events.Publication,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.RegistrationOrGrant,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.GrantPublication,  new List<CaseEvent>().AsQueryable()
                           }
                       });

                var subject = fixture.Subject;

                var r = subject.Retrieve(caseId).Single();

                Assert.Equal(Fixture.PastDate(), r.ApplicationDate);
                Assert.Null(r.RegistrationDate);
                Assert.Null(r.PublicationDate);
            }

            [Fact]
            public void ReturnsMappedPublicationDateCycle1()
            {
                var caseId = Fixture.Integer();
                var mappedEventId = Fixture.Integer();
                new SourceMappedEvents("Publication", mappedEventId).In(Db);

                var relevantEvent = new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 1,
                    EventDate = Fixture.PastDate()
                }.Build().In(Db);

                new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 2,
                    EventDate = Fixture.Today()
                }.Build().In(Db);

                new EligibleCaseItem
                {
                    CaseKey = caseId
                }.In(Db);

                var fixture = new EligiblePatentItemsFixture(Db);
                fixture.EventMappingsResolver.Resolve(Arg.Any<string[]>(), Arg.Any<string>())
                       .Returns(new Dictionary<string, IQueryable<CaseEvent>>
                       {
                           { 
                               Events.Publication,  new List<CaseEvent>
                               {
                                   relevantEvent
                               }.AsQueryable()
                           },
                           {
                               Events.Application,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.RegistrationOrGrant,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.GrantPublication,  new List<CaseEvent>().AsQueryable()
                           }
                       });

                var subject = fixture.Subject;

                var r = subject.Retrieve(caseId).Single();

                Assert.Equal(Fixture.PastDate(), r.PublicationDate);
                Assert.Null(r.RegistrationDate);
                Assert.Null(r.ApplicationDate);
            }

            [Fact]
            public void ReturnsMappedRegistrationOrGrantDateCycle1()
            {
                var caseId = Fixture.Integer();
                var mappedEventId = Fixture.Integer();
                new SourceMappedEvents("Registration/Grant", mappedEventId).In(Db);

                var relevantEvent = new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 1,
                    EventDate = Fixture.PastDate()
                }.Build().In(Db);

                new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = 2,
                    EventDate = Fixture.Today()
                }.Build().In(Db);

                new EligibleCaseItem
                {
                    CaseKey = caseId
                }.In(Db);

                var fixture = new EligiblePatentItemsFixture(Db);
                fixture.EventMappingsResolver.Resolve(Arg.Any<string[]>(), Arg.Any<string>())
                       .Returns(new Dictionary<string, IQueryable<CaseEvent>>
                       {
                           { 
                               Events.RegistrationOrGrant,  new List<CaseEvent>
                               {
                                   relevantEvent
                               }.AsQueryable()
                           },
                           {
                               Events.Publication,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.Application,  new List<CaseEvent>().AsQueryable()
                           },
                           {
                               Events.GrantPublication,  new List<CaseEvent>().AsQueryable()
                           }
                       });

                var subject = fixture.Subject;

                var r = subject.Retrieve(caseId).Single();

                Assert.Equal(Fixture.PastDate(), r.RegistrationDate);
                Assert.Null(r.ApplicationDate);
                Assert.Null(r.PublicationDate);
            }
        }
    }
}