using Autofac;

namespace Inprotech.Web.Cases.Maintenance
{
    public class CaseMaintenanceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseMaintenanceSave>().As<ICaseMaintenanceSave>();
        }
    }
}
