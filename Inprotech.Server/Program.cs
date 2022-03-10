using Topshelf;

namespace Inprotech.Server
{
    class Program
    {
        static void Main()
        {
            System.IO.Directory.SetCurrentDirectory(System.AppDomain.CurrentDomain.BaseDirectory);
            HostFactory.Run(
                            hc =>
                            {
                                hc.StartAutomaticallyDelayed();
                                hc.UseNLog();
                                hc.Service<HostServiceControl>(
                                                               sc =>
                                                               {
                                                                   sc.ConstructUsing(() => new HostServiceControl());
                                                                   sc.WhenStarted(sh => sh.Start());
                                                                   sc.WhenStopped(sh => sh.Stop());
                                                               });

                                hc.SetServiceName("Inprotech.Server");
                                hc.SetDisplayName("Inprotech Server");
                                hc.SetDescription("Inprotech Server");
                                hc.EnableServiceRecovery(
                                    rc =>
                                    {
                                        rc.RestartService(1);
                                        rc.SetResetPeriod(1);
                                        rc.RestartService(1);
                                        rc.SetResetPeriod(1);
                                    });
                            });
        }
    }
}