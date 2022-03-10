using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml
{
    class CpaXmlModules : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ConvertApplicationDetailsToCpaXml>().As<IConvertApplicationDetailsToCpaXml>();
            builder.RegisterType<CpaXmlConverter>().AsSelf();
            builder.RegisterType<CreateSenderDetails>().As<ICreateSenderDetails>();
        }
    }
}