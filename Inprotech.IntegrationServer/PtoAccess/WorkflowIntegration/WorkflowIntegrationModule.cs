using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration
{
    public class WorkflowIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DocumentEvents>().AsSelf();
        }
    }
}
