using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Certificates;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    public class PrivatePairSchedulePrerequisiteFacts : FactBase
    {
        [Fact]
        public void ReturnsFalseWhenOnlyDeletedSponsorsAreAvailable()
        {
            new Certificate
            {
                IsDeleted = true
            }.In(Db);

            var subject = new PrivatePairSchedulePrerequisite(Db);

            string result;
            Assert.False(subject.Validate(out result));
            Assert.Equal("missing-uspto-sponsorship", result);
        }

        [Fact]
        public void ReturnsFalseWhenThereAreNoSponsors()
        {
            var subject = new PrivatePairSchedulePrerequisite(Db);

            string result;
            Assert.False(subject.Validate(out result));
            Assert.Equal("missing-uspto-sponsorship", result);
        }

        [Fact]
        public void ReturnsTrueWhenThereAreUndeletedSponsors()
        {
            new Sponsorship() { Id = 10001, SponsorName = "sponsor", ServiceId = "1001" }.In(Db);

            var subject = new PrivatePairSchedulePrerequisite(Db);

            string result;
            Assert.True(subject.Validate(out result));
        }
    }
}