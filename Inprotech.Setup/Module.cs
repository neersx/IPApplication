using Autofac;
using Caliburn.Micro;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup
{
    public class Module : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<WindowManager>().As<IWindowManager>().SingleInstance();
            builder.RegisterType<EventAggregator>().As<IEventAggregator>().SingleInstance();
            builder.RegisterType<ShellViewModel>().As<IShell>().InstancePerLifetimeScope();
            builder.RegisterType<ValidationService>().AsImplementedInterfaces();
            builder.RegisterType<Service>().AsImplementedInterfaces();
            builder.RegisterType<WebAppInfoWrapper>();
            builder.RegisterType<Ports>().As<IPorts>();
            builder.RegisterType<ConfigurationSettingsReader>().As<IConfigurationSettingsReader>();
        }
    }
}