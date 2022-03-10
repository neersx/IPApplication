using Autofac;

namespace Inprotech.Integration.AutomaticDocketing
{
    public class AutomaticDocketingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DocumentEvents>().As<IDocumentEvents>();
            builder.RegisterType<DocumentMappings>().As<IDocumentMappings>();
            builder.RegisterType<RelevantEvents>().As<IRelevantEvents>();
            builder.RegisterType<ApplyUpdates>().As<IApplyUpdates>();
        }
    }
}
