using System;
using Autofac.Features.Indexed;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.Strategy
{
    public class StrategyFacts
    {
        readonly IExchangeService _ews = Substitute.For<IExchangeService>();
        readonly IExchangeService _graph = Substitute.For<IExchangeService>();

        [Fact]
        public void ShouldReturnRequestedExchangeService()
        {
            var serviceLocator = Substitute.For<IIndex<string, IExchangeService>>();
            serviceLocator[KnownImplementations.Ews].Returns(_ews);
            serviceLocator[KnownImplementations.Graph].Returns(_graph);

            var subject = new Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Strategy(serviceLocator);

            Assert.Equal(_ews, subject.GetService(Guid.NewGuid(), KnownImplementations.Ews));
            Assert.Equal(_graph, subject.GetService(Guid.NewGuid(), KnownImplementations.Graph));
        }

        [Fact]
        public void ShouldReturnEwsExchangeServiceByDefault()
        {
            var serviceLocator = Substitute.For<IIndex<string, IExchangeService>>();
            serviceLocator[KnownImplementations.Ews].Returns(_ews);
            serviceLocator[KnownImplementations.Graph].Returns(_graph);

            var subject = new Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Strategy(serviceLocator);

            Assert.Equal(_ews, subject.GetService(Guid.NewGuid()));
        }
    }
}