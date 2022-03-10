using System;
using Autofac;
using Inprotech.Setup.Core.Actions;
using Microsoft.Web.Administration;

namespace Inprotech.Setup.Core
{
    public class Module : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<FileSystem>().AsImplementedInterfaces();
            builder.RegisterType<IisAppInfoManager>().AsImplementedInterfaces().AsSelf();
            builder.Register<Func<ServerManager>>(c => () => new ServerManager());
            builder.Register<Func<string, IIisAppInfoManager>>(c =>
            {
                /* this registration is expected to be overriden by the DevOpsModule when launched from setup-cli */
                var context = c.Resolve<IComponentContext>();
                return x => context.Resolve<IisAppInfoManager>();
            });
            builder.RegisterType<SetupActionsAssemblyLoader>().AsImplementedInterfaces();
            builder.RegisterType<SetupRunner>().AsImplementedInterfaces();
            builder.RegisterType<SetupSettingsManager>().AsImplementedInterfaces();
            builder.RegisterType<WebConfigReader>().AsImplementedInterfaces();
            builder.RegisterType<WebConfigBackupReader>().AsImplementedInterfaces();
            builder.RegisterType<SetupWorkflow>().AsSelf();
            builder.RegisterType<SetupWorkflows>().AsImplementedInterfaces();
            builder.RegisterType<VersionManager>().AsImplementedInterfaces();
            builder.RegisterType<WebAppInfoManager>().AsImplementedInterfaces();
            builder.RegisterType<Validator>().AsImplementedInterfaces();
            builder.RegisterType<WebAppPairingService>().AsImplementedInterfaces();
            builder.RegisterType<AuthenticationMode>().AsImplementedInterfaces();
            builder.RegisterType<AvailableFeatures>().AsImplementedInterfaces();
            builder.RegisterType<WebAppConfigurationReader>().AsImplementedInterfaces();
            builder.RegisterType<ServiceManager>().AsImplementedInterfaces();
            builder.RegisterType<WebAppInfo>();
            builder.RegisterType<RecoveryManager>().AsImplementedInterfaces();
            builder.RegisterType<PersistingConfigManager>().As<IPersistingConfigManager>();
            builder.RegisterType<InprotechServerPersistingConfigManager>().As<IInprotechServerPersistingConfigManager>();
            builder.RegisterType<AdfsConfigPersistence>().As<IAdfsConfigPersistence>().UsingConstructor(typeof(string));
            builder.RegisterType<CryptoService>().As<ICryptoService>();
            builder.RegisterType<AppConfigReader>().As<IAppConfigReader>();
        }
    }
}