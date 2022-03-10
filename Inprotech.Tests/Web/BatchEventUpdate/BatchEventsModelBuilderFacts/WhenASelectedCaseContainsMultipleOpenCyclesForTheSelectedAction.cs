using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventsModelBuilderFacts
{
    public class WhenASelectedCaseContainsMultipleOpenCyclesForTheSelectedAction : FactBase
    {
        [Fact]
        public async Task It_should_be_in_non_updateable_cases_list_with_correct_reason()
        {
            var fixture = new Fixture(Db);

            fixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                   .ReturnsForAnyArgs(new BatchDataEntryTaskPrerequisiteCheckResult(hasMultipleOpenActionCycles: true));

            await fixture.Run();

            Assert.True(fixture.Result.NonUpdatableCases.Single(ic => ic.Id == fixture.ExistingCase.Id).HasMultipleOpenActionCycles);
        }
    }

    public class WhenASelectedCaseDoesNotContainOpenActionWIthGivenCycle : FactBase
    {
        [Fact]
        public async Task It_should_be_in_non_updateable_cases_list_with_correct_reason()
        {
            var fixture = new Fixture(Db);

            fixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                   .ReturnsForAnyArgs(new BatchDataEntryTaskPrerequisiteCheckResult(noRecordsForSelectedCycle: true));

            await fixture.Run();

            Assert.True(fixture.Result.NonUpdatableCases.Single(ic => ic.Id == fixture.ExistingCase.Id).HasNoRecordsForSelectedCycle);
        }
    }
}