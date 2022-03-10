using Autofac;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public class DmsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<IManageSettingsManager>().As<IIMangeSettingsManager>();
            builder.RegisterType<SettingTester>().As<ISettingTester>();
            builder.RegisterType<SettingYamlMapper>().As<ISettingYamlMapper>();
            builder.RegisterType<DmsTestDocuments>().As<IDmsTestDocuments>();
        }
    }
}