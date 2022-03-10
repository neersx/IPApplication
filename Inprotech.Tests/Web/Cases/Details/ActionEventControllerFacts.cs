using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ActionEventControllerFacts : FactBase
    {
        public ActionEventControllerFacts()
        {
            _q = new ActionEventQuery();
        }

        readonly ActionEventQuery _q;

        [Theory]
        [InlineData(null)]
        [InlineData(3)]
        [InlineData(6)]
        public async Task ValidatesImportanceLevelForExternalUser(int? defaultImportanceLevel)
        {
            var f = new ActionsEventControllerFixture(Db)
                    .WithCase(out var @case)
                    .WithValidImportanceLevel(defaultImportanceLevel);

            var result = await f.Subject.GetCaseActionEvents(@case.Id, Fixture.String(), new ActionEventQuery
            {
                ImportanceLevel = defaultImportanceLevel
            });

            f.ImportanceLevel.Received(1).GetValidImportanceLevel(defaultImportanceLevel);
            f.Events.Received(1).Events(@case, Arg.Any<string>(), Arg.Is<ActionEventQuery>(_ => _.ImportanceLevel == defaultImportanceLevel));
            Assert.NotNull(result);
        }

        class ActionsEventControllerFixture : IFixture<ActionEventController>
        {
            public ActionsEventControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                ImportanceLevel = Substitute.For<IImportanceLevelResolver>();
                Events = Substitute.For<IActionEvents>();
                EventNotesResolver = Substitute.For<IEventNotesResolver>();

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new ActionEventController(Db, Events, ImportanceLevel, EventNotesResolver, TaskSecurityProvider);
            }

            InMemoryDbContext Db { get; }

            public IImportanceLevelResolver ImportanceLevel { get; }

            public IActionEvents Events { get; }

            public IEventNotesResolver EventNotesResolver { get; }

            public ITaskSecurityProvider TaskSecurityProvider { get; }

            public ActionEventController Subject { get; }

            public ActionsEventControllerFixture WithCase(out Case @case)
            {
                @case = new CaseBuilder().Build().In(Db);
                return this;
            }

            public ActionsEventControllerFixture WithEventData(Case @case)
            {
                var data = Enumerable.Range(0, 5).Select(_ => new ActionEventData
                {
                    EventDescription = $"Event {_}",
                    EventNo = _,
                    Cycle = _,
                    ImportanceLevel = _.ToString()
                }).ToList().AsQueryable();
                Events.Events(@case, Arg.Any<string>(), Arg.Any<ActionEventQuery>()).Returns(data);
                return this;
            }
            
            public ActionsEventControllerFixture WithValidImportanceLevel(int? defaultImportanceLevel)
            {
                ImportanceLevel.GetValidImportanceLevel(Arg.Any<int?>()).Returns(defaultImportanceLevel);
                return this;
            }
        }

        [Theory]
        [InlineData(true, true, true)]
        [InlineData(true, false, false)]
        [InlineData(false, false, false)]
        [InlineData(false, true, false)]
        public async Task ReturnCanLinkToWorkflowWizardOnlyIfPermissionsAvailable(bool dataCanLink, bool permissionCanLink, bool expertedLinkability)
        {
            var action = Fixture.String();
            var q = new ActionEventQuery();

            var f = new ActionsEventControllerFixture(Db).WithCase(out var @case);

            f.Events.Events(@case, action, q)
             .Returns(new[]
             {
                 new ActionEventData
                 {
                     CanLinkToWorkflow = dataCanLink
                 }
             }.AsQueryable());

            f.Events.ClearValueByCaseAndNameAccess(Arg.Any<IEnumerable<ActionEventData>>())
             .Returns(x => (IEnumerable<ActionEventData>)x[0]);

            f.TaskSecurityProvider
             .HasAccessTo(ApplicationTask.LaunchWorkflowWizard)
             .Returns(permissionCanLink);

            var result = await f.Subject.GetCaseActionEvents(@case.Id, action, q);

            var r = (ActionEventData)result.Data.Single();

            Assert.Equal(expertedLinkability, r.CanLinkToWorkflow);
        }

        [Fact]
        public async Task GetsNotesOfActions()
        {
            var f = new ActionsEventControllerFixture(Db).WithCase(out var @case).WithEventData(@case);
            var result = await f.Subject.GetCaseActionEvents(@case.Id, Fixture.String(), new ActionEventQuery(), new CommonQueryParameters());

            f.EventNotesResolver.Received(1).Resolve(@case.Id, Arg.Any<IEnumerable<int>>());
            Assert.NotNull(result);
        }

        [Fact]
        public async Task ReturnsPagedResult()
        {
            var f = new ActionsEventControllerFixture(Db).WithCase(out var @case);
            var result = await f.Subject.GetCaseActionEvents(@case.Id, Fixture.String(), new ActionEventQuery());
            f.ImportanceLevel.Received(1).GetValidImportanceLevel(null);
            f.Events.Received(1).Events(@case, Arg.Any<string>(), Arg.Is<ActionEventQuery>(_ => !_.ImportanceLevel.HasValue));
            Assert.NotNull(result);
        }

        [Fact]
        public async Task ThrowsIfCaseNotFound()
        {
            var f = new ActionsEventControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCaseActionEvents(Fixture.Integer(), Fixture.String(), _q));

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ThrowsIfNoAccessToCase()
        {
            var f = new ActionsEventControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCaseActionEvents(Fixture.Integer(), Fixture.String()));

            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }
    }
}