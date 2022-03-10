using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CaseviewEvents
{
    public class CaseViewEventsControllerFacts
    {
        public class Occurred : FactBase
        {
            [Theory]
            [InlineData(4, 4)]
            [InlineData(5, 0)]
            [InlineData(3, 4)]
            public async Task GetCaseOccurredEventsAreFilteredByImportanceLevel(int minimumImportanceLevel, int expectedCount)
            {
                var eventsImportanceLevel = "4";
                var f = new CaseViewEventsControllerFixture(Db).WithUser()
                                                               .WithCase(out var @case)
                                                               .WithImportanceLevel(minimumImportanceLevel)
                                                               .WithCaseViewOccurredEvents(@case.Id, eventsImportanceLevel);
                var r = await f.Subject.GetCaseOccurredEvents(@case.Id, new CommonQueryParameters());

                Assert.Equal(expectedCount, r.Data.Count());
            }

            [Fact]
            public async Task ThrowsIfNoAccesstoCase()
            {
                var f = new CaseViewEventsControllerFixture(Db).WithCase(out _);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCaseOccurredEvents(Fixture.Integer(), new CommonQueryParameters()));

                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class Due : FactBase
        {
            [Theory]
            [InlineData(4, 4)]
            [InlineData(5, 0)]
            [InlineData(3, 4)]
            public async Task GetCaseDueEventsAreFilteredByImportanceLevel(int minimumImportanceLevel, int expectedCount)
            {
                var eventsImportanceLevel = "4";
                var f = new CaseViewEventsControllerFixture(Db).WithUser()
                                                               .WithCase(out var @case)
                                                               .WithImportanceLevel(minimumImportanceLevel)
                                                               .WithCaseViewDueEvents(@case.Id, eventsImportanceLevel);
                var r = await f.Subject.GetCaseDueEvents(@case.Id, new CommonQueryParameters());

                Assert.Equal(expectedCount, r.Data.Count());
            }

            [Fact]
            public async Task ThrowsIfNoAccessToCase()
            {
                var f = new CaseViewEventsControllerFixture(Db).WithCase(out _);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCaseDueEvents(Fixture.Integer(), new CommonQueryParameters()));

                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        class CaseViewEventsControllerFixture : IFixture<CaseViewEventsController>
        {
            public CaseViewEventsControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                CaseViewEvents = Substitute.For<ICaseViewEvents>();
                ImportanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
                SecurityContext = Substitute.For<ISecurityContext>();
                var eventNotesResolver = Substitute.For<IEventNotesResolver>();
                Subject = new CaseViewEventsController(Db, CaseViewEvents, ImportanceLevelResolver, eventNotesResolver);
            }

            InMemoryDbContext Db { get; }
            ICaseViewEvents CaseViewEvents { get; }
            ISecurityContext SecurityContext { get; }
            IImportanceLevelResolver ImportanceLevelResolver { get; }

            public CaseViewEventsController Subject { get; }

            public CaseViewEventsControllerFixture WithCase(out Case @case)
            {
                @case = new CaseBuilder().Build().In(Db);
                return this;
            }

            public CaseViewEventsControllerFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User(Fixture.String(), isExternal));
                return this;
            }

            public CaseViewEventsControllerFixture WithImportanceLevel(int importanceLevel)
            {
                ImportanceLevelResolver.GetValidImportanceLevel(Arg.Any<int?>()).Returns(importanceLevel);
                return this;
            }

            public CaseViewEventsControllerFixture WithCaseViewOccurredEvents(int caseId, string importanceLevel = "4", string clientImportanceLevel = "1")
            {
                CaseViewEvents.Occurred(Arg.Any<int>()).Returns(GetCaseViewEventsData(caseId, importanceLevel, clientImportanceLevel).AsQueryable());
                return this;
            }

            public CaseViewEventsControllerFixture WithCaseViewDueEvents(int caseId, string importanceLevel = "4", string clientImportanceLevel = "1")
            {
                CaseViewEvents.Due(Arg.Any<int>()).Returns(GetCaseViewEventsData(caseId, importanceLevel, clientImportanceLevel).AsQueryable());
                return this;
            }

            List<CaseViewEventsData> GetCaseViewEventsData(int caseId, string importanceLevel, string clientImportanceLevel)
            {
                return new List<CaseViewEventsData>
                {
                    new CaseViewEventsData {CaseKey = caseId, EventDescription = Fixture.String(), ImportanceLevel = importanceLevel},
                    new CaseViewEventsData {CaseKey = caseId, EventDescription = Fixture.String(), ImportanceLevel = importanceLevel},
                    new CaseViewEventsData {CaseKey = caseId, EventDescription = Fixture.String(), ImportanceLevel = importanceLevel},
                    new CaseViewEventsData {CaseKey = caseId, EventDescription = Fixture.String(), ImportanceLevel = importanceLevel}
                };
            }
        }
    }
}