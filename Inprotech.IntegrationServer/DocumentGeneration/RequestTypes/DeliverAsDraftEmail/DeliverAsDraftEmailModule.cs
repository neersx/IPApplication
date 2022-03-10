using Autofac;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail
{
    public class DeliverAsDraftEmailModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DraftEmail>().As<IDraftEmail>();
            builder.RegisterType<DraftEmailValidator>().As<IDraftEmailValidator>();
        }
    }
}