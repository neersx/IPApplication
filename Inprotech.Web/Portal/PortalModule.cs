using Autofac;

namespace Inprotech.Web.Portal
{
    public class PortalModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ToDoWebPartFormatter>().As<IWebPartFormatter>();
            builder.RegisterType<AppsMenu>().As<IAppsMenu>();
            builder.RegisterType<HelpLinkResolver>().As<IHelpLinkResolver>();
            builder.RegisterType<LinksResolver>().As<ILinksResolver>();
        }
    }
}