using Autofac;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy
{
    public class StrategyModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Strategy>().As<IStrategy>();
        }
    }
}