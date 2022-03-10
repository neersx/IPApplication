using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Threading;
using ApplicationInsights.OwinExtensions;
using Autofac;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Monitoring;
using Inprotech.IntegrationServer.BackgroundProcessing;
using Microsoft.Owin.Hosting;
using Owin;

namespace Inprotech.IntegrationServer
{
    public class HostServiceControl
    {
        string _boundEndpoint;
        IEnumerable<IClock> _clocks;
        IDisposable _server;
        
        public void Start()
        {
            _clocks = Configuration.Container.Resolve<IEnumerable<IClock>>();

            foreach (var clock in _clocks)
                clock.Start();

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

            if (_clocks == null) return;

            foreach (var _ in _clocks)
                _.Stop();
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

        public static void StartWorkflowEngine()
        {
            Configuration.StartDependableWorkflowEngine();
        }
    }
}