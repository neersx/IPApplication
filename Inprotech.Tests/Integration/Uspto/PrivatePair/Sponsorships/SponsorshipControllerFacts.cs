using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Uspto.PrivatePair.Sponsorships
{
    public class SponsorshipControllerFacts
    {
        public class SponsorshipControllerFixture : IFixture<SponsorshipController>
        {
            readonly InMemoryDbContext _db;

            public SponsorshipControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                SponsorshipProcessor = Substitute.For<ISponsorshipProcessor>();
                InnographyPrivatePairSettings = Substitute.For<IInnographyPrivatePairSettings>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                TaskSecurityProvider.HasAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload).Returns(true);

                HostInfo HostInfoResolver()
                {
                    return new HostInfo { DbIdentifier = "this-environment" };
                }

                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId).Returns(Fixture.String());

                Subject = new SponsorshipController(SponsorshipProcessor, TaskSecurityProvider, InnographyPrivatePairSettings, HostInfoResolver, SiteControlReader);
            }

            public ISponsorshipProcessor SponsorshipProcessor { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public IInnographyPrivatePairSettings InnographyPrivatePairSettings { get; }

            public ISiteControlReader SiteControlReader { get; }

            public SponsorshipModel[] SponsorshipModels => new[]
            {
                new SponsorshipModel {Id = 10001, SponsorName = "test1", SponsoredEmail = "test@test.com", CustomerNumbers = "1111,2222"},
                new SponsorshipModel {Id = 10002, SponsorName = "test2", SponsoredEmail = "test@test2.com", CustomerNumbers = "2222,3333"}
            };

            public SponsorshipController Subject { get; }
        }

        public class ControllerTests : FactBase
        {
            [Fact]
            public async Task DeleteSponsorships()
            {
                var controller = new SponsorshipControllerFixture(Db);
                controller.SponsorshipProcessor.DeleteSponsorship(Arg.Any<int>())
                          .Returns(Task.CompletedTask);

                var result = await controller.Subject.Delete(10001);

                Assert.NotNull(result);
            }

            [Fact]
            public async Task GetSponsorships()
            {
                var clientId = Fixture.String();
                var controller = new SponsorshipControllerFixture(Db);
                controller.SponsorshipProcessor.GetSponsorships().Returns(Task.FromResult(controller.SponsorshipModels.AsEnumerable()));
                controller.InnographyPrivatePairSettings.Resolve().Returns(new InnographyPrivatePairSetting
                {
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        ClientId = clientId,
                        ClientSecret = Fixture.String(),
                        QueueId = Fixture.String(),
                        QueueSecret = Fixture.String()
                    }
                });
                var result = await controller.Subject.Get();

                Assert.NotNull(result);
                Assert.Equal(true, result.CanScheduleDataDownload);
                Assert.Equal(2, ((IEnumerable<SponsorshipModel>)result.sponsorships).Count());
                Assert.Equal(clientId, result.ClientId);
                Assert.Equal(clientId, result.ClientId);
                Assert.Equal(false, result.missingBackgroundProcessLoginId);
            }

            [Fact]
            public async Task GetSponsorshipsReturnBackgroundProcessLogin()
            {
                var clientId = Fixture.String();
                var f = new SponsorshipControllerFixture(Db);
                f.SiteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId).Returns(string.Empty);
                f.InnographyPrivatePairSettings.Resolve().Returns(new InnographyPrivatePairSetting
                {
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        ClientId = clientId,
                        ClientSecret = Fixture.String(),
                        QueueId = Fixture.String(),
                        QueueSecret = Fixture.String()
                    }
                });

                var result = await f.Subject.Get();
                Assert.Equal(true, result.missingBackgroundProcessLoginId);
            }

            [Fact]
            public async Task UpdateSponsorships()
            {
                var controller = new SponsorshipControllerFixture(Db);
                controller.SponsorshipProcessor.UpdateSponsorship(Arg.Any<SponsorshipModel>())
                          .Returns(Task.FromResult(new ExecutionResult("error")));

                var model = new SponsorshipModel { Id = 10001, SponsorName = "test1", SponsoredEmail = "test@test.com", CustomerNumbers = "1111,2222" };
                var result = await controller.Subject.Update(model);

                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("error", result.Key);
            }

            [Fact]
            public async Task UpdateSponsorshipsDuplicate()
            {
                var controller = new SponsorshipControllerFixture(Db);
                controller.SponsorshipProcessor.UpdateSponsorship(Arg.Any<SponsorshipModel>())
                          .Returns(Task.FromResult(new ExecutionResult("error", "1111")));

                var model = new SponsorshipModel { Id = 10001, SponsorName = "test1", SponsoredEmail = "test@test.com", CustomerNumbers = "1111,2222" };
                var result = await controller.Subject.Update(model);

                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("error", result.Key);
                Assert.Equal("1111", result.Error);
            }

            [Fact]
            public async Task UpdateSponsorshipsSettings()
            {
                var controller = new SponsorshipControllerFixture(Db);
                controller.SponsorshipProcessor.UpdateOneTimeGlobalAccountSettings(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                          .Returns(Task.FromResult(new ExecutionResult("error")));

                var queueId = Fixture.String() + "   ";
                var model = new SponsorshipController.UsptoAccountSettingsUpdateModel { QueueId = queueId, QueueSecret = Fixture.String(), QueueUrl = Fixture.String() };
                var result = await controller.Subject.UpdateOneTimeGlobalAccountSettings(model);

                controller.SponsorshipProcessor.Received(1).UpdateOneTimeGlobalAccountSettings(model.QueueUrl, queueId.Trim(), model.QueueSecret).IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(result);
                Assert.False(result.IsSuccess);
                Assert.Equal("error", result.Key);
            }
        }
    }
}