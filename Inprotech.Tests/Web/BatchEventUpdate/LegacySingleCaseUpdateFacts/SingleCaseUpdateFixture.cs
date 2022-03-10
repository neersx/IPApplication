using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Rules;
using NSubstitute;

namespace Inprotech.Tests.Web.BatchEventUpdate.LegacySingleCaseUpdateFacts
{
    public class SingleCaseUpdateFixture : IFixture<SingleCaseUpdate>
    {
        readonly CaseDataEntryTaskModel _caseDataEntryTaskModel;
        readonly InMemoryDbContext _db;
        readonly Case _existingCase;

        public SingleCaseUpdateFixture(InMemoryDbContext db)
        {
            _db = db;

            DataEntryTaskDispatcher = Substitute.For<IDataEntryTaskDispatcher>();
            InputFormatter = Substitute.For<IDataEntryTaskHandlerInputFormatter>();

            PolicingRequestProcessor = Substitute.For<IPolicingRequestProcessor>();

            BatchDataEntryTaskPrerequisiteCheck = Substitute.For<IBatchDataEntryTaskPrerequisiteCheck>();

            BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                                               .ReturnsForAnyArgs(new BatchDataEntryTaskPrerequisiteCheckResult());

            _caseDataEntryTaskModel = new CaseDataEntryTaskModel();
            _existingCase = new CaseBuilder().Build().In(db);
            ExistingDataEntryTask = new DataEntryTaskBuilder().Build().In(db);
        }

        public IDataEntryTaskDispatcher DataEntryTaskDispatcher { get; set; }
        protected IDataEntryTaskHandlerInputFormatter InputFormatter { get; set; }
        protected IPolicingRequestProcessor PolicingRequestProcessor { get; set; }
        public IBatchDataEntryTaskPrerequisiteCheck BatchDataEntryTaskPrerequisiteCheck { get; set; }
        public SingleCaseUpdateResult CaseUpdateResult { get; set; }
        public DataEntryTaskCompletionResult ExistingDispatcherResults { get; set; }
        public DataEntryTask ExistingDataEntryTask { get; set; }

        public SingleCaseUpdate Subject => new SingleCaseUpdate(
                                                                _db,
                                                                DataEntryTaskDispatcher,
                                                                InputFormatter,
                                                                PolicingRequestProcessor,
                                                                BatchDataEntryTaskPrerequisiteCheck);

        public async Task Run()
        {
            CaseUpdateResult = await Subject.Update(_caseDataEntryTaskModel, _existingCase, ExistingDataEntryTask);
        }
    }
}