using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Integration.IPPlatform.FileApp.Builders;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public class FileAppModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FileSettingsResolver>().As<IFileSettingsResolver>();
            builder.RegisterType<FileIntegrationEvent>().As<IFileIntegrationEvent>();
            builder.RegisterType<FileInstructAllowedCases>().As<IFileInstructAllowedCases>();
            builder.RegisterType<FileAgents>().As<IFileAgents>();
            builder.RegisterType<FilePctCaseBuilder>().As<IFileCaseBuilder>();
            builder.RegisterType<FileIntegration>().As<IFileIntegration>();
            builder.RegisterType<FileApiClient>().As<IFileApiClient>();
            builder.RegisterType<FileApi>().As<IFileApi>();
            builder.RegisterType<FileInstructInterface>().As<IFileInstructInterface>();
            builder.RegisterType<FileIntegrationStatus>().As<IFileIntegrationStatus>();
            builder.RegisterType<FileIntegrationExceptionHandlerFilter>().AsWebApiExceptionFilterFor<ApiController>();
        }
    }
}