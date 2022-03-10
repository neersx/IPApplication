using System.Collections.Generic;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventsModelBuilderFacts
{
    public class WhenInputIsAnEmptyListOfCases : FactBase
    {
        [Fact]
        public async Task Nonupdatable_cases_list_should_be_empty()
        {
            var fixture = new Fixture(Db);
            fixture.ExistingCases = new List<Case>();
            await fixture.Run();
            Assert.True(fixture.Result.NonUpdatableCases.Length == 0);
        }

        [Fact]
        public async Task Updatable_cases_list_should_be_empty()
        {
            var fixture = new Fixture(Db);
            fixture.ExistingCases = new List<Case>();
            await fixture.Run();
            Assert.True(fixture.Result.UpdatableCases.Length == 0);
        }
    }
}