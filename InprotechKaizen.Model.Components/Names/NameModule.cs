using Autofac;

namespace InprotechKaizen.Model.Components.Names
{
    public class NameModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FormattedNameAddressTelecom>().As<IFormattedNameAddressTelecom>();
            builder.RegisterType<DisplayFormattedName>().As<IDisplayFormattedName>();
        }
    }
}