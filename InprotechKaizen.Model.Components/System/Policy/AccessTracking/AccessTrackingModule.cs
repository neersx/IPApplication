using Autofac;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.System.Policy.AccessTracking
{
    public class AccessTrackingModule : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<RegisterAccess>().As<IRegisterAccess>();
        }
    }
}