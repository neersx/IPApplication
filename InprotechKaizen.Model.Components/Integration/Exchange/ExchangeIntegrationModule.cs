using Autofac;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public class ExchangeIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExchangeIntegrationQueue>().As<IExchangeIntegrationQueue>();
            builder.RegisterType<ExchangeSiteSettingsResolver>().As<IExchangeSiteSettingsResolver>();
        }
    }
}