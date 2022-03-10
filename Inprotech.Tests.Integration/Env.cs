using System;
using System.Diagnostics;
using System.IO;
using System.Security.Principal;

namespace Inprotech.Tests.Integration
{
    static class Env
    {
        static bool? _isRunningTeamCity;

        static Env()
        {
            // TODO: can drivers be closed on crash or exit rather than on start?
            Runner.KillProcess("chromedriver.exe", "IeDriverServer.exe", "geckodriver.exe");

            if (IsTeamCity())
            {
                RootUrl = Runtime.TestSubject.DefaultInstallInprotechServerRoot;
                UseInstalledHost = true;
            }
            else
            {
                RootUrl = Runtime.TestSubject.DefaultTestInprotechServerRoot;
                UseInstalledHost = false;
            }
        }

        public static string RootUrl { get; private set; }

        public static string FakeServerUrl
        {
            get
            {
                var uri = new Uri(RootUrl);
                var url = $"{uri.Scheme}://{uri.Host}/e2e/";

                return url;
            }
        }

        public static bool UseInstalledHost { get; }

        public static bool UseDevelopmentHost => !UseInstalledHost;

        public static string InprotechServerDebugPath
        {
            get
            {
                if (UseInstalledHost)
                    return null;

                var path = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, @"..\..\..\Inprotech.Server\bin\debug\Inprotech.Server.exe");

                return Path.GetFullPath(path);
            }
        }

        public static string IntegrationServerDebugPath
        {
            get
            {
                if (UseInstalledHost)
                    return null;

                var path = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, @"..\..\..\Inprotech.IntegrationServer\bin\debug\Inprotech.IntegrationServer.exe");

                return Path.GetFullPath(path);
            }
        }

        public static string StorageServiceDebugPath
        {
            get
            {
                if (UseInstalledHost)
                    return null;

                var path = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, @"..\..\..\Inprotech.StorageService\bin\debug\Inprotech.StorageService.exe");

                return Path.GetFullPath(path);
            }
        }

        public static int LoginUserId => 45;

        public static string LoginUsername => "internal";

        public static string LoginRole => "internal";

        public static int ExternalLoginUserId => 46;

        public static string ExternalLoginUsername => "external";

        public static string ExternalLoginRole => "external";

        public static string StorageLocation => Runtime.StorageLocation;

        public static string GetUserDomainAndName()
        {
            return WindowsIdentity.GetCurrent().Name;
        }

        public static bool UseHeadlessChrome => Runtime.UseChromeHeadless;

        public static bool IsTeamCity()
        {
            if (_isRunningTeamCity.HasValue)
                return _isRunningTeamCity.Value;

            var process = Process.GetCurrentProcess();

            _isRunningTeamCity = process.ProcessName.IndexOf("Tests.Integration.Agent", StringComparison.InvariantCultureIgnoreCase) >= 0;

            return _isRunningTeamCity.Value;
        }
    }
}