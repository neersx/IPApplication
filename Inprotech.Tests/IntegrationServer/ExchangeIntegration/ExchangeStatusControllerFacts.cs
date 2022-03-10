using System;
using System.Threading.Tasks;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.Api;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{

    public class ExchangeStatusControllerFacts : FactBase
    {
        [Fact]
        public async Task VerifyStatusMethodWithGraph()
        {
            var userId = Fixture.Integer();
            var f = new ExchangeStatusControllerFixture(Db);
            var settings = new ExchangeConfigurationSettings
            {
                ExchangeGraph = new ExchangeGraph
                {
                    ClientId = Fixture.UniqueName(),
                    TenantId = Fixture.UniqueName()
                },
                ServiceType = KnownImplementations.Graph,
                IsReminderEnabled = true
            };

            f.ExchangeIntegrationSettings.ForEndpointTest().Returns(settings);
            f.ExchangeService.CheckStatus(settings, Arg.Any<string>(), userId).Returns(true);
            var result = await f.Subject.Status(userId);
            Assert.True(result);
            f.ExchangeIntegrationSettings.Received(1).ForEndpointTest();
            f.Strategy.Received(1).GetService(Arg.Any<Guid>(), settings.ServiceType);
        }

        [Fact]
        public async Task VerifyStatusMethodWithEws()
        {
            var f = new ExchangeStatusControllerFixture(Db);
            var settings = new ExchangeConfigurationSettings
            {
                Domain = Fixture.UniqueName(),
                Password = Fixture.RandomString(10),
                UserName = Fixture.UniqueName(),
                ServiceType = KnownImplementations.Ews,
                IsReminderEnabled = true
            };
            var user = new User(Fixture.UniqueName(), false) { IsValid = true }.In(Db);
            new SettingValues { SettingId = KnownSettingIds.ExchangeMailbox, CharacterValue = Fixture.RandomString(20), User = user }.In(Db);
            f.ExchangeIntegrationSettings.ForEndpointTest().Returns(settings);
            var result = await f.Subject.Status(user.Id);
            Assert.NotNull(result);
            f.Strategy.Received(1).GetService(Arg.Any<Guid>(), settings.ServiceType);
        }

        public class ExchangeStatusControllerFixture : IFixture<ExchangeStatusController>
        {
            public ExchangeStatusControllerFixture(InMemoryDbContext db)
            {
                ExchangeService = Substitute.For<IExchangeService>();
                Strategy = Substitute.For<IStrategy>();
                ExchangeIntegrationSettings = Substitute.For<IExchangeIntegrationSettings>();
                DbContext = db;
                Subject = new ExchangeStatusController(Strategy, ExchangeIntegrationSettings, DbContext);
                Strategy.GetService(Arg.Any<Guid>(), KnownImplementations.Graph).Returns(ExchangeService);
            }

            public IStrategy Strategy { get; set; }
            public IExchangeIntegrationSettings ExchangeIntegrationSettings { get; set; }
            public IDbContext DbContext { get; set; }
            public IExchangeService ExchangeService { get; set; }
            public ExchangeStatusController Subject { get; set; }
        }
    }
}