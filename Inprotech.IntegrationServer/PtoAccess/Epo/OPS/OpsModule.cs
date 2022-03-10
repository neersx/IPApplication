using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.OPS
{
    public class OpsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<OpsData>().As<IOpsData>();
        }
    }
}
