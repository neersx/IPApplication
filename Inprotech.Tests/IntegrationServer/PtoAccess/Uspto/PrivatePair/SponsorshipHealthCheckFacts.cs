using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class SponsorshipHealthCheckFacts : FactBase
    {
        [Theory]
        [InlineData("401 - Authentication Error")]
        [InlineData("408 - Some other error 408")]
        [InlineData("409 - Some other error 409")]
        [InlineData("500 : no cookies, unexpectedly empty java response")]
        public async Task SetsAuthenticationErrorForAllMessages(string messageText)
        {
            var f = new SponsorshipHealthCheckFixture(Db);
            var services = f.CreateSponsorship(2);
            var message = f.GetAuthErrorMessage(services.First().ServiceId);
            message.Meta.EventDate = Fixture.FutureDate().SetFileStoreMessageEventTimeStamp();
            message.Meta.Message = messageText;

            f.Subject.CheckErrors(message);
            await f.Subject.SetSponsorshipStatus();

            Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();

            var dbService = Db.Set<Sponsorship>().First(_ => _.ServiceId == message.Meta.ServiceId);
            Assert.Equal(SponsorshipStatus.Error, dbService.Status);
            Assert.Equal(message.Meta.EventDateParsed, dbService.StatusDate);
            Assert.Equal(message.Meta.Message, dbService.StatusMessage);
        }

        class SponsorshipHealthCheckFixture : IFixture<ISponsorshipHealthCheck>
        {
            public SponsorshipHealthCheckFixture(InMemoryDbContext db)
            {
                Db = db;
                Subject = new SponsorshipHealthCheck(Db);
            }

            InMemoryDbContext Db { get; }

            public ISponsorshipHealthCheck Subject { get; }

            public IEnumerable<Sponsorship> CreateSponsorship(int count = 1)
            {
                for (var i = 0; i < count; i++)
                {
                    yield return new Sponsorship
                    {
                        CustomerNumbers = Fixture.String(),
                        ServiceId = Fixture.String(),
                        SponsorName = Fixture.String(),
                        SponsoredAccount = Fixture.String(),
                        StatusDate = Fixture.Today()
                    }.In(Db);
                }
            }

            public Message GetMessage(string serviceId)
            {
                return new Message
                {
                    Meta = new Meta
                    {
                        ServiceId = serviceId,
                        Status = "success",
                        EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()
                    }
                };
            }

            public Message GetAuthErrorMessage(string serviceId)
            {
                return new Message
                {
                    Meta = new Meta
                    {
                        ServiceId = serviceId,
                        Status = "error",
                        EventDate = Fixture.Today().Date.SetFileStoreMessageEventTimeStamp(),
                        Message = "401 - Authentication Error"
                    }
                };
            }
        }

        [Fact]
        public async Task DoesNotSaveChangesIfNoData()
        {
            var f = new SponsorshipHealthCheckFixture(Db);
            await f.Subject.SetSponsorshipStatus();
            Db.DidNotReceiveWithAnyArgs().SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DoesNotSetAuthenticationErrorIfStatusDateIsNewer()
        {
            var f = new SponsorshipHealthCheckFixture(Db);
            var services = f.CreateSponsorship(2);
            var service = services.First();
            var message = f.GetAuthErrorMessage(service.ServiceId);
            message.Meta.EventDate = Fixture.PastDate().SetFileStoreMessageEventTimeStamp();

            f.Subject.CheckErrors(message);
            await f.Subject.SetSponsorshipStatus();

            var dbService = Db.Set<Sponsorship>().First(_ => _.ServiceId == message.Meta.ServiceId);
            Assert.Equal(SponsorshipStatus.Submitted, dbService.Status);
            Assert.Equal(service.StatusDate, dbService.StatusDate);
            Assert.Equal(service.StatusMessage, dbService.StatusMessage);
        }

        [Fact]
        public async Task PicksLatestMessageToSetStatus()
        {
            var f = new SponsorshipHealthCheckFixture(Db);
            var services = f.CreateSponsorship(2);
            var service = services.First();

            var message = f.GetAuthErrorMessage(service.ServiceId);
            message.Meta.EventDate = Fixture.PastDate().SetFileStoreMessageEventTimeStamp();

            var message2 = f.GetMessage(service.ServiceId);

            f.Subject.CheckErrors(message);
            f.Subject.CheckErrors(message2);
            await f.Subject.SetSponsorshipStatus();

            var dbService = Db.Set<Sponsorship>().First(_ => _.ServiceId == message.Meta.ServiceId);
            Assert.Equal(SponsorshipStatus.Active, dbService.Status);
            Assert.Equal(message2.Meta.EventDateParsed, dbService.StatusDate);
            Assert.Equal(message2.Meta.Message, dbService.StatusMessage);
        }

        [Fact]
        public async Task SetsAuthenticationError()
        {
            var f = new SponsorshipHealthCheckFixture(Db);
            var services = f.CreateSponsorship(2);
            var message = f.GetAuthErrorMessage(services.First().ServiceId);

            f.Subject.CheckErrors(message);
            await f.Subject.SetSponsorshipStatus();

            Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();

            var dbService = Db.Set<Sponsorship>().First(_ => _.ServiceId == message.Meta.ServiceId);
            Assert.Equal(SponsorshipStatus.Error, dbService.Status);
            Assert.Equal(message.Meta.EventDateParsed, dbService.StatusDate);
            Assert.Equal(message.Meta.Message, dbService.StatusMessage);
        }
    }
}