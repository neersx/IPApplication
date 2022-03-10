using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Rules;
using NSubstitute;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventsModelBuilderFacts
{
    public class Fixture : IFixture<BatchEventsModelBuilder>
    {
        readonly InMemoryDbContext _db;

        public Fixture(InMemoryDbContext db)
        {
            _db = db;
            ExistingCase = new CaseBuilder().Build().In(db);
            SetupAnOpenAction(ExistingCase);

            ExistingCases = new List<Case>(new[] {ExistingCase});

            BatchDataEntryTaskPrerequisiteCheck = Substitute.For<IBatchDataEntryTaskPrerequisiteCheck>();

            BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                                               .ReturnsForAnyArgs(new BatchDataEntryTaskPrerequisiteCheckResult());

            UpdatableCaseModelBuilder = Substitute.For<IUpdatableCaseModelBuilder>();

            UpdatableCaseModelBuilder.BuildForDynamicCycle(null, null, null, Arg.Any<bool>())
                                     .ReturnsForAnyArgs(c => new UpdatableCaseModel((Case) c.Args()[0]));
        }

        public IBatchDataEntryTaskPrerequisiteCheck BatchDataEntryTaskPrerequisiteCheck { get; }
        public Case ExistingCase { get; set; }
        public List<Case> ExistingCases { get; set; }
        public BatchEventsModel Result { get; set; }
        public OpenAction ExistingOpenAction { get; set; }
        DataEntryTask SelectedDataEntryTask { get; set; }
        IUpdatableCaseModelBuilder UpdatableCaseModelBuilder { get; }
        bool UseNextCycle { get; set; }

        public BatchEventsModelBuilder Subject => new BatchEventsModelBuilder(_db,
                                                                              BatchDataEntryTaskPrerequisiteCheck,
                                                                              UpdatableCaseModelBuilder);

        public async Task Run()
        {
            Result = await Subject.Build(ExistingCases.ToArray(), SelectedDataEntryTask, UseNextCycle);
        }

        void SetupAnOpenAction(Case @case)
        {
            ExistingOpenAction = OpenActionBuilder.ForCaseAsValid(_db, @case).Build().In(_db);
            SelectedDataEntryTask = DataEntryTaskBuilder.ForCriteria(ExistingOpenAction.Criteria).Build().In(_db);
            SelectedDataEntryTask.AvailableEvents.Add(new AvailableEventBuilder().Build().In(_db));

            ExistingOpenAction.Criteria.DataEntryTasks.Add(SelectedDataEntryTask);
            @case.OpenActions.Add(ExistingOpenAction);
        }
    }
}