using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.LegacySingleCaseUpdateFacts
{
    public class IfThereAreErrorsAndWarningsInTheUpdate : FactBase
    {
        [Fact]
        public async Task It_should_not_return_the_results_of_the_update_with_errors_and_warnings()
        {
            var singleCaseUpdateFixture = new SingleCaseUpdateFixture(Db);

            var ho = new DataEntryTaskHandlerOutput(
                                                    new[]
                                                    {
                                                        new ValidationResult(Fixture.String()),
                                                        new ValidationResult(Fixture.String(), Severity.Warning)
                                                    });

            singleCaseUpdateFixture.ExistingDispatcherResults = new DataEntryTaskCompletionResult(
                                                                                                  false,
                                                                                                  new[]
                                                                                                  {
                                                                                                      new DataEntryTaskHandlerResult(
                                                                                                                                     Fixture.String("HandlerName"),
                                                                                                                                     ho)
                                                                                                  },
                                                                                                  new ValidationResult[0]
                                                                                                 );

            singleCaseUpdateFixture.DataEntryTaskDispatcher.ApplyChanges(Arg.Any<DataEntryTaskInput>())
                                   .Returns(singleCaseUpdateFixture.ExistingDispatcherResults);

            await singleCaseUpdateFixture.Run();

            Assert.True(
                        singleCaseUpdateFixture.CaseUpdateResult.DataEntryTaskCompletionResult.HasErrors &&
                        singleCaseUpdateFixture.CaseUpdateResult.DataEntryTaskCompletionResult.HasWarnings);
        }
    }
}