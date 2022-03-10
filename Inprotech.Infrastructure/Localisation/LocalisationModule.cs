using Autofac;

namespace Inprotech.Infrastructure.Localisation
{
    public class LocalisationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ResolvedCultureTranslations>().As<IResolvedCultureTranslations>();
        }
    }
}
