using Autofac;
using Inprotech.Infrastructure.Localisation;

namespace Inprotech.IntegrationServer.Localisation
{
    public class LocalisationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackgroundProcessCultureResolver>().As<IPreferredCultureResolver>();
        }
    }
}