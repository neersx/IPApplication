using System;
using System.Collections.Generic;
using System.Management;

namespace Inprotech.Setup.Core
{
    interface IServiceManager
    {
        IEnumerable<string> FindAllWebAppPaths();
    }

    class ServiceManager : IServiceManager
    {
        public IEnumerable<string> FindAllWebAppPaths()
        {
            var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_Service WHERE Name LIKE 'Inprotech.Server$instance-%'");
            var services = searcher.Get();

            foreach (var service in services)
            {
                var path = service["PathName"] as string;
                yield return ExtractInstancePath(path);
            }
        }

        static string ExtractInstancePath(string servicePath)
        {
            var end = servicePath.IndexOf("Inprotech.Server\\Inprotech.Server.exe", StringComparison.OrdinalIgnoreCase);
            return servicePath.Substring(0, end).Trim('"');
        }
    }
}