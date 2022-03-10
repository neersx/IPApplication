using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate.Models;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    SaveFacts
{
    public class WhenAttemptingToBatchEventUpdateWithInvalidDataEntryTask : FactBase
    {
        [Fact]
        public async Task It_should_have_the_correct_error_message()
        {
            var fixture = new SaveFixture(Db);

            var otherOpenAction = OpenActionBuilder.ForCaseAsValid(Db, fixture.ExistingCase).Build().In(Db);
            var dataEntryTask = new DataEntryTaskBuilder {Criteria = otherOpenAction.Criteria}.Build().In(Db);

            fixture.CaseDataEntryTaskModels = new[]
            {
                new CaseDataEntryTaskModel {CaseId = fixture.ExistingCase.Id}
            };

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                Cases = fixture.CaseDataEntryTaskModels,
                CriteriaId = fixture.ExistingCriteria.Id,
                DataEntryTaskId = dataEntryTask.Id
            };

            await fixture.Run();

            Assert.Equal("No such data entry task for the case", fixture.Exception.Message);
        }

        [Fact]
        public async Task It_should_have_the_correct_http_status_code()
        {
            var fixture = new SaveFixture(Db);

            var otherOpenAction = OpenActionBuilder.ForCaseAsValid(Db, fixture.ExistingCase).Build().In(Db);
            var dataEntryTask = new DataEntryTaskBuilder {Criteria = otherOpenAction.Criteria}.Build().In(Db);

            fixture.CaseDataEntryTaskModels = new[]
            {
                new CaseDataEntryTaskModel {CaseId = fixture.ExistingCase.Id}
            };

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                Cases = fixture.CaseDataEntryTaskModels,
                CriteriaId = fixture.ExistingCriteria.Id,
                DataEntryTaskId = dataEntryTask.Id
            };

            await fixture.Run();

            Assert.Equal(400, fixture.Exception.GetHttpCode());
        }
    }
}