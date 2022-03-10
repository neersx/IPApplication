using System.Threading.Tasks;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    public class CreateScheduleFacts : FactBase
    {
        static JObject Build(string customerNumbers, int? daysWithinLast = null)
        {
            return new JObject
            {
                {"customerNumbers", customerNumbers},
                {"daysWithinLast", daysWithinLast}
            };
        }

        class CreateScheduleFixture : IFixture<CreateSchedule>
        {
            public CreateScheduleFixture(InMemoryDbContext db)
            {
                Subject = new CreateSchedule(db);
            }

            public CreateSchedule Subject { get; }
        }

        [Fact]
        public async Task CreatesSchedule()
        {
            new Sponsorship {Id = 1001, CustomerNumbers = "10001,1002", SponsoredAccount = "test", ServiceId = "10001"}.In(Db);

            var f = new CreateScheduleFixture(Db);
            var r = await f.Subject.TryCreateFrom(Build(string.Empty, 30));
            Assert.True(r.IsValid);
            Assert.Equal("success", r.ValidationResult);
            Assert.NotNull(r.Schedule.ExtendedSettings);

            var e = JsonConvert.DeserializeObject<PrivatePairSchedule>(r.Schedule.ExtendedSettings);
            Assert.Equal(string.Empty, e.CustomerNumbers);
            Assert.Equal(30, e.DaysWithinLast);
        }

        [Fact]
        public async Task RejectsIfSponsorProvidedIsDeleted()
        {
            var deletedCert = new Sponsorship
            {
                IsDeleted = true
            }.In(Db);

            var f = new CreateScheduleFixture(Db);
            var r = await f.Subject.TryCreateFrom(Build("70859", deletedCert.Id));
            Assert.False(r.IsValid);
            Assert.Equal("missing-uspto-sponsorship", r.ValidationResult);
        }

        [Fact]
        public async Task RejectsIfSponsorProvidedIsNotFound()
        {
            var f = new CreateScheduleFixture(Db);
            var r = await f.Subject.TryCreateFrom(Build("70859,12345"));
            Assert.False(r.IsValid);
            Assert.Equal("missing-uspto-sponsorship", r.ValidationResult);
        }

        [Fact]
        public async Task RejectsIfCustomerNumbersNotProvided()
        {
            var f = new CreateScheduleFixture(Db);
            var r = await f.Subject.TryCreateFrom(Build(string.Empty));
            Assert.False(r.IsValid);
            Assert.Equal("missing-uspto-sponsorship", r.ValidationResult);
        }
    }
}