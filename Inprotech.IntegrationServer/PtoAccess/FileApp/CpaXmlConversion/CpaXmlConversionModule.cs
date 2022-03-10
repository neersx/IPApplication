using Autofac;
using Inprotech.Integration.IPPlatform.FileApp;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class CpaXmlConversionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlConverter>().As<ICpaXmlConverter>();

            builder.RegisterType<PctApplicationDetails>()
                   .Keyed<IApplicationDetailsConverter>(IpTypes.PatentPostPct);

            builder.RegisterType<DirectPatentApplicationDetails>()
                   .Keyed<IApplicationDetailsConverter>(IpTypes.DirectPatent);

            builder.RegisterType<TrademarkApplicationDetails>()
                   .Keyed<IApplicationDetailsConverter>(IpTypes.TrademarkDirect);
        }
    }
}