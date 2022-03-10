using System;
using System.Linq;
using System.Reflection;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Contracts.Settings;
using Inprotech.Infrastructure;
using Inprotech.Integration.Documents;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Settings;
using Module = Autofac.Module;

namespace Inprotech.Integration
{
    public class MainModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            foreach(
                var m in
                    Assembly.GetExecutingAssembly()
                            .GetTypes()
                            .Where(t => t.IsAssignableTo<IModelBuilder>() && t.IsClass && !t.IsAbstract))
            {
                builder.RegisterType(m).As<IModelBuilder>();
            }

            builder.RegisterType<AppSettingsProvider>().As<IAppSettingsProvider>();
            builder.RegisterType<DefaultFileNameFormatter>().As<IDefaultFileNameFormatter>();
            builder.RegisterType<DocumentImporter>().As<IDocumentImporter>();
            builder.RegisterType<UpdatedEventsLoader>().As<IUpdatedEventsLoader>();
            builder.RegisterType<NameAttributeLoader>().As<INameAttributeLoader>();
            builder.RegisterType<CrmValidator>().As<ICrmValidator>();
            builder.RegisterType<CrmContactProcessor>().As<ICrmContactProcessor>();
            builder.RegisterType<ContactActivityProcessor>().As<IContactActivityProcessor>();
            builder.Register(c => DateTime.Now);
            builder.RegisterType<ConfigSettings>().As<ISettings>();
            builder.RegisterType<GroupedConfigSettings>();
            builder.RegisterType<DmsIntegrationSettings>().AsImplementedInterfaces();
            builder.RegisterType<ConfigureJob>().AsImplementedInterfaces();
            builder.RegisterType<DocumentLoader>().AsImplementedInterfaces();
            builder.RegisterType<JobStatePersister>().AsImplementedInterfaces();

            builder.RegisterType<EpoIntegrationSettings>().As<IEpoIntegrationSettings>();
            builder.RegisterType<TsdrIntegrationSettings>().As<ITsdrIntegrationSettings>();
            builder.RegisterType<InstancesInfo>().As<IInstancesInfo>();
        }
    }
}