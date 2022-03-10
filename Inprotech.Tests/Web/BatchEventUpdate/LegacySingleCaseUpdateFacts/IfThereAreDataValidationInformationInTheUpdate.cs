using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.LegacySingleCaseUpdateFacts
{
    public class IfThereAreDataValidationInformationInTheUpdate : FactBase
    {
        [Fact]
        public async Task It_should_return_the_results_of_the_update_with_no_warnings_and_errors()
        {
            var singleCaseUpdateFixture = new SingleCaseUpdateFixture(Db);

            singleCaseUpdateFixture.ExistingDispatcherResults = new DataEntryTaskCompletionResult(
                                                                                                  false,
                                                                                                  new[]
                                                                                                  {
                                                                                                      new DataEntryTaskHandlerResult(
                                                                                                                                     Fixture.String("HandlerName"),
                                                                                                                                     new DataEntryTaskHandlerOutput())
                                                                                                  },
                                                                                                  new[]
                                                                                                  {
                                                                                                      new ValidationResult(
                                                                                                                           Fixture.String("Message"),
                                                                                                                           Severity.Information).WithDetails(
                                                                                                                                                             new
                                                                                                                                                             {
                                                                                                                                                                 ValidationKey = Fixture.Integer()
                                                                                                                                                             })
                                                                                                                                                .CorrelateWithEntity(singleCaseUpdateFixture.ExistingDataEntryTask)
                                                                                                  });
            singleCaseUpdateFixture.DataEntryTaskDispatcher.ApplyChanges(Arg.Any<DataEntryTaskInput>())
                                   .Returns(singleCaseUpdateFixture.ExistingDispatcherResults);

            await singleCaseUpdateFixture.Run();

            Assert.True(
                        !singleCaseUpdateFixture.CaseUpdateResult.DataEntryTaskCompletionResult.HasWarnings &&
                        !singleCaseUpdateFixture.CaseUpdateResult.DataEntryTaskCompletionResult.HasErrors);
        }
    }
}