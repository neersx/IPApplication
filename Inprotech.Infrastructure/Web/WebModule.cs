using Autofac;

namespace Inprotech.Infrastructure.Web
{
    public class WebModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SearchBar>().As<ISearchBar>().InstancePerRequest();
            builder.RegisterType<AccessPermissions>().As<IAccessPermissions>().InstancePerRequest();
            builder.RegisterType<ViewInitialiserAttribute>().PropertiesAutowired();
            builder.RegisterType<RequestContext>().AsImplementedInterfaces().InstancePerRequest();
            builder.RegisterType<Menu>().As<IMenu>();
            builder.RegisterType<CurrentRequestLifetimeScope>().As<ICurrentRequestLifetimeScope>();
            builder.RegisterType<CommonQueryService>().As<ICommonQueryService>();
            builder.RegisterType<ApiClient>().As<IApiClient>();
        }
    }
}