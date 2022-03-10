using OpenQA.Selenium;

namespace Inprotech.Tests.Integration
{
    // this RegisterCallback will be called using reflection from E2E agent
    // so this class must be public

    public static class RunnerInterface
    {
        static object _callback;

        public static void RegisterCallback(object obj)
        {
            _callback = obj;
        }

        public static void RegisterApplicationSettingsForDockerMode(string url, string storageLocation)
        {
            Runtime.SetExecutionContextToDockerMode(url, storageLocation);
        }

        public static void AgentIsRunningInContainer()
        {
            Runtime.SetSettingsForAgentRunningInContainer();
        }

        public static void TeamCity(string line)
        {
            try
            {
                _callback?.GetType().GetMethod("TeamCityCallback").Invoke(_callback, new[] { line });
            }
            catch
            {
            }
        }

        public static void Log(string line)
        {
            try
            {
                _callback?.GetType().GetMethod("LogCallback").Invoke(_callback, new[] { line });
            }
            catch
            {
            }
        }

        public static BrowserType[] BrowsersAllowed()
        {
            return new BrowserType[0];
        }

        public static string BrowserVersion(BrowserType browserType)
        {
            return BrowserType.FireFox == browserType ? Runtime.Browser.FireFoxReleaseVersion : null;
        }

        public static dynamic PreferredScreenshotFormat()
        {
            return ScreenshotImageFormat.Png;
        }

        public static void StopDockerAppsInstances()
        {
            try
            {
                _callback?.GetType().GetMethod("StopDockerAppsInstances")?.Invoke(_callback, null);
            }
            catch
            {
            }
        }

        public static void StartDockerAppsInstances()
        {
            try
            {
                _callback?.GetType().GetMethod("StartDockerAppsInstances")?.Invoke(_callback, null);
            }
            catch
            {
            }
        }

        public static int GetDbReleaseLevel()
        {
            return new DbReleaseVersionResolver().ResolveDbReleaseLevel();
        }
    }
}