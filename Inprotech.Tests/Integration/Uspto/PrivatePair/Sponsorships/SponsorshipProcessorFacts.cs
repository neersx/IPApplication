using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Uspto.PrivatePair.Sponsorships
{
    public class SponsorshipProcessorFact
    {
        public class SponsorshipProcessorFixture : IFixture<SponsorshipProcessor>
        {
            public SponsorshipProcessorFixture(InMemoryDbContext db)
            {
                Repository = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("internal", false));
                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());
                PrivatePairService = Substitute.For<IPrivatePairService>();

                InitialData();
                Subject = new SponsorshipProcessor(SecurityContext, Repository, PrivatePairService, SystemClock);
            }

            public ISecurityContext SecurityContext { get; set; }
            public InMemoryDbContext Repository { get; set; }
            public IPrivatePairService PrivatePairService { get; set; }
            public Func<DateTime> SystemClock { get; set; }
            public SponsorshipProcessor Subject { get; }
            public List<Sponsorship> SponsorshipData { get; private set; }

            void InitialData()
            {
                SponsorshipData = new List<Sponsorship>()
                {
                    new Sponsorship {Id = 10001, SponsorName = "test1", SponsoredAccount = "test@test.com", CustomerNumbers = "1111,2222", IsDeleted = false}.In(Repository),
                    new Sponsorship {Id = 10002, SponsorName = "test2", SponsoredAccount = "test@test2.com", CustomerNumbers = "2222,3333", IsDeleted = true, DeletedBy = 45, DeletedOn = DateTime.Now}.In(Repository)
                };
            }
        }

        public class GetSponsorshipMethod : FactBase
        {
            [Fact]
            public async Task GetSponsorships()
            {
                var processor = new SponsorshipProcessorFixture(Db);
                var result = await processor.Subject.GetSponsorships();

                Assert.NotNull(result);
                Assert.Single(result);
            }
        }

        public class CreateSponsorships : FactBase
        {
            [Fact]
            public async Task CreateSponsorshipsValidationFailedInvalidArguments()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel() { SponsorName = "test1", SponsoredEmail = "aaa.bbbb", CustomerNumbers = "1111,bbb" };

                await Assert.ThrowsAsync<ArgumentException>(async () => await processor.Subject.CreateSponsorship(model));
            }

            [Fact]
            public async Task CreateSponsorshipsValidationFailedDuplicateSponsorship()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { SponsorName = "test1", SponsoredEmail = "test@test.com", CustomerNumbers = "111001,222002", Password = "password", AuthenticatorKey = "string" };
                var result = await processor.Subject.CreateSponsorship(model);

                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("duplicate", result.Key);
            }

            [Fact]
            public async Task CreateSponsorshipsSuccessDuplicateCustomerNumber()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = "1111,222000", Password = "password", AuthenticatorKey = "string" };
                processor.PrivatePairService.CheckOrCreateAccount().Returns(Task.CompletedTask);
                processor.PrivatePairService.DispatchCrawlerService(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>())
                         .Returns("1110001ServiceId");

                var result = await processor.Subject.CreateSponsorship(model);

                Assert.NotNull(result);
                Assert.Equal("duplicateCustomerNumber", result.Key);
                Assert.Equal("1111", result.Error);
            }

            [Fact]
            public async Task CreateSponsorshipsSuccess()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { SponsorName = "test2", SponsoredEmail = "test@test2.com", CustomerNumbers = "111000,222000", Password = "password", AuthenticatorKey = "string" };
                processor.PrivatePairService.CheckOrCreateAccount().Returns(Task.CompletedTask);
                processor.PrivatePairService.DispatchCrawlerService(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>())
                         .Returns("1110001ServiceId");

                var result = await processor.Subject.CreateSponsorship(model);
                var db = Db.NoDeleteSet<Sponsorship>().Single(_ => _.SponsorName == model.SponsorName);

                Assert.NotNull(result);
                Assert.True(result.IsSuccess);

                Assert.Null(db.StatusMessage);
                Assert.Equal(SponsorshipStatus.Submitted, db.Status);
                Assert.Equal(Fixture.Today(), db.StatusDate);
            }
        }

        public class UpdateSponsorship : FactBase
        {
            [Fact]
            public async Task UpdateSponsorshipsSuccess()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { Id = processor.SponsorshipData.First().Id, SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = "111002,222003", Password = "password", AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));

                var result = await processor.Subject.UpdateSponsorship(model);
                var db = Db.NoDeleteSet<Sponsorship>().Single(_ => _.SponsorName == model.SponsorName);

                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
                Assert.Null(db.StatusMessage);
                Assert.Equal(SponsorshipStatus.Submitted, db.Status);
                Assert.Equal(Fixture.Today(), db.StatusDate);
            }

            [Fact]
            public async Task UpdateSponsorshipsArgumentFailureValidation()
            {
                var id = 10003;
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { Id = id, SponsorName = string.Empty, SponsoredEmail = "test@test2.com", CustomerNumbers = "1111,2222", Password = string.Empty, AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));
                await Assert.ThrowsAsync<ArgumentException>(async () => await processor.Subject.UpdateSponsorship(model));

                model = new SponsorshipModel { Id = id, SponsorName = "test1", SponsoredEmail = string.Empty, CustomerNumbers = "1111,2222", Password = "password", AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));
                await Assert.ThrowsAsync<ArgumentException>(async () => await processor.Subject.UpdateSponsorship(model));

                model = new SponsorshipModel { Id = id, SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = string.Empty, Password = "password", AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));
                await Assert.ThrowsAsync<ArgumentException>(async () => await processor.Subject.UpdateSponsorship(model));

                model = new SponsorshipModel { Id = id, SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = "1111,2222", Password = "password", AuthenticatorKey = "string", ServiceId = string.Empty };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));
                await Assert.ThrowsAsync<ArgumentException>(async () => await processor.Subject.UpdateSponsorship(model));
            }

            [Fact]
            public async Task UpdateSponsorshipsFailureValidation()
            {
                var processor = new SponsorshipProcessorFixture(Db);
                var sponsorship = new Sponsorship { Id = 10003, SponsorName = "test1", SponsoredAccount = "test@test.com", CustomerNumbers = "3333", IsDeleted = false, ServiceId = "1110001ServiceId" }.In(Db);

                var model = new SponsorshipModel
                {
                    Id = sponsorship.Id,
                    SponsorName = sponsorship.SponsorName,
                    SponsoredEmail = sponsorship.SponsoredAccount,
                    CustomerNumbers = sponsorship.CustomerNumbers,
                    Password = string.Empty,
                    AuthenticatorKey = string.Empty,
                    ServiceId = sponsorship.ServiceId
                };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));
                var resp = await processor.Subject.UpdateSponsorship(model);
                Assert.NotNull(resp);
                Assert.False(resp.IsSuccess);
                Assert.Equal("noChange", resp.Key);
            }

            [Fact]
            public async Task UpdateSponsorshipsFailureNotFound()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { Id = 10003, SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = "111004,222004", Password = "password", AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));

                await Assert.ThrowsAsync<InvalidOperationException>(async () => await processor.Subject.UpdateSponsorship(model));
            }

            [Fact]
            public async Task UpdateSponsorshipsFailureCustomerNumberDuplicate()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                var model = new SponsorshipModel { Id = processor.SponsorshipData.First().Id, SponsorName = "test1", SponsoredEmail = "test@test2.com", CustomerNumbers = "1111,3333", Password = "password", AuthenticatorKey = "string", ServiceId = "1110001ServiceId" };
                processor.PrivatePairService.UpdateServiceDetails(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string[]>()).Returns((true, null));

                var result = await processor.Subject.UpdateSponsorship(model);

                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("duplicateCustomerNumber", result.Key);
                Assert.Equal("1111", result.Error);
            }
        }

        public class GlobalAccountChangeUpdateSettings : FactBase
        {
            [Fact]
            public async Task UpdateSponsorshipsSettingsSuccess()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                processor.PrivatePairService.UpdateOneTimeGlobalAccountSettings(Arg.Any<DateTime>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns((true, null));

                var result = await processor.Subject.UpdateOneTimeGlobalAccountSettings(Fixture.String(), Fixture.String(), Fixture.String());

                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
            }

            [Fact]
            public async Task UpdateSponsorshipsSettingsFailureValidation()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                processor.PrivatePairService.UpdateOneTimeGlobalAccountSettings(Arg.Any<DateTime>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns((false, "failedToUpdate"));

                var result = await processor.Subject.UpdateOneTimeGlobalAccountSettings(Fixture.String(), Fixture.String(), Fixture.String());

                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("failedToUpdate", result.Key);
            }

            [Fact]
            public async Task RequeueOneDayByDefault()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                processor.PrivatePairService.UpdateOneTimeGlobalAccountSettings(Arg.Any<DateTime>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns((true, null));

                var result = await processor.Subject.UpdateOneTimeGlobalAccountSettings(Fixture.String(), Fixture.String(), Fixture.String());

                processor.PrivatePairService.Received(1)
                         .UpdateOneTimeGlobalAccountSettings(processor.SystemClock().AddDays(-1), processor.SystemClock(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
            }

            [Fact]
            public async Task SetMaximumDaysOf14ForRequeue()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                processor.PrivatePairService.UpdateOneTimeGlobalAccountSettings(Arg.Any<DateTime>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns((true, null));
                var schedule = new Schedule() { DataSourceType = DataSourceType.UsptoPrivatePair }.In(Db);
                new ScheduleExecution() { Schedule = schedule, Status = ScheduleExecutionStatus.Complete, Started = processor.SystemClock().AddDays(-30) }.In(Db);

                var result = await processor.Subject.UpdateOneTimeGlobalAccountSettings(Fixture.String(), Fixture.String(), Fixture.String());

                processor.PrivatePairService.Received(1)
                         .UpdateOneTimeGlobalAccountSettings(processor.SystemClock().AddDays(-14), processor.SystemClock(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
            }

            [Fact]
            public async Task SetDayForRequeue()
            {
                var processor = new SponsorshipProcessorFixture(Db);

                processor.PrivatePairService.UpdateOneTimeGlobalAccountSettings(Arg.Any<DateTime>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .Returns((true, null));
                var schedule = new Schedule() { DataSourceType = DataSourceType.UsptoPrivatePair }.In(Db);
                new ScheduleExecution() { Schedule = schedule, Status = ScheduleExecutionStatus.Complete, Started = processor.SystemClock().AddDays(-3) }.In(Db);

                var result = await processor.Subject.UpdateOneTimeGlobalAccountSettings(Fixture.String(), Fixture.String(), Fixture.String());

                processor.PrivatePairService.Received(1)
                         .UpdateOneTimeGlobalAccountSettings(processor.SystemClock().AddDays(-3), processor.SystemClock(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                         .IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(result);
                Assert.True(result.IsSuccess);
            }
        }

        public class DeleteSponsorship : FactBase
        {
            [Fact]
            public async Task DeleteSponsorships()
            {
                var processor = new SponsorshipProcessorFixture(Db);
                var another = new Sponsorship { Id = Fixture.Integer(), SponsorName = Fixture.String(), SponsoredAccount = Fixture.String(), CustomerNumbers = Fixture.String() }.In(Db);
                await processor.Subject.DeleteSponsorship(another.Id);

                Assert.Single(Db.NoDeleteSet<Sponsorship>());
                Assert.Equal(2, Db.Set<Sponsorship>().Count(_ => _.IsDeleted));
                Assert.Equal(processor.SponsorshipData.First().Id, Db.Set<Sponsorship>().Single(_ => !_.IsDeleted).Id);

                var dbAnother = Db.Set<Sponsorship>().Single(_ => _.Id == another.Id);
                Assert.True(dbAnother.IsDeleted);

                Assert.Equal(Fixture.Today(), dbAnother.DeletedOn);

                processor.PrivatePairService.DidNotReceiveWithAnyArgs().DeleteAccount().IgnoreAwaitForNSubstituteAssertion();
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DeleteSponsorshipsClearsServiceId()
            {
                var processor = new SponsorshipProcessorFixture(Db);
                var serviceId = Fixture.String();
                var another = new Sponsorship { Id = Fixture.Integer(), SponsorName = Fixture.String(), SponsoredAccount = Fixture.String(), CustomerNumbers = Fixture.String(), ServiceId = serviceId }.In(Db);
                await processor.Subject.DeleteSponsorship(another.Id);

                var dbAnother = Db.Set<Sponsorship>().Single(_ => _.Id == another.Id);
                Assert.Null(dbAnother.ServiceId);
                Assert.True(dbAnother.IsDeleted);
                Assert.Equal(Fixture.Today(), dbAnother.DeletedOn);

                processor.PrivatePairService.Received(1).DecommissionCrawlerService(serviceId).IgnoreAwaitForNSubstituteAssertion();
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DeleteAllSponsorshipsClearsAccount()
            {
                var processor = new SponsorshipProcessorFixture(Db);
                await processor.Subject.DeleteSponsorship(processor.SponsorshipData.First().Id);

                Assert.Empty(Db.NoDeleteSet<Sponsorship>());

                processor.PrivatePairService.Received(1).DeleteAccount().IgnoreAwaitForNSubstituteAssertion();
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}