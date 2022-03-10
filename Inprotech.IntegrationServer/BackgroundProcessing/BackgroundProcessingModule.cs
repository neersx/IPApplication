using Autofac;

namespace Inprotech.IntegrationServer.BackgroundProcessing
{
    public class BackgroundProcessingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Clock>().As<IClock>().SingleInstance();
        }
    }
}
