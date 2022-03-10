using Autofac;

namespace Inprotech.Web.Names.Consolidations
{
    public class ConsolidationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NameConsolidationStatusMonitor>().AsImplementedInterfaces();
            builder.RegisterType<NamesConsolidationValidator>().As<INamesConsolidationValidator>();
        }

    }
}