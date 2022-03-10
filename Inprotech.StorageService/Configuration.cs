using System.Collections.Generic;
using System.Configuration;
using System.Data.Entity;
using System.Net;
using System.Net.Security;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using Autofac;
using Autofac.Features.Variance;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Instrumentation;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using Inprotech.StorageService.Storage;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Rest;
using Newtonsoft.Json.Serialization;

namespace Inprotech.StorageService
{
    public static class Configuration
    {
        static Configuration()
        {
            var builder = BuildContainer();

            Http = BuildHttp();
            builder.RegisterWebApiFilterProvider(Http);

            var component = new InprotechKaizen.Model.Components.Component();
            builder.RegisterInstance<IComponent>(component);

            var hostInfo = new HostInfo();
            builder.RegisterInstance(hostInfo);

            Container = builder.Build();

            Http.DependencyResolver = new AutofacWebApiDependencyResolver(Container);

            InitializeDatabases(Container, component, hostInfo);

            ConfigureCertificateValidation();

            ConfigureApplicationInsights(Container);

            ConfigureServiceClientTracing();

            Task.Run(async () =>
            {
                using (var scope = Container.BeginLifetimeScope())
                {
                    await scope.Resolve<IStorageCache>().RebuildEntireCache();
                }
            });
        }

        public static ILifetimeScope Container { get; }

        public static HttpConfiguration Http { get; }

        static void ConfigureServiceClientTracing()
        {
            ServiceClientTracing.IsEnabled = true;
            ServiceClientTracing.AddTracingInterceptor(new ServiceClientTracingInterceptor(new NLogBackgroundProcessLogger<ServiceClientTracingInterceptor>()));
        }

        static HttpConfiguration BuildHttp()
        {
            var config = new HttpConfiguration();
            config.MapHttpAttributeRoutes();
            config.Formatters.JsonFormatter.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            config.Services.Replace(typeof(IExceptionHandler), new DelegatingUnhandledExceptionHandler());

            return config;
        }

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

        static ContainerBuilder BuildContainer()
        {
            var builder = new ContainerBuilder();
            var appAssembly = Assembly.GetExecutingAssembly();
            var storageServiceAssembly = typeof(Integration.MainModule).Assembly;

            InfrastructureModule.Assemble(builder);

            builder.RegisterSource(new ContravariantRegistrationSource());
            builder.RegisterAssemblyModules(typeof(Case).Assembly);
            builder.RegisterAssemblyModules(typeof(PolicingEngine).Assembly);
            builder.RegisterAssemblyModules(appAssembly);
            builder.RegisterAssemblyModules(storageServiceAssembly);
            builder.RegisterApiControllers(storageServiceAssembly);
            builder.RegisterApiControllers(appAssembly);

            StorageServiceApiPipeline.Assemble(builder);
            return builder;
        }

        static void InitializeDatabases(ILifetimeScope container, InprotechKaizen.Model.Components.Component component, HostInfo hostInfo)
        {
            using (var scope = container.BeginLifetimeScope())
            {
                var inprotech = scope.Resolve<IDbContext>();
                Database.SetInitializer<SqlDbContext>(null);

                hostInfo.DbIdentifier = inprotech.GetDbIdentifier();
                component.Load(inprotech);

                /*
                    integration server should not cache site control or task security permissions as there
                    are no processes available to invalidate the cache 
                */
                foreach (var applicationCache in container.Resolve<IEnumerable<IDisableApplicationCache>>())
                    applicationCache.IsDisabled = true;

                Database.SetInitializer<IntegrationDbContext>(null);
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