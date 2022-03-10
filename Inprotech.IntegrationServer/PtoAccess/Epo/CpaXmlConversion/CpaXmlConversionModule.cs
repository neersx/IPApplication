using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class CpaXmlConversionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlConverter>().As<ICpaXmlConverter>();
            builder.RegisterType<ProceduralStepsAndEventsConverter>().As<IProceduralStepsAndEventsConverter>();
            builder.RegisterType<NamesConverter>().As<INamesConverter>();
            builder.RegisterType<OfficialNumbersConverter>().As<IOfficialNumbersConverter>();
            builder.RegisterType<PriorityClaimsConverter>().As<IPriorityClaimsConverter>();
            builder.RegisterType<TitlesConverter>().As<ITitlesConverter>();

            builder.RegisterType<OpsProcedureOrEventsResolver>().As<IOpsProcedureOrEventsResolver>();
        }
    }
}
