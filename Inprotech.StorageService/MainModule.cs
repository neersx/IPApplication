using System;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Contracts.Settings;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.IPPlatform.Sso;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Settings;
using Inprotech.StorageService.Storage;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Security;
using Module = Autofac.Module;

namespace Inprotech.StorageService
{
    public class MainModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            foreach (
                var m in
                Assembly.GetExecutingAssembly()
                        .GetTypes()
                        .Where(t => t.IsAssignableTo<IModelBuilder>() && t.IsClass && !t.IsAbstract))
                builder.RegisterType(m).As<IModelBuilder>();

            builder.RegisterType<AppSettingsProvider>().As<IAppSettingsProvider>();
            builder.RegisterType<AttachmentSettings>().As<IAttachmentSettings>();
            builder.RegisterType<FileHelpers>().As<IFileHelpers>();
            builder.RegisterType<InstancesInfo>().As<IInstancesInfo>();

            builder.Register(c => DateTime.Now);
            builder.RegisterType<MockCurrentOwinContext>().As<ICurrentOwinContext>();
            builder.RegisterType<WebSecurityContext>().As<ISecurityContext>();

            builder.Register(c => DateTime.Now);
            builder.RegisterType<ConfigSettings>().As<ISettings>();
            builder.RegisterType<GroupedConfigSettings>();

            builder.RegisterType<Storage.StorageService>().As<IStorageService>();
            builder.RegisterType<StorageCache>().As<IStorageCache>().SingleInstance();
            builder.RegisterType<RecursivelySearchForPathInCache>().As<IRecursivelySearchForPathInCache>();
            builder.RegisterType<ApplicationAccessToken>().As<IAccessTokenProvider>();
            
            builder.RegisterType<UnhandledExceptionLoggingFilter>().AsWebApiExceptionFilterFor<ApiController>();
            builder.Register<Func<HostApplication>>(c => () => new HostApplication("Inprotech.StorageService"));
        }
    }
}