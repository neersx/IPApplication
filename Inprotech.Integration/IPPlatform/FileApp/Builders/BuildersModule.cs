using Autofac;
using Inprotech.Integration.IPPlatform.FileApp.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;

namespace Inprotech.Integration.IPPlatform.FileApp.Builders
{
    public class BuildersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FilePctCaseBuilder>()
                   .Keyed<IFileCaseBuilder>(IpTypes.PatentPostPct);

            builder.RegisterType<FileDirectPatentCaseBuilder>()
                   .Keyed<IFileCaseBuilder>(IpTypes.DirectPatent);

            builder.RegisterType<FileTrademarkCaseBuilder>()
                   .Keyed<IFileCaseBuilder>(IpTypes.TrademarkDirect);
            
            builder.RegisterType<FileTrademarkComparableClassProvider>()
                   .Keyed<IGoodsServicesProvider>("FILE");
        }
    }
}