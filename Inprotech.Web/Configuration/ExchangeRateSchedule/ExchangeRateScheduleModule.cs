using Autofac;

namespace Inprotech.Web.Configuration.ExchangeRateSchedule
{
   public class ExchangeRateScheduleModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExchangeRateScheduleService>().As<IExchangeRateScheduleService>();
        }
    }
}
