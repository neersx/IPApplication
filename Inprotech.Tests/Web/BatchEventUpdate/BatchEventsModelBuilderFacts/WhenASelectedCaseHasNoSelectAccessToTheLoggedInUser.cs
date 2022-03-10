using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventsModelBuilderFacts
{
    public class WhenASelectedCaseHasNoSelectAccessToTheLoggedInUser : FactBase
    {
        [Fact]
        public async Task It_should_not_be_included_in_non_updatable_list()
        {
            var fixture = new Fixture(Db);

            fixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                   .ReturnsForAnyArgs(
                                      new BatchDataEntryTaskPrerequisiteCheckResult(
                                                                                    new DataEntryTaskPrerequisiteCheckResult(true,
                                                                                                                             caseAccessSelectSecurityFailed: true)));

            await fixture.Run();
            Assert.True(fixture.Result.NonUpdatableCases.All(ic => ic.Id != fixture.ExistingCase.Id));
        }

        [Fact]
        public async Task It_should_not_be_included_in_updatable_list()
        {
            var fixture = new Fixture(Db);

            fixture.BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                   .ReturnsForAnyArgs(
                                      new BatchDataEntryTaskPrerequisiteCheckResult(
                                                                                    new DataEntryTaskPrerequisiteCheckResult(true,
                                                                                                                             caseAccessSelectSecurityFailed: true)));

            await fixture.Run();

            Assert.True(fixture.Result.UpdatableCases.All(uc => uc.Id != fixture.ExistingCase.Id));
        }
    }
}