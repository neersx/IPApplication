using Autofac;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Settings;

namespace InprotechKaizen.Model.Components.System.Settings
{
    public class SettingsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SettingsModelBuilder>().As<IModelBuilder>();
            builder.RegisterType<ConfigSettings>().As<IConfigSettings>();
            builder.RegisterType<GroupedConfig>().As<IGroupedConfig>();
            builder.RegisterType<ExternalSetting>().As<IExternalSettings>();
        }
    }
}