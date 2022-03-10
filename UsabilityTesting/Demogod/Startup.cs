using System;
using System.Threading;
using Demogod.Policing;
using Microsoft.Owin;
using NLog;
using Owin;

[assembly: OwinStartup(typeof (Demogod.Startup))]

namespace Demogod
{
    public class Startup
    {
        readonly Timer _timer;
        readonly ServerManager _serverManager;
        readonly Logger _logger = LogManager.GetLogger("Startup");

        public void Configuration(IAppBuilder app)
        {
            app.MapSignalR();
        }
        
        public Startup()
        {
            _serverManager = new ServerManager();
            _timer = new Timer(TickInternal, null, 1000, 1 * 1000);
        }
        
        void TickInternal(object state)
        {
            try
            {
                _serverManager.PublishServerState();

                _serverManager.PublishProblemItems();
            }
            catch (Exception ex)
            {
                _logger.Error(ex);
            }
        }
    }
}