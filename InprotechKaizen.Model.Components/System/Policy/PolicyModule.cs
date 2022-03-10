using Autofac;
using Inprotech.Infrastructure.Policy;

namespace InprotechKaizen.Model.Components.System.Policy
{
    public class PolicyModule : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<AuditTrail>().As<IAuditTrail>();
        }
    }
}
