using System.Configuration;
using System.Reflection;
using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using AutoMapper;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.Sso;
using Inprotech.Integration.Qos;
using Inprotech.Server.Security.AntiForgery;
using Inprotech.Web.FinancialReports.AgeDebtorAnalysis;
using Inprotech.Web.KeepOnTopNotes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Server
{
    public static class Dependencies
    {
        public static ContainerBuilder Configure(HttpConfiguration configuration)
        {
            var builder = new ContainerBuilder();

            // It's important to run this first.
            InfrastructureModule.Assemble(builder);

            var appIntegrationAssembly = typeof(StatusController).Assembly;
            var kaizenModelAssembly = typeof(Case).Assembly;
            var kaizenModelComponentAssembly = typeof(PolicingEngine).Assembly;
            var appWebAssembly = typeof(AgedDebtorsController).Assembly;
            var spAssembly = typeof(DbContextHelpers).Assembly;
            var integrationModelAssembly = typeof(InprotechKaizen.Model.Components.MainModule).Assembly;

            builder.RegisterAssemblyModules(Assembly.GetExecutingAssembly());
            builder.RegisterAssemblyModules(appIntegrationAssembly);
            builder.RegisterAssemblyModules(kaizenModelAssembly);
            builder.RegisterAssemblyModules(kaizenModelComponentAssembly);
            builder.RegisterAssemblyModules(spAssembly);
            builder.RegisterAssemblyModules(appWebAssembly);

            builder.RegisterApiControllers(appIntegrationAssembly);
            builder.RegisterApiControllers(appWebAssembly);
            builder.RegisterWebApiFilterProvider(configuration);

            builder.RegisterType<CsrfMiddleware>().AsSelf();
            builder.RegisterType<FormsAuthCookieMiddleware>().AsSelf();
            builder.RegisterType<GlobalExceptionHandlerMiddleware>().AsSelf();

            var mapperConfiguration = new MapperConfiguration(cfg =>
                                                              {
                                                                  cfg.AddProfiles(Assembly.GetExecutingAssembly());
                                                                  cfg.AddProfiles(kaizenModelAssembly);
                                                                  cfg.AddProfiles(appWebAssembly);
                                                                  cfg.AddProfiles(integrationModelAssembly);
                                                                  cfg.CreateMissingTypeMaps = true;
                                                              });
            var mapper = mapperConfiguration.CreateMapper();
            builder.Register(ctx => mapperConfiguration);
            builder.RegisterInstance(mapper);

            if (ConfigurationManager.AppSettings["AuthenticationMode"]?.Contains(AuthenticationModeKeys.Sso) == true)
            {
                SingleSignOnModule.Assemble(builder);
            }
            else
            {
                SingleSignOnModule.AssembleFake(builder);
            }

            var versionChecker = new InprotechVersionChecker(new Infrastructure.ConfigurationSettings());
            if (versionChecker.CheckMinimumVersion(16))
            {
                KotModule.LoadKot16Module(builder);
            }
            else
            {
                KotModule.LoadKot15Module(builder);
            }

            WebApiPipeline.Assemble(configuration, builder);

            return builder;
        }
    }
}