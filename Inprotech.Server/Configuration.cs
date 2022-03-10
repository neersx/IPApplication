using System;
using System.Configuration;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using ApplicationInsights.OwinExtensions;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.ConfigurationSetting;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Instrumentation;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Inprotech.Infrastructure.ThirdPartyLicensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Server.Extensibility;
using Inprotech.Server.Security.AntiForgery;
using Inprotech.Web.Translation;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using Microsoft.Owin.FileSystems;
using Microsoft.Owin.StaticFiles;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Owin;
using ConfigurationSettings = Inprotech.Infrastructure.ConfigurationSettings;

namespace Inprotech.Server
{
    [SuppressMessage("Microsoft.Naming", "CA1724:TypeNamesShouldNotMatchNamespaces")]
    [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
    public class Configuration
    {
        const string Root = "client";

        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        public Configuration()
        {
            var config = new HttpConfiguration();

            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute("InprotechApi",
                                       "api/{controller}/{action}/{id}",
                                       new
                                       {
                                           action = RouteParameter.Optional,
                                           id = RouteParameter.Optional
                                       });

            config.Routes.MapHttpRoute("Default",
                                       "{controller}/{action}/{id}",
                                       new
                                       {
                                           action = "Index",
                                           id = RouteParameter.Optional
                                       });

            config.Formatters.Remove(config.Formatters.XmlFormatter);
            config.Formatters.JsonFormatter.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            config.Formatters.JsonFormatter.SerializerSettings.Converters.Add(new CamelCaseStringEnumConverter());
            config.Formatters.JsonFormatter.SerializerSettings.Converters.Add(new RoundedTimeSpanConverter());

            config.Services.Replace(typeof(IExceptionHandler), new DelegatingUnhandledExceptionHandler());

            var builder = Dependencies.Configure(config);

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

            var translationDir = Path.Combine(Root, @"condor\localisation\translations");
            builder.Register(x => new StaticTranslator(translationDir)).As<IStaticTranslator>().SingleInstance();

            var container = builder.Build();

            InitializeDatabases(container, component, hostInfo, authSettings);

            ConfigureQaSettings(container);

            config.DependencyResolver = new AutofacWebApiDependencyResolver(container);

            ConfigureCertificateValidation();

            ConfigureGoogleAnalyticsIdentifier(container);

            Http = config;
            Container = container;
        }

        public ILifetimeScope Container { get; }

        public HttpConfiguration Http { get; }

        public void Config(IAppBuilder appBuilder)
        {
            if (appBuilder == null) throw new ArgumentNullException(nameof(appBuilder));

            ConfigureCallContextAccessor(appBuilder);

            ConfigureApplicationInsights(appBuilder);

            ConfigureSignalR(appBuilder);

            appBuilder.UseAutofacLifetimeScopeInjector(Container);

            appBuilder.UseMiddlewareFromContainer<GlobalExceptionHandlerMiddleware>();

            ConfigureAuthentication(appBuilder);

            ConfigureStaticFiles(appBuilder);

            ConfigureApiResponseCompression(appBuilder);

            ConfigureAntiForgerySecurity(appBuilder);

            appBuilder.UseAutofacMiddleware(Container);

            ConfigureResponseHeaders(appBuilder);

            appBuilder.UseWebApi(Http);

            ConfigureNtlmForBackwardCompatibility(appBuilder);

            appBuilder.RestoreOperationIdContext();

            ConfigureServiceClientTracing();

            ConfigureThirdPartyLicensing();
        }

        void ConfigureApiResponseCompression(IAppBuilder appBuilder)
        {
            var gzipSection = ConfigurationManager.GetSection("gzipCompression") as GzipCompressionSection;

            if (gzipSection == null || !gzipSection.Enabled) return;

            var settings = new CompressionSettings(
                                                   serverPath: string.Empty,
                                                   allowUnknonwnFiletypes: false,
                                                   allowRootDirectories: false,
                                                   cacheExpireTime: Microsoft.FSharp.Core.FSharpOption<DateTimeOffset>.None,
                                                   allowedExtensionAndMimeTypes:
                                                   new[]
                                                   {
                                                       Tuple.Create(".json", "application/json")
                                                   },
                                                   minimumSizeToCompress: gzipSection.MinimumSizeToCompress,
                                                   deflateDisabled: true
                                                  );

            appBuilder.UseCompressionModule(settings);
        }

        void ConfigureThirdPartyLicensing()
        {
            using (var scope = Container.BeginLifetimeScope())
            {
                var thirdPartyLicensing = scope.Resolve<IThirdPartyLicensing>();
                thirdPartyLicensing.Configure();
            }
        }

        void ConfigureApplicationInsights(IAppBuilder appBuilder)
        {
            using (var scope = Container.BeginLifetimeScope())
            {
                var appInsights = scope.Resolve<IApplicationInsights>();
                appInsights.Configure(instrumentationSettings =>
                {
                    if (!string.IsNullOrWhiteSpace(instrumentationSettings?.Key))
                    {
                        TelemetryConfiguration.Active.InstrumentationKey = instrumentationSettings.Key;

                        appBuilder.UseApplicationInsights();
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

        static void ConfigureServiceClientTracing()
        {
            ServiceClientTracing.IsEnabled = true;
            ServiceClientTracing.AddTracingInterceptor(new ServiceClientTracingInterceptor(new NLogBackgroundProcessLogger<ServiceClientTracingInterceptor>()));
        }

        static void ConfigureCallContextAccessor(IAppBuilder appBuilder)
        {
            appBuilder.Use(async (context, next) =>
            {
                OwinContextAccessor.OwinContext.Value = context;
                await next();
            });
        }

        static void ConfigureAntiForgerySecurity(IAppBuilder appBuilder)
        {
            CsrfConfigOptions.IsEnabled = CheckMinimumInprotechVersion(12, 1);
            CsrfConfigOptions.Path = ConfigurationManager.AppSettings[KnownAppSettingsKeys.SessionCookiePath].NullIfEmptyOrWhitespace();
            CsrfConfigOptions.Domain = ConfigurationManager.AppSettings[KnownAppSettingsKeys.SessionCookieDomain].NullIfEmptyOrWhitespace();

            appBuilder.UseMiddlewareFromContainer<CsrfMiddleware>();
        }

        static void ConfigureResponseHeaders(IAppBuilder appBuilder)
        {
            appBuilder.UseXfo(options => options.SameOrigin());
            appBuilder.UseXXssProtection(options => options.EnabledWithBlockMode());
            appBuilder.UseXContentTypeOptions();
            appBuilder.UseCsp(options => options
                                  .DefaultSources(s => s.Self()));

            var hstsEnabled = Convert.ToBoolean(ConfigurationManager.AppSettings[KnownAppSettingsKeys.EnableHsts].NullIfEmptyOrWhitespace());
            if (hstsEnabled)
            {
                var maxAge = Convert.ToInt32(ConfigurationManager.AppSettings[KnownAppSettingsKeys.HstsMaxAge].NullIfEmptyOrWhitespace());
                appBuilder.UseHsts(options => options.MaxAge(seconds: maxAge).IncludeSubdomains());
            }
        }

        void ConfigureSignalR(IAppBuilder appBuilder)
        {
            var serializer = JsonSerializer.Create(
                                                   new JsonSerializerSettings
                                                   {
                                                       ContractResolver = new SignalRCamelCasingContractResolver()
                                                   });

            GlobalHost.DependencyResolver.Register(typeof(JsonSerializer), () => serializer);
            GlobalHost.DependencyResolver.Register(typeof(IHubActivator), () => new AutofacHubActivator(Container));
            GlobalHost.HubPipeline.AddModule(new SignalRErrorHandler(Container));
            appBuilder.MapSignalR();
        }

        static void ConfigureAuthentication(IAppBuilder appBuilder)
        {
            appBuilder.UseMiddlewareFromContainer<FormsAuthCookieMiddleware>();
        }

        static void ConfigureStaticFiles(IAppBuilder appBuilder)
        {
            var fs = new PhysicalFileSystem(Root);

            appBuilder.UseDefaultFiles(new DefaultFilesOptions { FileSystem = fs });
            appBuilder.UseStaticFiles(new StaticFileOptions
            {
                FileSystem = fs,
                OnPrepareResponse = OnPrepareResponse,
                ContentTypeProvider = new CustomContentTypeProvider()
            });
        }

        static void OnPrepareResponse(StaticFileResponseContext ctx)
        {
            var index = string.Equals(ctx.File.Name, "index.html", StringComparison.OrdinalIgnoreCase);
            var angularlocale = ctx.File.Name.StartsWith("angular-locale", StringComparison.OrdinalIgnoreCase);
            var translations = ctx.File.Name.StartsWith("translations_", StringComparison.OrdinalIgnoreCase);
            var kendoLocales = ctx.File.Name.EndsWith("all.json", StringComparison.OrdinalIgnoreCase);
            var compressedFiles = ctx.File.Name.EndsWith(".gz", StringComparison.OrdinalIgnoreCase);
            var servedFolderSecurity = ctx.OwinContext.Request.Path.HasValue &&
                                      (ctx.OwinContext.Request.Path.Value.Contains("ng") || ctx.OwinContext.Request.Path.Value.Contains("condor"));
            
            var headers = ctx.OwinContext.Response.Headers;
            
            if (compressedFiles && servedFolderSecurity)
            {
                ctx.OwinContext.Response.Headers["Content-Encoding"] = "gzip";
                ctx.OwinContext.Response.Headers["Content-Type"] = "application/javascript";
            }
            //Set response headers related to security.
            headers["X-Frame-Options"] = "SameOrigin";
            headers["X-XSS-Protection"] = "1;mode=block";
            if (!compressedFiles) headers["X-Content-Type-Options"] = "nosniff";

            var mustRevalidate = index || angularlocale || translations || kendoLocales;
            if (!mustRevalidate) return;

            headers["Cache-Control"] = (translations || kendoLocales)
                ? "no-cache, max-age=86164, must-revalidate, proxy-revalidate"
                : "no-cache, no-store, must-revalidate";

            headers["Pragma"] = "no-cache";
            headers["Expires"] = "0";
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

                if (!CheckMinimumInprotechVersion(12, 1))
                {
                    var cache = scope.Resolve<ITaskSecurityProviderCache>();
                    cache.IsDisabled = true;

                    var subjectCache = scope.Resolve<ISubjectSecurityProviderCache>();
                    subjectCache.IsDisabled = true;
                }

                var usptoInt = scope.Resolve<IRepository>();
                Database.SetInitializer<IntegrationDbContext>(null);

                var _ = usptoInt.Set<Sponsorship>().FirstOrDefault();
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
            return true;
        }

        static void ConfigureNtlmForBackwardCompatibility(IAppBuilder appBuilder)
        {
            ConfigurationSettings configSettings;
            if (CheckMinimumInprotechVersion(12, 1) || (configSettings = new ConfigurationSettings())["AuthenticationMode"].Trim().ToLower() != "windows")
                return;

            var schemesSetting = configSettings["WindowsAuthenticationSchemes"];

            var schemes = (from s in schemesSetting.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                           select (AuthenticationSchemes)Enum.Parse(typeof(AuthenticationSchemes), s.Trim(), true))
                .Aggregate(AuthenticationSchemes.None, (current, i) => current | i);

            var httpListener = (HttpListener)appBuilder.Properties["System.Net.HttpListener"];
            httpListener.AuthenticationSchemes = schemes;
        }

        static bool CheckMinimumInprotechVersion(int majorVersion, int minorVersion)
        {
            var versionChecker = new InprotechVersionChecker(new ConfigurationSettings());
            return versionChecker.CheckMinimumVersion(majorVersion, minorVersion);
        }

        static void ConfigureQaSettings(ILifetimeScope container)
        {
            if (string.IsNullOrEmpty(ConfigurationManager.AppSettings["e2e"])) return;

            var siteControlCache = container.Resolve<ISiteControlCache>();
            siteControlCache.IsDisabled = true;
        }
    }
}