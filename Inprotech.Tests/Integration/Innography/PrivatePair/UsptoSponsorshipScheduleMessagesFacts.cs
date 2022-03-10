using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.PrivatePair
{
    public class UsptoSponsorshipScheduleMessagesFacts : FactBase
    {
        [Fact]
        public void ReturnsNullIfSponsorshipsNotFound()
        {
            var f = new UsptoSponsorshipScheduleMessagesFixture(Db);
            var response = f.Subject.Resolve(Fixture.Integer());
            Assert.Null(response);
        }

        [Fact]
        public void ReturnsNullIfSponsorshipsNotFoundForMultipleSchedules()
        {
            var f = new UsptoSponsorshipScheduleMessagesFixture(Db);
            var response = f.Subject.Resolve(new[] { Fixture.Integer(), Fixture.Integer(), Fixture.Integer() });
            Assert.Empty(response);
        }

        [Fact]
        public void DoesNotConsiderDeletedSponsorships()
        {
            new Sponsorship() { ServiceId = Fixture.String(), Status = SponsorshipStatus.Error, StatusMessage = Fixture.String(), IsDeleted = true }.In(Db);
            var f = new UsptoSponsorshipScheduleMessagesFixture(Db);
            var response = f.Subject.Resolve(Fixture.Integer());
            Assert.Null(response);
        }

        [Fact]
        public void ReturnsSponsorshipsThatHaveError()
        {
            new Sponsorship() { ServiceId = Fixture.String(), Status = SponsorshipStatus.Active, StatusMessage = Fixture.String() }.In(Db);
            new Sponsorship() { ServiceId = Fixture.String(), Status = SponsorshipStatus.Error, StatusMessage = Fixture.String() }.In(Db);
            var f = new UsptoSponsorshipScheduleMessagesFixture(Db);
            var response = f.Subject.Resolve(Fixture.Integer());
            Assert.NotNull(response);
            Assert.Equal("sponsorshipError", response.Message);
            Assert.Equal("sponsorshipLink", response.Link.Text);
            Assert.Equal("#/integration/ptoaccess/uspto-private-pair-sponsorships", response.Link.Url);
        }

        class UsptoSponsorshipScheduleMessagesFixture : IFixture<UsptoSponsorshipScheduleMessages>
        {
            public UsptoSponsorshipScheduleMessagesFixture(InMemoryDbContext db)
            {
                Db = db;
                Subject = new UsptoSponsorshipScheduleMessages(Db);
            }

            public UsptoSponsorshipScheduleMessages Subject { get; }
            InMemoryDbContext Db { get; }
        }
    }
}