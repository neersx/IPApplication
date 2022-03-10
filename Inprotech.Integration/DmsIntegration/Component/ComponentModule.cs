using Autofac;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public class ComponentModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DmsSettingsProvider>().As<IDmsSettingsProvider>().InstancePerLifetimeScope();
            builder.RegisterType<CredentialsResolver>().As<ICredentialsResolver>().InstancePerLifetimeScope();
            builder.RegisterType<PersistedCredentialsResolver>().As<IPersistedCredentialsResolver>().InstancePerLifetimeScope();

            builder.RegisterType<CaseFolderCriteriaResolver>().As<ICaseFolderCriteriaResolver>();
            builder.RegisterType<NameFolderCriteriaResolver>().As<INameFolderCriteriaResolver>();

            builder.RegisterType<ConfiguredDms>().As<IConfiguredDms>();

            builder.RegisterType<CaseFolders>().As<ICaseDmsFolders>();
            builder.RegisterType<NameFolders>().As<INameDmsFolders>();

            builder.RegisterType<DmsDocuments>().As<IDmsDocuments>();

            builder.RegisterType<IManageDmsService>().Keyed<IDmsService>(KnownExternalSettings.IManage);
        }
    }
}