using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core
{
    public interface IWebAppInfoManager
    {
        WebAppInfo Get(string instancePath);

        string GetNewInstanceName(string uniqueIisPath);

        string GetNewInstancePath(string rootPath, string uniqueIisPath);

        IEnumerable<WebAppInfo> FindAll(string rootPath);
    }

    internal class WebAppInfoManager : IWebAppInfoManager
    {
        readonly IWebAppConfigurationReader _configurationReader;
        readonly IFileSystem _fileSystem;
        readonly IServiceManager _serviceManager;
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly ISetupActionsAssemblyLoader _setupActionsAssemblyLoader;

        public WebAppInfoManager(IFileSystem fileSystem, ISetupActionsAssemblyLoader setupActionsAssemblyLoader,
                                 Func<string, ISetupSettingsManager> settingsManagerFunc, IWebAppConfigurationReader configurationReader,
                                 IServiceManager serviceManager)
        {
            _fileSystem = fileSystem;
            _setupActionsAssemblyLoader = setupActionsAssemblyLoader;
            _settingsManagerFunc = settingsManagerFunc;
            _configurationReader = configurationReader;
            _serviceManager = serviceManager;
        }

        public string GetNewInstanceName(string uniqueIisPath)
        {
            return _fileSystem.GetSafeFolderName($"{uniqueIisPath}-{Environment.MachineName}".ToLower());
        }

        public string GetNewInstancePath(string rootPath, string uniqueIisPath)
        {
            return Path.Combine(rootPath, GetNewInstanceName(uniqueIisPath));
        }

        public WebAppInfo Get(string instancePath)
        {
            var features = GetSupportedFeatures(instancePath);
            var configPath = Path.Combine(instancePath, Constants.InprotechServer.ConfigPath);
            if (!_fileSystem.FileExists(configPath))
                return new WebAppInfo(instancePath, features, new SetupSettings(), null).MarkBroken();

            var configurations = _configurationReader.Read(instancePath).ToArray();

            string privateKey = null;
            configurations.SingleOrDefault(_ => _.Name == "Inprotech Server")?.AppSettings.TryGetValue("PrivateKey", out privateKey);
            var settingsManager = _settingsManagerFunc(privateKey);
            var settings = settingsManager.Read(instancePath);

            return settings == null ? null : new WebAppInfo(instancePath, features, settings, configurations);
        }

        public IEnumerable<WebAppInfo> FindAll(string rootPath)
        {
            var pathsFromCurrent = LoadFromDirectory(rootPath).ToArray();
            var pathsFromServices = LoadFromServices().ToArray();

            return pathsFromCurrent.Union(pathsFromServices)
                                   .Where(_ => _ != null)
                                   .GroupBy(_ => _.FullPath)
                                   .Select(_ => _.First())
                                   .OrderBy(_ => _.InstanceNo ?? int.MaxValue)
                                   .ThenBy(_ => _.InstanceName)
                                   .ToArray();
        }

        IEnumerable<WebAppInfo> LoadFromDirectory(string rootPath)
        {
            if (!_fileSystem.DirectoryExists(rootPath))
            {
                return Enumerable.Empty<WebAppInfo>();
            }

            return (from directory in _fileSystem.GetDirectories(rootPath)
                    select Get(_fileSystem.GetFullPath(directory))).ToArray();
        }

        IEnumerable<WebAppInfo> LoadFromServices()
        {
            return _serviceManager.FindAllWebAppPaths().Select(Get).ToArray();
        }

        IEnumerable<string> GetSupportedFeatures(string path)
        {
            var asm = _setupActionsAssemblyLoader.Load(path);

            if (asm == null)
            {
                return Enumerable.Empty<string>();
            }

            var type = asm.GetExportedTypes().SingleOrDefault(t => t.Name == "Features");

            if (type == null)
            {
                return Enumerable.Empty<string>();
            }

            return ((IFeatures)Activator.CreateInstance(type)).Support ?? Enumerable.Empty<string>();
        }
    }
}