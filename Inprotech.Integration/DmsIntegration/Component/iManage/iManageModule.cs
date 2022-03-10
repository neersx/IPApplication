using Autofac;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public class iManageModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WorkSiteManagerFactory>().As<IWorkSiteManagerFactory>();
            builder.RegisterType<WorkServerClient>().As<IWorkServerClient>();
            builder.RegisterType<AccessTokenManager>().As<IAccessTokenManager>().InstancePerLifetimeScope();

            builder.RegisterType<v8.WorkSiteManager>().Keyed<IWorkSiteManager>(Version.iManageCom);
            builder.RegisterType<v10.v1.WorkSiteManager>().Keyed<IWorkSiteManager>(Version.WorkApiV1);
            builder.RegisterType<v10.v2.WorkSiteManager>().Keyed<IWorkSiteManager>(Version.WorkApiV2);
        }
    }
}
