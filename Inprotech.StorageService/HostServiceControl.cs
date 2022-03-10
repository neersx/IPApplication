using System;
using System.Configuration;
using System.Data;
using System.Threading;
using ApplicationInsights.OwinExtensions;
using Autofac;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Monitoring;
using Microsoft.Owin.Hosting;
using Owin;

namespace Inprotech.StorageService
{
    public class HostServiceControl
    {
        string _boundEndpoint;
        IDisposable _server;

        public void Start()
        {
            var options = new StartOptions();

            var host = ConfigurationManager.AppSettings["Host"];
            var port = ConfigurationManager.AppSettings["Port"];
            var path = ConfigurationManager.AppSettings["Path"];
            var uriSafeInstanceName = ConfigurationManager.AppSettings["InstanceName"].Replace($"-{Environment.MachineName}".ToLower(), string.Empty);

            options.Urls.Add(_boundEndpoint = $"http://{host}:{port}/{path}-{uriSafeInstanceName}");

            _server = WebApp.Start(options, appBuilder =>
            {
                appBuilder.UseApplicationInsights(new RequestTrackingConfiguration
                {
                    RequestIdFactory = IdFactory.FromHeader(OperationContexts.RequestIdHeader)
                });
                appBuilder.UseWebApi(Configuration.Http);
            });

            RegisterServiceStatus(ServiceStatus.Online);
        }

        public void Stop()
        {
            RegisterServiceStatus(ServiceStatus.Offline);

            _server?.Dispose();
        }

        void RegisterServiceStatus(ServiceStatus status)
        {
            var exceeded = 0;
            do
            {
                try
                {
                    using (var scope = Configuration.Container.BeginLifetimeScope())
                    {
                        scope.Resolve<IInstanceRegistrations>().RegisterSelf(status, new[] {_boundEndpoint.TrimEnd('/') + '/'});
                    }

                    break;
                }
                catch (DBConcurrencyException) when (exceeded++ < 2)
                {
                    Thread.Sleep(TimeSpan.FromSeconds(1));
                }
            }
            while (true);
        }
    }
}