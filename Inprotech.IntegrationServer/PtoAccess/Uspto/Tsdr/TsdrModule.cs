using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr
{
    public class TsdrModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TsdrSettings>().As<ITsdrSettings>();
            builder.RegisterType<TsdrClient>().As<ITsdrClient>();
            builder.RegisterType<TsdrDocumentClient>().As<ITsdrDocumentClient>();
        }
    }
}