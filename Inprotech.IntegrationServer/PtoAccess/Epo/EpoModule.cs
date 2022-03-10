using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    class EpoModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EpoSettings>().As<IEpoSettings>();
            builder.RegisterType<EpoAuthClient>().As<IEpoAuthClient>();
            builder.RegisterType<OpsClient>().As<IOpsClient>().InstancePerLifetimeScope();
            builder.RegisterType<AllDocumentsTabExtractor>().As<IAllDocumentsTabExtractor>();
            builder.RegisterType<EpRegisterClient>().As<IEpRegisterClient>();
        }
    }
}
