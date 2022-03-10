using System;
using System.IO;
using Topshelf;

namespace Inprotech.StorageService
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
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

                                hc.SetServiceName("Inprotech.StorageService");
                                hc.SetDisplayName("Inprotech Storage Service");
                                hc.SetDescription("Inprotech Storage Service");
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