using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.CpaXmlConversion
{
    public class CpaXmlConversionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlConverter>().As<ICpaXmlConverter>();
        }
    }
}