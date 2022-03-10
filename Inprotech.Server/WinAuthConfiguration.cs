using System;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Security;
using Inprotech.Server.Security;
using Inprotech.Server.Security.AntiForgery;
using Owin;

namespace Inprotech.Server
{
    public static class WinAuthConfiguration
    {
        public static void Config(IAppBuilder appBuilder)
        {
            if (appBuilder == null) throw new ArgumentNullException(nameof(appBuilder));

            var config = new HttpConfiguration();

            var builder = Dependencies.Configure(config);

            builder.RegisterType<WindowsAuthenticationMiddleware>().InstancePerRequest();

            var authSettings = new AuthSettings();
            builder.RegisterInstance<IAuthSettings>(authSettings);

            var container = builder.Build();
            config.Services.Replace(typeof(IExceptionHandler), new DelegatingUnhandledExceptionHandler());

            var schemesSetting = ConfigurationManager.AppSettings["WindowsAuthenticationSchemes"];

            var schemes = (from s in schemesSetting.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                           select (AuthenticationSchemes)Enum.Parse(typeof(AuthenticationSchemes), s.Trim(), true))
                .Aggregate(AuthenticationSchemes.None, (current, i) => current | i);

            var httpListener = (HttpListener)appBuilder.Properties["System.Net.HttpListener"];
            httpListener.AuthenticationSchemes = schemes;

            appBuilder.UseAutofacLifetimeScopeInjector(container);
            appBuilder.UseMiddlewareFromContainer<GlobalExceptionHandlerMiddleware>();
            appBuilder.UseMiddlewareFromContainer<WindowsAuthenticationMiddleware>();
            appBuilder.UseMiddlewareFromContainer<CsrfMiddleware>();
            appBuilder.UseAutofacMiddleware(container);
            InitialiseAuthSettings(container, authSettings);
        }

        static void InitialiseAuthSettings(ILifetimeScope container, AuthSettings authSettings)
        {
            using (var scope = container.BeginLifetimeScope())
            {
                var groupedConfig = scope.Resolve<Func<string, IGroupedConfig>>();
                var appConfigurationSettings = scope.Resolve<IConfigurationSettings>();
                AuthSettingsResolver.Resolve(authSettings, groupedConfig, appConfigurationSettings);
            }
        }
    }
}