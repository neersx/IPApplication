using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventsModelBuilderFacts
{
    public class WhenMoreThenOneCaseIsSpecified : FactBase
    {
        [Fact]
        public async Task It_should_return_result_with_cases_in_same_order_as_passed()
        {
            var fixture = new Fixture(Db);

            var otherCase = new CaseBuilder().Build().In(Db);

            otherCase.OpenActions.Add(
                                      OpenActionBuilder.ForCaseAsValid(
                                                                       Db,
                                                                       otherCase,
                                                                       fixture.ExistingOpenAction.Action,
                                                                       fixture.ExistingOpenAction.Criteria)
                                                       .Build());

            fixture.ExistingCases.Add(otherCase);

            await fixture.Run();

            Assert.True(fixture.Result.UpdatableCases.First().Id == fixture.ExistingCase.Id);
            Assert.True(fixture.Result.UpdatableCases.Skip(1).First().Id == otherCase.Id);
        }

        [Fact]
        public async Task It_should_return_result_with_each_case_listed_once()
        {
            var fixture = new Fixture(Db);

            var otherCase = new CaseBuilder().Build().In(Db);

            otherCase.OpenActions.Add(
                                      OpenActionBuilder.ForCaseAsValid(
                                                                       Db,
                                                                       otherCase,
                                                                       fixture.ExistingOpenAction.Action,
                                                                       fixture.ExistingOpenAction.Criteria)
                                                       .Build());

            fixture.ExistingCases.Add(otherCase);

            await fixture.Run();

            Assert.True(fixture.Result.UpdatableCases.Count() == 2);
        }
    }
}