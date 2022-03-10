using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class CpaXmlConversionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlConverter>().As<ICpaXmlConverter>();
            builder.RegisterType<ApplicantsConverter>().As<IApplicantsConverter>();
            builder.RegisterType<CriticalDatesConverter>().As<ICriticalDatesConverter>();
            builder.RegisterType<GoodsServicesConverter>().As<IGoodsServicesConverter>();
            builder.RegisterType<OtherCriticalDetailsConverter>().As<IOtherCriticalDetailsConverter>();
            builder.RegisterType<EventsConverter>().As<IEventsConverter>();
        }
    }
}
