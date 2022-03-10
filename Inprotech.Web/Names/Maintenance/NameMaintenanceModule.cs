using Autofac;

namespace Inprotech.Web.Names.Maintenance
{
    public class NameMaintenanceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<NameMaintenanceSave>().As<INameMaintenanceSave>();
        }
    }
}
