using Autofac;

namespace Inprotech.Web.Configuration.Currencies
{
    public class CurrenciesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CurrenciesService>().As<ICurrencies>();
        }
    }
}
