using System;
using System.Configuration;
using Inprotech.Infrastructure;
using Microsoft.Owin.Hosting;

namespace Inprotech.Tests.E2e
{
    public class HostServiceControl
    {
        IDisposable _server;

        public void Start()
        {

            var options = new StartOptions();
            options.Urls.Add(string.Format(
                                           "https://{0}:{1}/{2}",
                                           ConfigurationManager.AppSettings["Host"],
                                           443,
                                           ConfigurationManager.AppSettings["Path"]));
            options.Urls.Add(string.Format(
                                           "http://{0}:{1}/{2}",
                                           ConfigurationManager.AppSettings["Host"],
                                           ConfigurationManager.AppSettings["Port"],
                                           ConfigurationManager.AppSettings["Path"]));

            _server = WebApp.Start(options);
        }

        public void Stop()
        {
            if(_server != null) _server.Dispose();
        }
    }
}