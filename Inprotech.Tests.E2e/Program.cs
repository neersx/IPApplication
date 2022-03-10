using Topshelf;

namespace Inprotech.Tests.E2e
{
    internal class Program
    {
        static int Main(string[] args)
        {
            return (int) HostFactory.Run(
                                         hc =>
                                         {
                                             hc.Service<HostServiceControl>(
                                                                            sc =>
                                                                            {
                                                                                sc.ConstructUsing(() => new HostServiceControl());
                                                                                sc.WhenStarted(sh => sh.Start());
                                                                                sc.WhenStopped(sh => sh.Stop());
                                                                            });

                                             hc.SetServiceName("InprotechTestsE2E");
                                             hc.SetDisplayName("Inprotech Tests E2E Web Server");
                                             hc.SetDescription("Inprotech Tests E2E Web Server");
                                         });
        }
    }
}