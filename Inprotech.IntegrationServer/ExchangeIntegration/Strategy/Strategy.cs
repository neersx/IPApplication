using System;
using Autofac.Features.Indexed;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy
{
    public interface IStrategy
    {
        IExchangeService GetService(Guid guid, string key = null);
    }

    public class Strategy : IStrategy
    {
        readonly IIndex<string, IExchangeService> _services;

        public Strategy(IIndex<string, IExchangeService> services)
        {
            _services = services;
        }

        public IExchangeService GetService(Guid context, string key = null)
        {
            var service = _services[key ?? KnownImplementations.Ews];
            service?.SetLogContext(context);
            return service;
        }
    }
}