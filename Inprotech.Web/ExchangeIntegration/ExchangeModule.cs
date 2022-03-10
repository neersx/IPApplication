using Autofac;
using Inprotech.Integration;

namespace Inprotech.Web.ExchangeIntegration
{
    public class ExchangeModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<RequestQueueItemModel>().As<IRequestQueueItemModel>();
            builder.RegisterType<ExchangePairedInstanceRequestValidator>().AsImplementedInterfaces();
            builder.RegisterType<ExchangeIntegrationController>().AsSelf();
            builder.RegisterType<AppSettings>().As<IAppSettings>();
            builder.RegisterType<ExchangeSettingsResolver>().As<IExchangeSettingsResolver>();
        }
    }
}