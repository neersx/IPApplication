using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.SaveFacts
{
    public class WhenCasesSavedDoNotRequireImmediatePolicing : FactBase
    {
        [Fact]
        public async Task It_should_call_policing_for_as_many_updates_requiring_immediate_policing()
        {
            var fixture = new SaveFixture(Db);

            fixture.SingleCaseUpdate
                   .Update(Arg.Any<CaseDataEntryTaskModel>(), Arg.Any<Case>(), Arg.Any<DataEntryTask>())
                   .Returns(
                            new SingleCaseUpdateResult(
                                                       new DataEntryTaskCompletionResult(
                                                                                         true,
                                                                                         new DataEntryTaskHandlerResult[0],
                                                                                         new ValidationResult[0]
                                                                                        ),
                                                       new DataEntryTaskPrerequisiteCheckResult(
                                                                                                false,
                                                                                                false,
                                                                                                new CaseNameRestriction[0],
                                                                                                new CaseName[0],
                                                                                                true)));

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                CriteriaId = fixture.ExistingOpenAction.Criteria.Id,
                DataEntryTaskId = fixture.ExistingOpenAction.Criteria.DataEntryTasks.First().Id,
                Cases = new[]
                {
                    new CaseDataEntryTaskModel
                    {
                        CaseId = fixture.ExistingCase.Id,
                        Data = new KeyValuePair<string, string>[0]
                    }
                }
            };

            await fixture.Run();

            fixture.PolicingEngine.DidNotReceiveWithAnyArgs().PoliceAsync(0);
        }

        [Fact]
        public async Task It_should_return_as_many_single_case_update_result_as_there_are_cases_to_be_saved()
        {
            var fixture = new SaveFixture(Db);

            fixture.SingleCaseUpdate
                   .Update(Arg.Any<CaseDataEntryTaskModel>(), Arg.Any<Case>(), Arg.Any<DataEntryTask>())
                   .Returns(
                            new SingleCaseUpdateResult(
                                                       new DataEntryTaskCompletionResult(
                                                                                         true,
                                                                                         new DataEntryTaskHandlerResult[0],
                                                                                         new ValidationResult[0]
                                                                                        ),
                                                       new DataEntryTaskPrerequisiteCheckResult(
                                                                                                false,
                                                                                                false,
                                                                                                new CaseNameRestriction[0],
                                                                                                new CaseName[0],
                                                                                                true)));

            fixture.SaveBatchEventsModel = new SaveBatchEventsModel
            {
                AreWarningsConfirmed = true,
                CriteriaId = fixture.ExistingOpenAction.Criteria.Id,
                DataEntryTaskId = fixture.ExistingOpenAction.Criteria.DataEntryTasks.First().Id,
                Cases = new[]
                {
                    new CaseDataEntryTaskModel
                    {
                        CaseId = fixture.ExistingCase.Id,
                        Data = new KeyValuePair<string, string>[0]
                    }
                }
            };

            await fixture.Run();

            Assert.Equal(fixture.Result.Count(), fixture.SaveBatchEventsModel.Cases.Count());
        }
    }
}