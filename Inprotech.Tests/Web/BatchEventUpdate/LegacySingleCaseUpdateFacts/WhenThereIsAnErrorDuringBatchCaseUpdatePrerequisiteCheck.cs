using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.LegacySingleCaseUpdateFacts
{
    public class WhenThereIsAnErrorDuringBatchCaseUpdatePrerequisiteCheck : FactBase
    {
        [Fact]
        public async Task It_should_perform_the_prerequisite_check()
        {
            var singleCaseUpdateFixture = new SingleCaseUpdateFixture(Db);

            singleCaseUpdateFixture.BatchDataEntryTaskPrerequisiteCheck = Substitute.For<IBatchDataEntryTaskPrerequisiteCheck>();

            singleCaseUpdateFixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                                   .ReturnsForAnyArgs(
                                                      new BatchDataEntryTaskPrerequisiteCheckResult(
                                                                                                    new DataEntryTaskPrerequisiteCheckResult(
                                                                                                                                             false,
                                                                                                                                             false,
                                                                                                                                             new CaseNameRestriction[0],
                                                                                                                                             new CaseName[0],
                                                                                                                                             true),
                                                                                                    true));

            await singleCaseUpdateFixture.Run();

            singleCaseUpdateFixture.BatchDataEntryTaskPrerequisiteCheck.ReceivedWithAnyArgs(1).Run(null, null).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task It_should_return_an_error()
        {
            var singleCaseUpdateFixture = new SingleCaseUpdateFixture(Db);

            singleCaseUpdateFixture.BatchDataEntryTaskPrerequisiteCheck = Substitute.For<IBatchDataEntryTaskPrerequisiteCheck>();

            singleCaseUpdateFixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                                   .ReturnsForAnyArgs(
                                                      new BatchDataEntryTaskPrerequisiteCheckResult(
                                                                                                    new DataEntryTaskPrerequisiteCheckResult(
                                                                                                                                             false,
                                                                                                                                             false,
                                                                                                                                             new CaseNameRestriction[0],
                                                                                                                                             new CaseName[0],
                                                                                                                                             true),
                                                                                                    true));

            await singleCaseUpdateFixture.Run();

            Assert.True(singleCaseUpdateFixture.CaseUpdateResult.DataEntryTaskCompletionResult.HasErrors);
        }
    }
}