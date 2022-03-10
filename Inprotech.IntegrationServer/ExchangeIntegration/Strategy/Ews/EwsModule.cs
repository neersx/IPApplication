using Autofac;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Ews
{
    public class EwsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExchangeServiceConnection>()
                   .As<IExchangeServiceConnection>();

            builder.RegisterType<ExchangeWebService>()
                   .Keyed<IExchangeService>(KnownImplementations.Ews);
        }
    }
}