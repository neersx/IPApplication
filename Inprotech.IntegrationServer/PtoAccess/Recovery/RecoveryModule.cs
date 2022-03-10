using System;
using Autofac;
using Inprotech.Integration.CaseSource;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    class RecoveryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseResolverProvider>().AsImplementedInterfaces();
            builder.RegisterType<RecoveryCasesForDownloadResolver>().AsSelf();

            // wire up factory methods for each of the two cases for download resolvers
            builder.Register<Func<CasesForDownloadResolver>>(c =>
            {
                var context = c.Resolve<IComponentContext>();
                return () => context.Resolve<CasesForDownloadResolver>();
            });

            builder.Register<Func<RecoveryCasesForDownloadResolver>>(c =>
            {
                var context = c.Resolve<IComponentContext>();
                return () => context.Resolve<RecoveryCasesForDownloadResolver>();
            });

            builder.RegisterType<ReadScheduleSettings>().AsImplementedInterfaces();
            builder.RegisterType<RecoveryComplete>().AsSelf();
        }
    }
}
