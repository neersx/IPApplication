using System;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class ExchangeQueueProcessorFacts
    {
        public class ProcessMethod : FactBase
        {
            [Fact]
            public void QuitsWhenDisabled()
            {
                var f = new ExchangeQueueProcessorFixture();
                f.SetupExternalSettings(Fixture.String(), Fixture.String(), Fixture.String(), false);
                f.Subject.Process();
                f.ExchangeIntegrationSettings.Received(1).Resolve();
                f.RequestQueue.DidNotReceive().NextRequest();
                f.RequestQueue.DidNotReceive().Completed(Arg.Any<long>());
                f.RequestQueue.DidNotReceive().Failed(Arg.Any<long>(), Arg.Any<string>(), Arg.Any<short>());
            }

            [Fact]
            public void ResolvesSettings()
            {
                var f = new ExchangeQueueProcessorFixture();
                f.SetupExternalSettings(Fixture.String(), Fixture.String(), Fixture.String(), true);
                f.Subject.Process();
                f.ExchangeIntegrationSettings.Received(1).Resolve();
            }
        }
    }

    public class ExchangeQueueProcessorFixture : IFixture<ExchangeQueueProcessor>
    {
        public ExchangeQueueProcessorFixture()
        {
            RequestQueue = Substitute.For<IRequestQueue>();
            BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<ExchangeQueueProcessor>>();
            ExchangeIntegrationSettings = Substitute.For<IExchangeIntegrationSettings>();
            Handlers = Substitute.For<IIndex<ExchangeRequestType, Func<IHandleExchangeMessage>>>();

            Subject = new ExchangeQueueProcessor(RequestQueue, BackgroundProcessLogger, ExchangeIntegrationSettings, Handlers);
        }

        public IIndex<ExchangeRequestType, Func<IHandleExchangeMessage>> Handlers { get; set; }

        public IExchangeIntegrationSettings ExchangeIntegrationSettings { get; set; }

        public IBackgroundProcessLogger<ExchangeQueueProcessor> BackgroundProcessLogger { get; set; }

        public IRequestQueue RequestQueue { get; set; }
        public ExchangeQueueProcessor Subject { get; set; }

        public void SetupExternalSettings(string server, string userName, string password, bool isEnabled, string domain = "dev")
        {
            ExchangeIntegrationSettings.Resolve().Returns(
                                                          new ExchangeConfigurationSettings
                                                          {
                                                              Server = server,
                                                              Domain = domain,
                                                              Password = password,
                                                              UserName = userName
                                                          });
        }
    }
}