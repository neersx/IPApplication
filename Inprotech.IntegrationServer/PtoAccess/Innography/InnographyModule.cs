using Autofac;
using Inprotech.Integration;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public class InnographyModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            
            builder.RegisterType<InnographyPatentsDataValidationClient>().As<IInnographyPatentsDataValidationClient>();
            builder.RegisterType<InnographyPatentsDataMatchingClient>().As<IInnographyPatentsDataMatchingClient>();
            builder.RegisterType<InnographyTrademarksValidationRequestMapping>().As<IInnographyTrademarksValidationRequestMapping>();
            builder.RegisterType<InnographyTradeMarksDataValidationClient>().As<IInnographyTradeMarksDataValidationClient>();
            builder.RegisterType<InnographyTrademarksDataMatchingClient>().As<IInnographyTradeMarksDataMatchingClient>();
            builder.RegisterType<InnographyTrademarksImageClient>().As<IInnographyTradeMarksImageClient>();
            builder.RegisterType<InnographyPatentsValidationRequestMapping>().As<IInnographyPatentsValidationRequestMapping>();
            builder.RegisterType<EligiblePatentItems>().As<IEligiblePatentItems>();
            builder.RegisterType<EligibleTrademarkItems>().As<IEligibleTrademarkItems>();
            builder.RegisterType<InnographyImageDownloadHandler>()
                   .Keyed<ISourceImageDownloadHandler>(DataSourceType.IpOneData);
        }
    }
}