using Autofac;

namespace Inprotech.Integration.Names.Consolidations
{
    public class ConsolidationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NameConsolidationStatusChecker>()
                   .As<INameConsolidationStatusChecker>();
            
            builder.RegisterType<FailedConsolidatingName>()
                   .As<IFailedConsolidatingName>();

            builder.RegisterType<NameConsolidationJob>()
                   .AsImplementedInterfaces()
                   .AsSelf();
        }
    }
}