using System;
using System.IO;
using System.Reflection;

namespace Inprotech.Setup.Core
{
    public interface IVersionManager
    {
        Version GetCurrentWebAppVersion();
        Version GetIisAppVersion(string root);
        bool ShouldUpgradeWebApp(Version installedVersion);
        bool IsAuthModeSetFromApps(Version installedIisAppVersion);
        bool MustUpgradeWebApp(Version installedIisAppVersion, Version installedWebAppsVersion);
    }

    class VersionManager : IVersionManager
    {
        const string MinIisVersionForSso = "12.1";
        const string MinAppsVersionForSso = "4.3";
        public Version GetCurrentWebAppVersion()
        {
            return Assembly.GetExecutingAssembly().GetName().Version;
        }

        public Version GetIisAppVersion(string root)
        {
            var path = Path.Combine(root, Constants.BinFolder, Constants.InprotechCoreDll);
            var name = AssemblyName.GetAssemblyName(path);

            return name.Version;
        }

        public bool ShouldUpgradeWebApp(Version oldVersion)
        {
#if DEBUG
            return true;
#else
            var currentVersion = GetCurrentWebAppVersion();
            return currentVersion > oldVersion;
#endif
        }
        
        public bool IsAuthModeSetFromApps(Version installedIisAppVersion)
        {
#if DEBUG
            return true;
#else
            return installedIisAppVersion >= Version.Parse(MinIisVersionForSso);
#endif
        }

        public bool MustUpgradeWebApp(Version installedIisAppVersion, Version installedWebAppsVersion)
        {
#if DEBUG
            return false;
#else
           var appsWithoutSso = installedWebAppsVersion < Version.Parse(MinAppsVersionForSso);
           return IsAuthModeSetFromApps(installedIisAppVersion) && appsWithoutSso;
#endif
        }
    }
}