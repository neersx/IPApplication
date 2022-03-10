using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Threading;
using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Server.Scheduling;
using Microsoft.Owin.Hosting;

namespace Inprotech.Server
{
    public class HostServiceControl
    {
        IDisposable _server;
        IDisposable _winAuthServer;

        public HostServiceControl()
        {
            Configuration = new Configuration();
        }

        public Configuration Configuration { get; }

        public void Start()
        {
            ConfigurePrimaryServer();

            ConfigureWindowsAuthListener();

            ForEachRunnerGroup(_ => _.StartAll());

            RegisterServiceStatus(ServiceStatus.Online);
        }

        void ConfigureWindowsAuthListener()
        {
            var settings = Configuration.Container.Resolve<IAuthSettings>();

            if (!settings.WindowsEnabled) return;

            var options = new StartOptions();

            var bindingUrls = HttpListenerAddressParser.Parse(ConfigurationManager.AppSettings["BindingUrls"],
                                                              ConfigurationManager.AppSettings["ParentPath"],
                                                              "winAuth");

            options.Urls.AddAll(bindingUrls);

            _winAuthServer = WebApp.Start(options, WinAuthConfiguration.Config);
        }

        void ConfigurePrimaryServer()
        {
            var options = new StartOptions();

            var bindingUrls = HttpListenerAddressParser.Parse(
                                                              ConfigurationManager.AppSettings["BindingUrls"],
                                                              ConfigurationManager.AppSettings["ParentPath"],
                                                              ConfigurationManager.AppSettings["Path"]);

            options.Urls.AddAll(bindingUrls);

            _server = WebApp.Start(options, builder => Configuration.Config(builder));
        }

        public void Stop()
        {
            ForEachRunnerGroup(_ => _.StopAll());

            RegisterServiceStatus(ServiceStatus.Offline);

            _server?.Dispose();
            _server = null;

            _winAuthServer?.Dispose();
            _winAuthServer = null;
        }

        void ForEachRunnerGroup(Action<IRunner> action)
        {
            var runners = Configuration.Container.Resolve<IEnumerable<IRunner>>();

            if (runners == null)
            {
                return;
            }

            foreach (var runner in runners)
                action(runner);
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
                        scope.Resolve<IInstanceRegistrations>().RegisterSelf(status, new string[0]);
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