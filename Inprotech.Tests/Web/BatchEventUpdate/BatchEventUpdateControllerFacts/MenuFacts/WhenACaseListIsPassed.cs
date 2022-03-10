using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.MenuFacts
{
    public class WhenACaseListIsPassed : FactBase
    {
        [Fact]
        public async Task It_should_only_return_open_actions_for_the_first_case_the_user_has_access_to()
        {
            var fixture = new MenuFixture(Db);

            await fixture.Run();

            Assert.True(
                        fixture.Result.All(
                                           oam =>
                                               fixture.ExistingCase.OpenActions.Any(
                                                                                    oa =>
                                                                                        oa.IsOpen && oa.ActionId == oam.Action.ActionId &&
                                                                                        oa.Criteria.Id == oam.CriteriaId)));
        }

        [Fact]
        public async Task It_should_only_return_open_actions_with_a_data_entry_task()
        {
            var fixture = new MenuFixture(Db);

            await fixture.Run();

            Assert.True(
                        fixture.Result.All(
                                           oam =>
                                               fixture.ExistingCase.OpenActions.Any(
                                                                                    oa => oa.Criteria.DataEntryTasks.Any())));
        }

        [Fact]
        public async Task It_should_return_data_entry_task_in_order_of_display_sequence()
        {
            var fixture = new MenuFixture(Db);

            await fixture.Run();

            var firstEntryTask =
                fixture.ExistingOpenAction.Criteria.DataEntryTasks.OrderBy(det => det.DisplaySequence).First();

            var result = fixture.Result.First(oam => oam.Action.ActionId == fixture.ExistingOpenAction.ActionId);

            Assert.Equal(firstEntryTask.DisplaySequence, result.DataEntryTasks.First().DisplaySequence);
        }
    }
}