using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public class PtoAccessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PtoAccessCase>().As<IPtoAccessCase>();
            builder.RegisterType<TitleExtractor>().As<ITitleExtractor>();
            builder.RegisterType<Throttler>().As<IThrottler>();
        }
    }
}
