using Autofac;

namespace Inprotech.Integration.IPPlatform.FileApp.Validators
{
    public class ValidatorModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FilePctCaseValidator>()
                   .Keyed<IFileCaseValidator>(IpTypes.PatentPostPct);

            builder.RegisterType<FileDirectPatentCaseValidator>()
                   .Keyed<IFileCaseValidator>(IpTypes.DirectPatent);

            builder.RegisterType<FileTrademarkCaseValidator>()
                   .Keyed<IFileCaseValidator>(IpTypes.TrademarkDirect);
        }
    }
}