using System.Threading.Tasks;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    EventsFacts
{
    public class IfTheSelectedDataEntryTaskRequiresConfirmationOnSave : FactBase
    {
        [Fact]
        public async Task It_should_display_a_confirmation_dialog()
        {
            var fixture = new EventsFixture(Db);
            var statusId = Fixture.Short();
            var newCaseStatus = new StatusBuilder {Id = statusId, Name = Fixture.String()}.Build();
            newCaseStatus.ConfirmationRequiredFlag = 1;

            fixture.SelectedDataEntryTask.Criteria.Action.NumberOfCyclesAllowed = 1;
            fixture.SelectedDataEntryTask.CaseStatusCodeId = statusId;
            fixture.SelectedDataEntryTask.CaseStatus = newCaseStatus;
            fixture.ExistingCase.CaseStatus =
                new StatusBuilder {Id = (short) (statusId + 1), Name = Fixture.String()}.Build();
            await fixture.Run();

            Assert.True(fixture.Result.ShouldConfirmOnSave);
        }
    }
}