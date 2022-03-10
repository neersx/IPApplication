using System;
using System.Globalization;
using System.Net.Http;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.TempStorage;
using NSubstitute;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts
{
    public class BatchEventUpdateControllerFixture : IFixture<BatchEventUpdateController>
    {
        const string Path = "http://localhost/batcheventupdate";
        const string PathInAngular = "http://localhost/api/batcheventupdate";
        protected InMemoryDbContext Db;

        public BatchEventUpdateControllerFixture(InMemoryDbContext db)
        {
            Db = db;
            ExistingCase = new CaseBuilder().Build().In(db);
            SetupAnOpenAction(ExistingCase);

            var tempId = new TempStorage(ExistingCase.Id.ToString(CultureInfo.InvariantCulture));
            tempId.In(db);
            TempStorageId = tempId.Id;

            PolicingEngine = Substitute.For<IPolicingEngine>();
            SingleCaseUpdate = Substitute.For<ISingleCaseUpdate>();

            LifetimeScope = Substitute.For<ILifetimeScope>();
            LifetimeScope.BeginLifetimeScope().Returns(LifetimeScope);

            LifetimeScope.Resolve<ISingleCaseUpdate>().Returns(SingleCaseUpdate);

            SecurityContext = Substitute.For<ISecurityContext>();
            var user = UserBuilder.AsInternalUser(db).Build();
            user.Roles.Add(new Role(Fixture.Integer()));
            user.Roles.Add(new Role(Fixture.Integer()));

            SecurityContext.User.Returns(user);

            BatchEventsModelBuilder = Substitute.For<IBatchEventsModelBuilder>();

            BatchEventsModelBuilder.Build(null, null, Arg.Any<bool>())
                                   .ReturnsForAnyArgs(
                                                      new BatchEventsModel(
                                                                           new UpdatableCaseModel[0],
                                                                           new NonUpdatableCaseModel[0],
                                                                           true,
                                                                           true));

            CaseAuthorization = Substitute.For<ICaseAuthorization>();
            CaseAuthorization.Authorize(ExistingCase.Id, AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, false, null);
            });

            CycleSelection = Substitute.For<ICycleSelection>();
        }

        public Case ExistingCase { get; set; }
        public OpenAction ExistingOpenAction { get; private set; }
        public DataEntryTask SelectedDataEntryTask { get; set; }

        public IPolicingEngine PolicingEngine { get; }
        public ISingleCaseUpdate SingleCaseUpdate { get; }
        protected ILifetimeScope LifetimeScope { get; }
        public ISecurityContext SecurityContext { get; }
        public ICaseAuthorization CaseAuthorization { get; }
        protected IBatchEventsModelBuilder BatchEventsModelBuilder { get; set; }
        public ICycleSelection CycleSelection { get; set; }

        public long TempStorageId { get; set; }

        public Exception Exception { get; set; }

        public BatchEventUpdateController Subject => new BatchEventUpdateController(
                                                                                    Db,
                                                                                    SecurityContext,
                                                                                    PolicingEngine,
                                                                                    LifetimeScope,
                                                                                    BatchEventsModelBuilder,
                                                                                    CaseAuthorization,
                                                                                    CycleSelection) {Request = new HttpRequestMessage {RequestUri = new Uri(Path)}};
        public BatchEventUpdateController SubjectInAngular => new BatchEventUpdateController(
                                                                                    Db,
                                                                                    SecurityContext,
                                                                                    PolicingEngine,
                                                                                    LifetimeScope,
                                                                                    BatchEventsModelBuilder,
                                                                                    CaseAuthorization,
                                                                                    CycleSelection) {Request = new HttpRequestMessage {RequestUri = new Uri(PathInAngular)}};

        public void SetupAnOpenAction(Case @case)
        {
            ExistingOpenAction = OpenActionBuilder.ForCaseAsValid(Db, @case).Build().In(Db);
            ExistingOpenAction.Cycle = 1;
            SelectedDataEntryTask = DataEntryTaskBuilder.ForCriteria(ExistingOpenAction.Criteria).Build().In(Db);
            SelectedDataEntryTask.AvailableEvents.Add(new AvailableEventBuilder().Build().In(Db));

            var secondDataEntryTask = DataEntryTaskBuilder.ForCriteria(ExistingOpenAction.Criteria).Build().In(Db);
            secondDataEntryTask.AvailableEvents.Add(new AvailableEventBuilder().Build().In(Db));
            ExistingOpenAction.Criteria.DataEntryTasks.Add(secondDataEntryTask);

            var thirdDataEntryTask = DataEntryTaskBuilder.ForCriteria(ExistingOpenAction.Criteria).Build().In(Db);
            thirdDataEntryTask.AvailableEvents.Add(new AvailableEventBuilder().Build().In(Db));
            ExistingOpenAction.Criteria.DataEntryTasks.Add(thirdDataEntryTask);

            ExistingOpenAction.Criteria.DataEntryTasks.Add(SelectedDataEntryTask);
            @case.OpenActions.Add(ExistingOpenAction);
        }
    }
}