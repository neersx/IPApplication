using System;
using System.IO;
using System.Linq;

namespace Inprotech.Setup.Core.Actions
{
    interface IValidator
    {
        void ValidateSettingsFileExists(string instancePath);
        void ValidateSafePathForNewInstance(string path);
        void ValidateIisAppIsNotPaired(string rootPath, string iisSite, string iisPath);
        void RequireUpdateFeature(string instancePath);
        void ValidateCommandLineInstallationFeatureIfRequired(string instancePath);
        void ValidateCanUpgrade(string instancePath);
        void ValidateInstanceComplete(string instancePath, ISetupSettingsManager settingsManager);
        void ValidateMustUpgrade(string instancePath, IisAppInfo pairedIisApp);
        void ValidateRecoveryFeature(string instancePath);
    }

    class Validator : IValidator
    {
        readonly IFileSystem _fileSystem;
        readonly IWebAppInfoManager _webAppInfoManager;
        readonly IVersionManager _versionManager;

        public Validator(IFileSystem fileSystem, IWebAppInfoManager webAppInfoManager, IVersionManager versionManager)
        {
            _fileSystem = fileSystem;
            _webAppInfoManager = webAppInfoManager;
            _versionManager = versionManager;
        }

        public void ValidateSettingsFileExists(string instancePath)
        {
            if (!_fileSystem.DirectoryExists(instancePath))
                throw new Exception("Path not found: " + instancePath);

            if (!_fileSystem.FileExists(Path.Combine(instancePath, Constants.SettingsFileName)))
                throw new Exception($"Unable to find {Constants.SettingsFileName} in \"{instancePath}\"");
        }

        public void ValidateInstanceComplete(string instancePath, ISetupSettingsManager settingsManager)
        {
            if (settingsManager.Read(instancePath).Status != SetupStatus.Complete)
                throw new Exception("Previous setup is not complete. Run 'setup-cli resume' to continue.");
        }

        public void ValidateSafePathForNewInstance(string path)
        {
            if (_fileSystem.FileExists(Path.Combine(path, Constants.SettingsFileName)))
                throw new Exception($"An instance already exists in \"{path}\"");
        }

        public void ValidateIisAppIsNotPaired(string rootPath, string iisSite, string iisPath)
        {
            var all = _webAppInfoManager.FindAll(rootPath);
            var info = Helpers.FindWebApp(all, iisSite, iisPath);

            if (info != null)
                throw new Exception(string.Format("\"{0}\" has already been paired with \"{1}\"", iisSite + iisPath, info.InstanceName));
        }

        public void RequireUpdateFeature(string instancePath)
        {
            if (!_webAppInfoManager.Get(instancePath).Features.Contains("settings"))
                throw new Exception("Instance doesn't support changing settings.");
        }

        public void ValidateCommandLineInstallationFeatureIfRequired(string instancePath)
        {
            if (SetupEnvironment.IsUiMode)
                return;

            if (!_webAppInfoManager.Get(instancePath).Features.Contains("cli-installation"))
                throw new Exception("Instance doesn't support command line installation. Please try using UI version.");
        }

        public void ValidateCanUpgrade(string instancePath)
        {
            var info = _webAppInfoManager.Get(instancePath);

            if (!_versionManager.ShouldUpgradeWebApp(info.Settings.Version))
                throw new Exception(string.Format("Cannot upgrade to lower version. current={0}, new={1}", info.Settings.Version, _versionManager.GetCurrentWebAppVersion()));
        }

        public void ValidateMustUpgrade(string instancePath,IisAppInfo pairedIisApp)
        {
            var info = _webAppInfoManager.Get(instancePath);

            if (pairedIisApp.AuthModeToBeSetFromApps && _versionManager.MustUpgradeWebApp(pairedIisApp.Version,info.Settings.Version))
                throw new Exception(string.Format("You must upgrade your apps version. current={0}, new={1}", info.Settings.Version, _versionManager.GetCurrentWebAppVersion()));
        }

        public void ValidateRecoveryFeature(string instancePath)
        {
            if (!_webAppInfoManager.Get(instancePath).Features.Contains("failed-action-recovery"))
                throw new Exception("Instance doesn't support script recovery.");
        }
    }
}