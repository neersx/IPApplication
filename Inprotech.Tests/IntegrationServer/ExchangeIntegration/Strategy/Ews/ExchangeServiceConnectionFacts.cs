using System;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Ews;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.Strategy.Ews
{
    public class ExchangeServiceConnectionFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ImpersonatesMailboxOwner()
            {
                var mailbox = Fixture.String("Mailbox@");
                var f = new ExchangeServiceConnectionFixture();

                var r = f.Subject.Get(new ExchangeConfigurationSettings {Server = Fixture.String("https://")}, mailbox);
                Assert.Equal(mailbox, r.ImpersonatedUserId.Id);
            }

            [Fact]
            public void SetsMailboxHeader()
            {
                var mailbox = Fixture.String("Mailbox@");
                var f = new ExchangeServiceConnectionFixture();

                var r = f.Subject.Get(new ExchangeConfigurationSettings {Server = Fixture.String("https://")}, mailbox);
                Assert.Equal(mailbox, r.ImpersonatedUserId.Id);
                Assert.Equal(mailbox, r.HttpHeaders.Single(_ => _.Key == "X-AnchorMailbox").Value);
            }
        }
    }

    public class ExchangeServiceConnectionFixture : IFixture<ExchangeServiceConnection>
    {
        public IGroupedConfig GroupedConfig { get; } = Substitute.For<IGroupedConfig>();

        Func<string, IGroupedConfig> Config => (x) => GroupedConfig;

        public ExchangeServiceConnectionFixture()
        {
            var logger = Substitute.For<ILogger<ExchangeServiceConnection>>();

            Subject = new ExchangeServiceConnection(Config, Fixture.Today, logger);
        }

        public ExchangeServiceConnection Subject { get; set; }
    }
}