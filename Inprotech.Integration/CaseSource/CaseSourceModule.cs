using Autofac;
using Inprotech.Integration.CaseSource.Epo;
using Inprotech.Integration.CaseSource.FileApp;
using Inprotech.Integration.CaseSource.Innography;
using Inprotech.Integration.CaseSource.Uspto;

namespace Inprotech.Integration.CaseSource
{
    public class CaseSourceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EligibleCases>().As<IEligibleCases>();
            builder.RegisterType<NationalCasesResolver>().As<INationalCasesResolver>();
            builder.RegisterType<InnographyTrademarksRestrictor>().As<IInnographyTrademarksRestrictor>();
            builder.RegisterType<InnographyPatentsRestrictor>().As<IInnographyPatentsRestrictor>();
            builder.RegisterType<CasesForDownloadResolver>().AsSelf();

            builder.RegisterType<EpoSourceRestrictor>()
                   .Keyed<ISourceRestrictor>(DataSourceType.Epo);

            builder.RegisterType<TsdrSourceRestrictor>()
                   .Keyed<ISourceRestrictor>(DataSourceType.UsptoTsdr);

            builder.RegisterType<InnographySourceRestrictor>()
                   .Keyed<ISourceRestrictor>(DataSourceType.IpOneData);

            builder.RegisterType<FileAppSourceRestrictor>()
                   .Keyed<ISourceRestrictor>(DataSourceType.File);
        }
    }
}