using Autofac;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public class LocalisationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<LocalisationResources>().As<ILocalisationResources>();
            builder.RegisterType<LocalisationResourcesResponseEnricher>().As<IResponseEnricher>();
            builder.RegisterType<Resources>().As<IResources>();
            builder.RegisterType<ResourceLoader>().As<IResourceLoader>();
            builder.RegisterType<KendoLocale>().As<IKendoLocale>();
        }
    }
}
