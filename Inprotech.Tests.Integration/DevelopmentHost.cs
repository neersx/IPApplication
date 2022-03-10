using System.Diagnostics;
using System.Net.Http;
using Inprotech.Tests.Integration.Utils;

namespace Inprotech.Tests.Integration
{
    internal static class DevelopmentHost
    {
        internal static bool IsRunning()
        {
            if (!Env.UseDevelopmentHost)
                return false;

            using (var client = new HttpClient())
            using (var message = new HttpRequestMessage(HttpMethod.Get, Runtime.TestSubject.DefaultTestInprotechServerRoot))
            {
                var response = client.SendAsync(message, HttpCompletionOption.ResponseHeadersRead).Result;
                return response.IsSuccessStatusCode;
            }
        }

        internal static void Stop()
        {
            Runner.KillProcess("Inprotech.Server.exe");
        }

        internal static void Start()
        {
            Process.Start(new ProcessStartInfo {FileName = Env.InprotechServerDebugPath});
            Try.Wait(5, 1000, IsRunning);
        }
    }

    internal static class DevelopmentIntegrationServer
    {
        internal static bool IsRunning()
        {
            if (!Env.UseDevelopmentHost)
                return false;

            using (var client = new HttpClient())
            using (var message = new HttpRequestMessage(HttpMethod.Get, Runtime.TestSubject.DefaultTestIntegrationServerStatus))
            {
                var response = client.SendAsync(message, HttpCompletionOption.ResponseHeadersRead).Result;
                return response.IsSuccessStatusCode;
            }
        }

        internal static void Stop()
        {
            Runner.KillProcess("Inprotech.IntegrationServer.exe");
        }

        internal static void Start()
        {
            Process.Start(new ProcessStartInfo {FileName = Env.IntegrationServerDebugPath});
            Try.Wait(5, 1000, IsRunning);
        }
    }

    internal static class DevelopmentStorageService
    {
        internal static bool IsRunning()
        {
            if (!Env.UseDevelopmentHost)
                return false;

            using (var client = new HttpClient())
            using (var message = new HttpRequestMessage(HttpMethod.Get, Runtime.TestSubject.DefaultTestStorageServiceStatus))
            {
                var response = client.SendAsync(message, HttpCompletionOption.ResponseHeadersRead).Result;
                return response.IsSuccessStatusCode;
            }
        }

        internal static void Stop()
        {
            Runner.KillProcess("Inprotech.StorageService.exe");
        }

        internal static void Start()
        {
            Process.Start(new ProcessStartInfo {FileName = Env.StorageServiceDebugPath});
            Try.Wait(5, 1000, IsRunning);
        }
    }
}