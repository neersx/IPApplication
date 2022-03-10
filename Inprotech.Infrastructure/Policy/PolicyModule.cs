using Autofac;

namespace Inprotech.Infrastructure.Policy
{
    public class PolicyModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SiteDateFormat>().As<ISiteDateFormat>();
            builder.RegisterType<SiteCurrencyFormat>().As<ISiteCurrencyFormat>();
        }
    }
}