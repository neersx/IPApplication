using System;
using System.Collections.Generic;
using System.Net.NetworkInformation;

namespace Inprotech.Setup.Core.Utilities
{
    public interface IPorts
    {
        int Allocate();
    }

    public class Ports : IPorts
    {
        static readonly List<int> Allocated = new List<int>();

        public int Allocate()
        {
            var random = new Random();
            int port;
            do
            {
                port = random.Next(14000, 16000);
                if (Allocated.Contains(port) || !IsAvailable(port))
                    continue;

                Allocated.Add(port);
                break;
            }
            while (true);   

            return port;
        }

        static bool IsAvailable(int port)
        {
            var isAvailable = true;

            var ipGlobalProperties = IPGlobalProperties.GetIPGlobalProperties();
            var tcpConnInfoArray = ipGlobalProperties.GetActiveTcpListeners();

            foreach (var endpoint in tcpConnInfoArray)
            {
                if (endpoint.Port != port) continue;
                isAvailable = false;
                break;
            }

            return isAvailable;
        }
    }
}
