﻿using System.Threading.Tasks;
using Inprotech.Web.BatchEventUpdate.Models;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    SaveFacts
{
    public class WhenAttemptingToBatchEventUpdateWithInvalidCase : FactBase
    {
        [Fact]
        public async Task It_should_have_the_correct_error_message()
        {
            var fixture = new SaveFixture(Db);

            fixture.CaseDataEntryTaskModels = new[] {new CaseDataEntryTaskModel {CaseId = Fixture.Integer()}};

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                Cases = fixture.CaseDataEntryTaskModels,
                CriteriaId = fixture.ExistingCriteria.Id,
                DataEntryTaskId = fixture.ExistingDataEntryTask.Id
            };

            await fixture.Run();

            Assert.Equal("One or more cases for batch event update is invalid", fixture.Exception.Message);
        }

        [Fact]
        public async Task It_should_have_the_correct_http_status_code()
        {
            var fixture = new SaveFixture(Db);

            fixture.CaseDataEntryTaskModels = new[] {new CaseDataEntryTaskModel {CaseId = Fixture.Integer()}};

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                Cases = fixture.CaseDataEntryTaskModels,
                CriteriaId = fixture.ExistingCriteria.Id,
                DataEntryTaskId = fixture.ExistingDataEntryTask.Id
            };

            await fixture.Run();

            Assert.Equal(400, fixture.Exception.GetHttpCode());
        }
    }
}