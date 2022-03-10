using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Security;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using Autofac;
using Autofac.Features.Variance;
using Autofac.Integration.WebApi;
using AutoMapper;
using Dependable;
using Dependable.Extensions.Dependencies.Autofac;
using Dependable.Extensions.Persistence.Sql;
using Dependable.Tracking;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Instrumentation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.ThirdPartyLicensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration;
using Inprotech.Integration.Accounting.Billing;
using Inprotech.Integration.Accounting.Time.Timers;
using Inprotech.Integration.Diagnostics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.IPPlatform.Sso;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Reports.Engine;
using Inprotech.Integration.Search.Export;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Integration.Uspto.PrivatePair.Certificates;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Names.Consolidation;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Rest;
using Newtonsoft.Json.Serialization;
using Case = InprotechKaizen.Model.Cases.Case;
using DueSchedule = Inprotech.IntegrationServer.PtoAccess.Innography.Activities.DueSchedule;
using EnsureScheduleValid = Inprotech.IntegrationServer.PtoAccess.Epo.Activities.EnsureScheduleValid;
using IExceptionLogger = Dependable.Diagnostics.IExceptionLogger;

namespace Inprotech.IntegrationServer
{
    public static class Configuration
    {
        static Configuration()
        {
            var builder = BuildContainer();

            Http = BuildHttp();
            builder.RegisterWebApiFilterProvider(Http);

            var component = new Component();
            builder.RegisterInstance<IComponent>(component);

            var authSettings = new AuthSettings();
            builder.RegisterInstance<IAuthSettings>(authSettings);
            if (!string.IsNullOrEmpty(ConfigurationManager.AppSettings["e2e"]))
            {
                builder.Register(x =>
                {
                    var g = x.Resolve<Func<string, IGroupedConfig>>();
                    var c = x.Resolve<IConfigurationSettings>();
                    var l = x.Resolve<ILogger<QaAuthSettings>>();
                    return new QaAuthSettings(g, c, l, authSettings);
                });
            }

            var hostInfo = new HostInfo();
            builder.RegisterInstance(hostInfo);

            Container = builder.Build();

            Http.DependencyResolver = new AutofacWebApiDependencyResolver(Container);

            InitializeDatabases(Container, component, hostInfo, authSettings);

            ConfigureCertificateValidation();

            ConfigureApplicationInsights(Container);

            ConfigureGoogleAnalyticsIdentifier(Container);

            ConfigureServiceClientTracing();

            ConfigureThirdPartyLicensing();
        }

        public static void StartDependableWorkflowEngine()
        {
            Scheduler = BuildScheduler(Container);

            Scheduler.Start();
        }

        public static ILifetimeScope Container { get; }

        public static HttpConfiguration Http { get; }

        public static IScheduler Scheduler { get; set; }

        static void ConfigureApplicationInsights(ILifetimeScope container)
        {
            using (var scope = container.BeginLifetimeScope())
            {
                var appInsights = scope.Resolve<IApplicationInsights>();
                appInsights.Configure(instrumentationSettings =>
                {
                    if (!string.IsNullOrWhiteSpace(instrumentationSettings?.Key))
                    {
                        TelemetryConfiguration.Active.InstrumentationKey = instrumentationSettings.Key;
                    }
                    else
                    {
                        TelemetryConfiguration.Active.DisableTelemetry = true;
                    }
                });
            }
        }

        static void ConfigureGoogleAnalyticsIdentifier(ILifetimeScope container)
        {
            using (var scope = container.BeginLifetimeScope())
            {
                var identifier = scope.Resolve<IAnalyticsIdentifierResolver>();
                var key = scope.Resolve<AnalyticsRuntimeSettings>();
                key.IdentifierKey = identifier.Resolve().Result;
            }
        }

        static void ConfigureThirdPartyLicensing()
        {
            using (var scope = Container.BeginLifetimeScope())
            {
                var thirdPartyLicensing = scope.Resolve<IThirdPartyLicensing>();
                thirdPartyLicensing.Configure();
            }
        }

        static void ConfigureServiceClientTracing()
        {
            ServiceClientTracing.IsEnabled = true;
            ServiceClientTracing.AddTracingInterceptor(new ServiceClientTracingInterceptor(new NLogBackgroundProcessLogger<ServiceClientTracingInterceptor>()));
        }

        public static IScheduler BuildScheduler(ILifetimeScope container)
        {
            DependableSettings settings;
            using (var scope = container.BeginLifetimeScope())
            {
                var dependableSettingsProvider = scope.Resolve<IDependableSettings>();
                settings = dependableSettingsProvider.GetSettings();
            }

            var logger = container.Resolve<IExceptionLogger>();

            return new DependableConfiguration()
                   .SetRetryTimerInterval(settings.RetryTimerInterval)
                   .SetDefaultRetryCount(settings.RetryCount)
                   .SetDefaultRetryDelay(settings.RetryDelay)
                   .SetDefaultMaxQueueLength(500000)
                   .UseAutofacDependencyResolver(container)
                   .UseSqlPersistenceProvider("InprotechIntegration", ConfigurationManager.AppSettings["InstanceName"])
                   .UseConsoleEventLogger(EventType.JobStatusChanged | EventType.Exception)
                   .UseExceptionLogger(logger)
                   .Activity<PtoAccess.Uspto.PrivatePair.Activities.DueSchedule>(c => c.WithRetryCount(0))
                   .Activity<PtoAccess.Uspto.PrivatePair.MessageQueueMonitor.IDequeueUsptoMessagesJob>(c => c.WithMaxWorkers(1).WithRetryCount(0))
                   .Activity<PtoAccess.Uspto.PrivatePair.MessageQueueMonitor.IStoreDequeuedMessagesFromFileJob>(c => c.WithMaxWorkers(1))
                   .Activity<PtoAccess.Uspto.Tsdr.Activities.DueSchedule>(c => c.WithRetryCount(0))
                   .Activity<PtoAccess.Epo.Activities.DueSchedule>(c => c.WithRetryCount(0))
                   .Activity<PtoAccess.FileApp.Activities.DueSchedule>(c => c.WithRetryCount(0))
                   .Activity<PtoAccess.Uspto.Tsdr.Activities.EnsureScheduleValid>(c => c.WithRetryCount(1))
                   .Activity<DueSchedule>(c => c.WithRetryCount(0))
                   .Activity<BackgroundIdentityConfiguration>(c => c.WithRetryCount(1))
                   .Activity<EnsureScheduleValid>(c => c.WithRetryCount(1))
                   .Activity<RecoveryComplete>(c => c.WithRetryCount(3))
                   .Activity<IApplicationDownloadFailed>(p => p.WithRetryCount(1))
                   .Activity<IConvertApplicationDetailsToCpaXml>(c => c.WithMaxWorkers(2))
                   .Activity<IMoveDocumentToDmsFolder>(c => c.WithRetryDelay(settings.DmsRetryDelay))
                   .Activity<ILoadCaseAndSendDocumentToDms>(c => c.WithRetryDelay(settings.DmsRetryDelay))
                   .Activity<ICleanScheduleExecutionSessions>(c => c.WithMaxWorkers(1))
                   .Activity<ICleanUpFolders>(c => c.WithMaxWorkers(1))
                   .Activity<ISingleNameConsolidation>(c => c.WithMaxWorkers(1).WithRetryCount(0))
                   .Activity<IUpdateScheduleExecutionStatus>(c => c.WithMaxWorkers(1))
                   .Activity<ExpiringLicenses>(c => c.WithRetryCount(1))
                   .Activity<DownloadedCase>(c => c.WithMaxWorkers(5)
                                                   .WithRetryDelay(TimeSpan.FromSeconds(1)))
                   .Activity<RuntimeEvents>(c => c.WithMaxWorkers(1))
                   .Activity<DetailsUnavailable>(c => c.WithMaxWorkers(2))
                   .Activity<IMessages>(c => c.WithMaxWorkers(5))
                   .Activity<ExpiringPassword>(c => c.WithRetryCount(1))
                   .Activity<ExportExecutionEngine>(c => c.WithMaxWorkers(3).WithRetryCount(0))
                   .Activity<BillProduction>(c => c.WithMaxWorkers(3).WithRetryCount(0))
                   .Activity<ReportEngine>(c => c.WithMaxWorkers(3).WithRetryCount(0))
                   .Activity<StopRunningTimers>(c => c.WithRetryCount(1))
                   .CreateScheduler();
        }

        static HttpConfiguration BuildHttp()
        {
            var config = new HttpConfiguration();
            config.MapHttpAttributeRoutes();
            config.Formatters.JsonFormatter.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            config.Formatters.XmlFormatter.UseXmlSerializer = true;
            config.Formatters.XmlFormatter.WriterSettings.OmitXmlDeclaration = false;

            config.Services.Replace(typeof(IExceptionHandler), new UnhandledWebApiExceptionHandler());

            return config;
        }

        static ContainerBuilder BuildContainer()
        {
            var builder = new ContainerBuilder();
            var appAssembly = Assembly.GetExecutingAssembly();
            var appIntegrationAssembly = typeof(Integration.MainModule).Assembly;
            var kaizenModelAssembly = typeof(Case).Assembly;
            var kaizenModelComponentAssembly = typeof(PolicingEngine).Assembly;
            InfrastructureModule.Assemble(builder);

            builder.RegisterSource(new ContravariantRegistrationSource());
            builder.RegisterAssemblyModules(kaizenModelAssembly);
            builder.RegisterAssemblyModules(kaizenModelComponentAssembly);
            builder.RegisterAssemblyModules(appAssembly);
            builder.RegisterAssemblyModules(appIntegrationAssembly);
            builder.RegisterApiControllers(appIntegrationAssembly);
            builder.RegisterApiControllers(appAssembly);

            var mapperConfiguration = new MapperConfiguration(cfg =>
            {
                cfg.AddProfiles(Assembly.GetExecutingAssembly());
                cfg.AddProfiles(kaizenModelAssembly);
                cfg.AddProfiles(kaizenModelComponentAssembly);
                cfg.CreateMissingTypeMaps = true;
            });

            var mapper = mapperConfiguration.CreateMapper();
            builder.Register(ctx => mapperConfiguration);
            builder.RegisterInstance(mapper);

            IntegrationApiPipeline.Assemble(builder);

            if (ConfigurationManager.AppSettings["AuthenticationMode"]?.Contains(AuthenticationModeKeys.Sso) == true)
            {
                SingleSignOnModule.Assemble(builder);
            }
            else
            {
                SingleSignOnModule.AssembleFake(builder);
            }

            return builder;
        }

        static void InitializeDatabases(ILifetimeScope container, Component component, HostInfo hostInfo, AuthSettings authSettings)
        {
            using (var scope = container.BeginLifetimeScope())
            {
                var inprotech = scope.Resolve<IDbContext>();
                Database.SetInitializer<SqlDbContext>(null);

                hostInfo.DbIdentifier = inprotech.GetDbIdentifier();
                component.Load(inprotech);

                var groupedConfig = scope.Resolve<Func<string, IGroupedConfig>>();
                var appConfigurationSettings = scope.Resolve<IConfigurationSettings>();
                AuthSettingsResolver.Resolve(authSettings, groupedConfig, appConfigurationSettings);

                /*
                    integration server should not cache site control, authorization results or task security permissions as there
                    are no processes available to invalidate the cache 
                */
                foreach (var applicationCache in container.Resolve<IEnumerable<IDisableApplicationCache>>())
                    applicationCache.IsDisabled = true;

                var usptoInt = scope.Resolve<IRepository>();
                Database.SetInitializer<IntegrationDbContext>(null);

                var _ = usptoInt.Set<Certificate>().FirstOrDefault();
            }
        }

        static void ConfigureCertificateValidation()
        {
            bool.TryParse(ConfigurationManager.AppSettings["BypassSslCertificateCheck"], out var bypassCertificateCheck);

            if (bypassCertificateCheck)
            {
                ServicePointManager.ServerCertificateValidationCallback = CertificateValidationCallBack;
            }
        }

        static bool CertificateValidationCallBack(
            object sender,
            X509Certificate certificate,
            X509Chain chain,
            SslPolicyErrors sslPolicyErrors)
        {
            if (sslPolicyErrors == SslPolicyErrors.None)
            {
                return true;
            }

            if ((sslPolicyErrors & SslPolicyErrors.RemoteCertificateChainErrors) == 0)
            {
                return false;
            }

            if (chain?.ChainStatus == null) return true;

            foreach (var status in chain.ChainStatus)
            {
                if (certificate.Subject == certificate.Issuer &&
                    status.Status == X509ChainStatusFlags.UntrustedRoot)
                {
                    continue;
                }

                if (status.Status != X509ChainStatusFlags.NoError)
                {
                    return false;
                }
            }

            return true;
        }
    }
}