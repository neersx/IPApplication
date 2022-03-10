using Topshelf;

namespace Inprotech.IntegrationServer
{
    class Program
    {
        static void Main(string[] args)
        {
            System.IO.Directory.SetCurrentDirectory(System.AppDomain.CurrentDomain.BaseDirectory);
            HostFactory.Run(
                            hc =>
                            {
                                hc.UseNLog();
                                hc.Service<HostServiceControl>(
                                                               sc =>
                                                               {
                                                                   sc.ConstructUsing(() => new HostServiceControl());
                                                                   sc.WhenStarted(sh => sh.Start());
                                                                   sc.WhenStopped(sh => sh.Stop());
                                                                   sc.AfterStartingService(x =>
                                                                   {
                                                                       HostServiceControl.StartWorkflowEngine();
                                                                   });
                                                               });
                                
                                hc.SetServiceName("Inprotech.IntegrationServer");
                                hc.SetDisplayName("Inprotech Integration Server");
                                hc.SetDescription("Inprotech Integration Server");
                                hc.EnableServiceRecovery(
                                    rc =>
                                    {
                                        rc.RestartService(1);
                                        rc.SetResetPeriod(1);
                                    });
                            });
        }
    }
}