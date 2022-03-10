using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
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

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ActionsControllerFacts : FactBase
    {
        readonly int defaultImportanceLevel = 5;
        readonly int importanceLevelCount = 6;

        class ActionsControllerFixture : IFixture<ActionsController>
        {
            public readonly ISiteControlReader SiteControlReader;

            public ActionsControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                Actions = Substitute.For<IActions>();
                ImportanceLevel = Substitute.For<IImportanceLevelResolver>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                SecurityContext = Substitute.For<ISecurityContext>();
                caseAuthorization = Substitute.For<ICaseAuthorization>();
                caseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Update).Returns(Task.Run(() => new AuthorizationResult(1, true, false, string.Empty)));
                WithUser();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new ActionsController(Db, Actions, ImportanceLevel, TaskSecurityProvider, SiteControlReader, caseAuthorization);
            }

            ITaskSecurityProvider TaskSecurityProvider { get; }

            InMemoryDbContext Db { get; }

            public IImportanceLevelResolver ImportanceLevel { get; }

            public IActions Actions { get; }

            ISecurityContext SecurityContext { get; }
            ICaseAuthorization caseAuthorization { get; }

            public ActionsController Subject { get; }

            public ActionsControllerFixture WithTasks(params ApplicationTask[] tasks)
            {
                foreach (var t in tasks) TaskSecurityProvider.HasAccessTo(t).Returns(true);

                return this;
            }

            public ActionsControllerFixture WithTasksFullPermissions(params ApplicationTask[] tasks)
            {
                foreach (var t in tasks) TaskSecurityProvider.HasAccessTo(t,Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);

                return this;
            }

            public ActionsControllerFixture WithCase(out Case @case)
            {
                @case = new CaseBuilder().Build().In(Db);
                return this;
            }

            public ActionsControllerFixture WithActionData(Case @case)
            {
                var data = Enumerable.Range(1, 6).Select(_ => new ActionData
                {
                    Name = Fixture.String(_.ToString()),
                    ImportanceLevel = _.ToString(),
                    IsOpen = _ == 2 || _ == 4 || _ == 6,
                    IsClosed = _ == 1 || _ == 3,
                    IsPotential = _ == 5
                }).ToList();
                Actions.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId).Returns(data.AsQueryable());
                return this;
            }

            public ActionsControllerFixture WithDefaultImportanceLevel(int defaultImportanceLevel)
            {
                ImportanceLevel.Resolve().Returns(defaultImportanceLevel);
                return this;
            }

            public ActionsControllerFixture WithRecalculateImportanceLevel(int defaultImportanceLevel)
            {
                ImportanceLevel.GetValidImportanceLevel(Arg.Any<int?>()).Returns(defaultImportanceLevel);
                return this;
            }

            public ActionsControllerFixture WithImportanceLevelOptions(int totalImportanceLevels)
            {
                var importance = new List<Importance>();
                Enumerable.Range(0, totalImportanceLevels).ToList().ForEach(i => { importance.Add(new Importance(i.ToString(), $"Importance Level {i}")); });
                ImportanceLevel.GetImportanceLevels().Returns(importance.AsEnumerable());
                return this;
            }

            public ActionsControllerFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User("user", isExternal));
                return this;
            }
        }

        [Fact]
        public async Task ChecksWorkflowPermissions()
        {
            int caseKey = 1001;
            var f = new ActionsControllerFixture(Db).WithTasks(ApplicationTask.MaintainWorkflowRules);
            Assert.True((await f.Subject.View(caseKey)).CanMaintainWorkflow);

            f = new ActionsControllerFixture(Db).WithTasks(ApplicationTask.MaintainWorkflowRulesProtected);
            Assert.True((await f.Subject.View(caseKey)).CanMaintainWorkflow);

            f = new ActionsControllerFixture(Db);
            Assert.False((await f.Subject.View(caseKey)).CanMaintainWorkflow);
        }

        [Fact]
        public async Task ChecksCanPolicingPermissions()
        {
            int caseKey = 1001;
            var f = new ActionsControllerFixture(Db).WithTasksFullPermissions(ApplicationTask.MaintainCase);
            Assert.False((await f.Subject.View(caseKey)).CanPoliceActions);

            f = new ActionsControllerFixture(Db).WithTasksFullPermissions(ApplicationTask.MaintainCase, ApplicationTask.PoliceActionsOnCase);
            Assert.True((await f.Subject.View(caseKey)).CanPoliceActions);
        }

        [Fact]
        public void DoesNotReturnPagedResultsIfActionTypeNotProvided()
        {
            var inputImportanceLevel = 2;
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(defaultImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { ImportanceLevel = inputImportanceLevel }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.False(result.Data.Any());
            Assert.True(result.Pagination.Total == 0);
        }

        [Fact]
        public void FilterReturnsByImportanceLevel()
        {
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(defaultImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { IncludeOpenActions = true, IncludeClosedActions = true }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.ImportanceLevelNumber < defaultImportanceLevel);
            Assert.True(result.Data.Count() == 1);
            Assert.True(result.Pagination.Total == 1);
        }

        [Fact]
        public void ReturnsPagedResult()
        {
            var f = new ActionsControllerFixture(Db).WithCase(out var @case);
            var result = f.Subject.GetCaseActions(@case.Id);
            f.ImportanceLevel.Received(1).GetValidImportanceLevel(null);
            f.Actions.Received(1).CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);
            Assert.NotNull(result);
        }

        [Fact]
        public void ReturnsResultsForOpenClosePotentialActions()
        {
            var inputImportanceLevel = 0;
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(inputImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { ImportanceLevel = inputImportanceLevel, IncludeClosedActions = true, IncludeOpenActions = true, IncludePotentialActions = true }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.ImportanceLevelNumber < inputImportanceLevel);
            Assert.Contains(result.Data, _ => (_ as ActionData)?.IsOpen == true);
            Assert.Contains(result.Data, _ => (_ as ActionData)?.IsClosed == true);
            Assert.Contains(result.Data, _ => (_ as ActionData)?.IsPotential == true);
            Assert.True(result.Data.Count() == 6);
            Assert.True(result.Pagination.Total == 6);
        }

        [Fact]
        public void ReturnsResultsForPotentialActions()
        {
            var inputImportanceLevel = 0;
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(defaultImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { ImportanceLevel = inputImportanceLevel, IncludeClosedActions = false, IncludeOpenActions = false, IncludePotentialActions = true }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.ImportanceLevelNumber < inputImportanceLevel);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.IsPotential == false);
            Assert.True(result.Data.Count() == 1);
        }

        [Fact]
        public void ReturnsResultsOnlyForClosedActions()
        {
            var inputImportanceLevel = 0;
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(inputImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { ImportanceLevel = inputImportanceLevel, IncludeClosedActions = true }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.ImportanceLevelNumber < inputImportanceLevel);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.IsOpen == true);
            Assert.True(result.Data.Count() == 2);
            Assert.True(result.Pagination.Total == 2);
        }

        [Fact]
        public void ReturnsResultsOnlyForOpenActions()
        {
            var inputImportanceLevel = 0;
            var f = new ActionsControllerFixture(Db).WithRecalculateImportanceLevel(inputImportanceLevel)
                                                    .WithCase(out var @case)
                                                    .WithActionData(@case);
            var result = f.Subject.GetCaseActions(@case.Id, new ActionEventQuery { ImportanceLevel = inputImportanceLevel, IncludeOpenActions = true }, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.ImportanceLevelNumber < inputImportanceLevel);
            Assert.DoesNotContain(result.Data, _ => (_ as ActionData)?.IsOpen != true);
            Assert.True(result.Data.Count() == 3);
            Assert.True(result.Pagination.Total == 3);
        }

        [Fact]
        public void ThrowsIfCaseNotFound()
        {
            var f = new ActionsControllerFixture(Db);
            var exception = Assert.Throws<HttpResponseException>(() => f.Subject.GetCaseActions(Fixture.Integer()));

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public void ThrowsIfNoAccesstoCase()
        {
            var f = new ActionsControllerFixture(Db).WithCase(out _);
            var exception = Assert.Throws<HttpResponseException>(() => f.Subject.GetCaseActions(Fixture.Integer()));

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ViewFiltersDataForExternalUser()
        {
            var f = new ActionsControllerFixture(Db).WithUser(true)
                                                    .WithDefaultImportanceLevel(defaultImportanceLevel)
                                                    .WithImportanceLevelOptions(importanceLevelCount);

            var r = await f.Subject.View(1001);

            Assert.False(r.CanMaintainWorkflow);
        }

        [Fact]
        public async Task ViewReturnsDataForInternalUser()
        {
            var f = new ActionsControllerFixture(Db);

            var r = await f.Subject.View(1001);

            Assert.False(r.CanMaintainWorkflow);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ViewReturnsDataForCanAddAttachment(bool hasPermission)
        {
            var f = hasPermission ? new ActionsControllerFixture(Db).WithTasksFullPermissions(new[] {ApplicationTask.MaintainCaseAttachments}) : new ActionsControllerFixture(Db);

            var r = await f.Subject.View(1001);

            Assert.Equal(hasPermission, r.CanAddAttachment);
        }
    }
}