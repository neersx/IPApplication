using Autofac;

namespace Inprotech.Web.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExchangeRateVariations>().As<IExchangeRateVariations>();
        }
    }
}
