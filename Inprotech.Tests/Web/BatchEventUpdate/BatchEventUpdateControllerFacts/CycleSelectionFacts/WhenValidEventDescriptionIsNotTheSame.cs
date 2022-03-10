using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    CycleSelectionFacts
{
    public class WhenValidEventDescriptionIsNotTheSame : FactBase
    {
        [Fact]
        public async Task It_should_return_the_valid_event_description()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.NextRenewalDateEvent.Description = Fixture.String();

            var validEventDescription = Fixture.String();

            fixture.ExistingDataEntryTask.Criteria.ValidEvents.Add(
                                                                   new ValidEventBuilder
                                                                   {
                                                                       Criteria = fixture.ExistingDataEntryTask.Criteria,
                                                                       Event = fixture.NextRenewalDateEvent,
                                                                       Description = validEventDescription,
                                                                       NumberOfCyclesAllowed = 2
                                                                   }.Build().In(Db));

            await fixture.Run();

            Assert.Same(fixture.Result.EventDescription, validEventDescription);
        }
    }
}