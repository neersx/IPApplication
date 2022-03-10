using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.MenuFacts
{
    public class WhenOpenActionCriteriaHasMultipleStepsInDataEntryTask : FactBase
    {
        protected DataEntryTask DataEntryTaskWithAdditionalTabs { get; private set; }

        [Fact]
        public async Task It_should_not_return_data_entry_task_with_additional_tabs()
        {
            var fixture = new MenuFixture(Db);

            DataEntryTaskWithAdditionalTabs =
                DataEntryTaskBuilder.ForCriteria(fixture.ExistingOpenAction.Criteria).Build().In(Db);
            DataEntryTaskWithAdditionalTabs.AvailableEvents.Add(new AvailableEventBuilder().Build());
            fixture.ExistingOpenAction.Criteria.DataEntryTasks.Add(DataEntryTaskWithAdditionalTabs);

            new DataEntryTaskStepBuilder
            {
                Criteria = fixture.ExistingOpenAction.Criteria,
                DataEntryTask = DataEntryTaskWithAdditionalTabs,
                ScreenName = "frmMyTest"
            }.Build().In(Db);

            await fixture.Run();

            Assert.True(fixture.Result.First().DataEntryTasks.All(det => det.Id != DataEntryTaskWithAdditionalTabs.Id));
        }

        [Fact]
        public async Task It_should_return_data_entry_task_with_default_tabs_only()
        {
            var fixture = new MenuFixture(Db);

            DataEntryTaskWithAdditionalTabs =
                DataEntryTaskBuilder.ForCriteria(fixture.ExistingOpenAction.Criteria).Build().In(Db);
            DataEntryTaskWithAdditionalTabs.AvailableEvents.Add(new AvailableEventBuilder().Build());
            fixture.ExistingOpenAction.Criteria.DataEntryTasks.Add(DataEntryTaskWithAdditionalTabs);

            new DataEntryTaskStepBuilder
            {
                Criteria = fixture.ExistingOpenAction.Criteria,
                DataEntryTask = DataEntryTaskWithAdditionalTabs,
                ScreenName = "frmMyTest"
            }.Build().In(Db);

            await fixture.Run();

            Assert.Equal(3, fixture.Result.First().DataEntryTasks.Count());
        }
    }
}