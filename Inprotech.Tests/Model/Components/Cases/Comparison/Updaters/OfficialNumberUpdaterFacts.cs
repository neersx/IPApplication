using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using NSubstitute;
using Xunit;
using OfficialNumber = InprotechKaizen.Model.Cases.OfficialNumber;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class OfficialNumberUpdaterFacts
    {
        public class AddOrUpdateOfficialNumbersMethod : FactBase
        {
            [Fact]
            public void AddsNewNumberIfNotExists()
            {
                var f = new OfficialNumberUpdaterFixture(Db);
                var @case = new CaseBuilder().Build();
                var officialNumberDate = Fixture.PastDate();
                @case.OfficialNumbers.Add(new OfficialNumber {NumberId = 1, IsCurrent = 1, Number = "A"});

                var comparedOfficialNumber = new InprotechKaizen.Model.Components.Cases.Comparison.Results.OfficialNumber
                {
                    Id = null,
                    MappedNumberTypeId = "O",
                    Number = new Value<string>().AsUpdatedValue(null, "B"),
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, officialNumberDate)
                };
                new NumberType("O", "Official", null).In(Db);

                var result = f.Subject.AddOrUpdateOfficialNumbers(@case, new[] {comparedOfficialNumber});

                Assert.Empty(result);

                var addedNumber = @case.OfficialNumbers.FirstOrDefault(o => o.Number == "B");

                Assert.Equal(2, @case.OfficialNumbers.Count);
                Assert.NotNull(addedNumber);
                Assert.Equal(officialNumberDate, addedNumber.DateEntered);
                Assert.Equal("O", addedNumber.NumberTypeId);
                Assert.Equal(1, addedNumber.IsCurrent);
                f.CurrentOfficialNumberUpdater.Received(1).Update(@case);
            }

            [Fact]
            public void ReturnsPolicingRequestsForEvents()
            {
                var f = new OfficialNumberUpdaterFixture(Db);
                var @case = new CaseBuilder().Build();
                var officialNumberDate = Fixture.PastDate();
                @case.OfficialNumbers.Add(new OfficialNumber {NumberId = 1, IsCurrent = 1, Number = "A"});

                var comparedOfficialNumber = new InprotechKaizen.Model.Components.Cases.Comparison.Results.OfficialNumber
                {
                    Id = 1,
                    EventNo = -1,
                    Cycle = 1,
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, officialNumberDate)
                };

                var result = f.Subject.AddOrUpdateOfficialNumbers(@case, new[] {comparedOfficialNumber});

                Assert.Single(result);
                f.EventUpdater.Received(1).AddOrUpdateEvent(@case, -1, officialNumberDate, 1);
            }

            [Fact]
            public void UpdatesExistingNumberAndDate()
            {
                var f = new OfficialNumberUpdaterFixture(Db);
                var @case = new CaseBuilder().Build();
                var officialNumberDate = Fixture.PastDate();
                @case.OfficialNumbers.Add(new OfficialNumber {NumberId = 1, IsCurrent = 1, Number = "A"});

                var comparedOfficialNumber = new InprotechKaizen.Model.Components.Cases.Comparison.Results.OfficialNumber
                {
                    Id = 1,
                    Number = new Value<string>().AsUpdatedValue("A", "B"),
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, officialNumberDate)
                };

                var result = f.Subject.AddOrUpdateOfficialNumbers(@case, new[] {comparedOfficialNumber});

                Assert.Empty(result);
                Assert.Equal("B", @case.OfficialNumbers.First().Number);
                Assert.Equal(officialNumberDate, @case.OfficialNumbers.First().DateEntered);
                f.CurrentOfficialNumberUpdater.Received(1).Update(@case);
            }
        }

        class OfficialNumberUpdaterFixture : IFixture<OfficialNumberUpdater>
        {
            public OfficialNumberUpdaterFixture(InMemoryDbContext db)
            {
                CurrentOfficialNumberUpdater = Substitute.For<ICurrentOfficialNumberUpdater>();
                EventUpdater = Substitute.For<IEventUpdater>();
                Subject = new OfficialNumberUpdater(db, CurrentOfficialNumberUpdater, EventUpdater);
            }

            public ICurrentOfficialNumberUpdater CurrentOfficialNumberUpdater { get; }
            public IEventUpdater EventUpdater { get; }

            public OfficialNumberUpdater Subject { get; }
        }
    }
}