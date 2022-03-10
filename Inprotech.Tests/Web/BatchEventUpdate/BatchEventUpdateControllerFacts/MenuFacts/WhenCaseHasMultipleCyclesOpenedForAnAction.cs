using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    MenuFacts
{
    public class WhenCaseHasMultipleCyclesOpenedForAnAction : FactBase
    {
        void SetData(MenuFixture fixture)
        {
            var actionNew = new OpenActionBuilder(Db)
            {
                Case = fixture.ExistingCase,
                Action = fixture.ExistingOpenAction.Action,
                Criteria = fixture.ExistingOpenAction.Criteria,
                IsOpen = true
            }.Build().In(Db);
            actionNew.Cycle = 3;
            fixture.ExistingOpenAction.Criteria.DataEntryTasks.Add(fixture.SelectedDataEntryTask);
            fixture.ExistingCase.OpenActions.Add(actionNew);
        }
        [Fact]
        public async Task ItShouldReturnTheActionOnlyOnceAndBeTheHighestCycle()
        {
            var fixture = new MenuFixture(Db);
            SetData(fixture);
            await fixture.Run();

            Assert.Single(fixture.Result);
            Assert.Equal(3, fixture.Result[0].Cycle);
        }

        [Fact]
        public async Task ItShouldReturnAllCyclesForOpenAction()
        {
            var fixture = new MenuFixture(Db);
            SetData(fixture);
            await fixture.Run();

            var result = fixture.Result.First(oam => oam.Action.ActionId == fixture.ExistingOpenAction.ActionId);

            Assert.Equal(result.OpenCycles.Count(), 2);
            Assert.Equal(result.OpenCycles.First(), 1);
            Assert.Equal(result.OpenCycles.Last(), 3);
        }
    }
}