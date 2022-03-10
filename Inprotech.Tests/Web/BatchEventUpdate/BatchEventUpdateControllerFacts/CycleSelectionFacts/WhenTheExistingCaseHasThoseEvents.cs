using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    CycleSelectionFacts
{
    public class WhenTheExistingCaseHasThoseEvents : FactBase
    {
        [Fact]
        public async Task It_should_return_all_cycles_of_that_event_in_the_case()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase.CurrentOfficialNumber = Fixture.String();

            fixture.ExistingCase.Irn = Fixture.String();

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 2
                                                }.AsEventOccurred(Fixture.Today()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.OtherCyclicEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.NextRenewalDateEvent.Description = Fixture.String();

            await fixture.Run();

            Assert.True(
                        fixture.Result.Events.Count() ==
                        fixture.ExistingCase.CaseEvents.Count(ce => ce.EventNo == fixture.NextRenewalDateEvent.Id));
        }

        [Fact]
        public async Task It_should_return_the_correct_case_current_official_number()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase.CurrentOfficialNumber = Fixture.String();

            fixture.ExistingCase.Irn = Fixture.String();

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 2
                                                }.AsEventOccurred(Fixture.Today()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.OtherCyclicEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.NextRenewalDateEvent.Description = Fixture.String();

            await fixture.Run();

            Assert.Equal(fixture.Result.CurrentOfficialNumber, fixture.ExistingCase.CurrentOfficialNumber);
        }

        [Fact]
        public async Task It_should_return_the_correct_case_reference()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase.CurrentOfficialNumber = Fixture.String();

            fixture.ExistingCase.Irn = Fixture.String();

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 2
                                                }.AsEventOccurred(Fixture.Today()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.OtherCyclicEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.NextRenewalDateEvent.Description = Fixture.String();

            await fixture.Run();

            Assert.Equal(fixture.Result.CaseReference, fixture.ExistingCase.Irn);
        }

        [Fact]
        public async Task It_should_return_the_event_description_from_the_event()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase.CurrentOfficialNumber = Fixture.String();

            fixture.ExistingCase.Irn = Fixture.String();

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.NextRenewalDateEvent.Id,
                                                    Cycle = 2
                                                }.AsEventOccurred(Fixture.Today()).Build());

            fixture.ExistingCase.CaseEvents.Add(
                                                new CaseEventBuilder
                                                {
                                                    EventNo = fixture.OtherCyclicEvent.Id,
                                                    Cycle = 1
                                                }.AsEventOccurred(Fixture.PastDate()).Build());

            fixture.NextRenewalDateEvent.Description = Fixture.String();

            await fixture.Run();

            Assert.Same(fixture.Result.EventDescription, fixture.NextRenewalDateEvent.Description);
        }
    }
}