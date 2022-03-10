using Autofac;
using InprotechKaizen.Model.Components.Names.Consolidation;

namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public class ConsolidationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ConsolidatorProvider>().As<IConsolidatorProvider>();
            builder.RegisterType<SingleNameConsolidation>().As<ISingleNameConsolidation>();
            builder.RegisterType<BatchedCommand>().As<IBatchedCommand>();

            builder.RegisterType<ConsolidationSettings>()
                   .As<IConsolidationSettings>()
                   .InstancePerLifetimeScope();
        }
    }
}