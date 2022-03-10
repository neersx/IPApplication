using System;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Ews;
using InprotechKaizen.Model.Components.Integration.Exchange;
using Microsoft.Exchange.WebServices.Data;
using NSubstitute;
using NSubstitute.ReturnsExtensions;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.Strategy.Ews
{
    public class ExchangeWebServiceFacts
    {
        public class CheckStatusMethod : FactBase
        {
            [Fact]
            public async System.Threading.Tasks.Task ChecksConnectionUsingSettingsAndMailbox()
            {
                var userId = Fixture.Integer();
                var mailbox = Fixture.String("me@");
                var settings = new ExchangeConfigurationSettings
                {
                    Domain = "ABC",
                    Password = Fixture.String("password"),
                    Server = Fixture.String("myServer"),
                    UserName = Fixture.String("user")
                };
                var f = new ExchangeWebServiceFixture();
                f.Connection.Get(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<string>()).Returns(new ExchangeService());
                await f.Subject.CheckStatus(settings, mailbox, userId);
                f.Connection.Received(1).Get(settings, mailbox);
                f.Logger.Received(1).Information("Checking access to mailbox: " + mailbox);
            }

            [Fact]
            public async System.Threading.Tasks.Task ReturnsFalseAndLogsFailure()
            {
                var userId = Fixture.Integer();
                var mailbox = Fixture.String("me@");
                var settings = new ExchangeConfigurationSettings
                {
                    Domain = "ABC",
                    Password = Fixture.String("password"),
                    Server = Fixture.String("myServer"),
                    UserName = Fixture.String("user")
                };
                var f = new ExchangeWebServiceFixture();
                f.Connection.Get(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<string>()).ReturnsNull();
                await f.Subject.CheckStatus(settings, mailbox, userId);
                f.Connection.Received(1).Get(settings, mailbox);
                f.Logger.Received(1).Information("Checking access to mailbox: " + mailbox);
                f.Logger.Received(1).Exception(Arg.Any<Exception>());
            }
        }
    }

    public class ExchangeWebServiceFixture : IFixture<ExchangeWebService>
    {
        public ExchangeWebServiceFixture()
        {
            Connection = Substitute.For<IExchangeServiceConnection>();
            Logger = Substitute.For<IBackgroundProcessLogger<IExchangeService>>();
            Subject = new ExchangeWebService(Connection, Logger);
        }

        public IExchangeServiceConnection Connection { get; set; }
        public IBackgroundProcessLogger<IExchangeService> Logger { get; set; }
        public ExchangeWebService Subject { get; set; }
    }
}