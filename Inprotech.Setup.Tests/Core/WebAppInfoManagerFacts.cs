using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class WebAppInfoManagerFacts
    {
        public WebAppInfoManagerFacts()
        {
            _settingsManagerFunc.Invoke(Arg.Any<string>()).Returns(_ => _settingsManager);

            _manager = new WebAppInfoManager(_fileSystem, _assemblyLoader, _settingsManagerFunc, _configurationReader, _serviceManager);
        }

        readonly IWebAppInfoManager _manager;
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly ISetupSettingsManager _settingsManager = Substitute.For<ISetupSettingsManager>();
        readonly IWebAppConfigurationReader _configurationReader = Substitute.For<IWebAppConfigurationReader>();
        readonly IServiceManager _serviceManager = Substitute.For<IServiceManager>();
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc = Substitute.For<Func<string, ISetupSettingsManager>>();
        readonly ISetupActionsAssemblyLoader _assemblyLoader = Substitute.For<ISetupActionsAssemblyLoader>();

        void ReturnInstanceFromService(string instance)
        {
            _serviceManager.FindAllWebAppPaths().Returns(new[] {instance});
            _settingsManager.Read(instance).Returns(new SetupSettings());
        }

        void ReturnInstanceFromDirectory(string root, string instance)
        {
            _fileSystem.DirectoryExists(root).Returns(true);
            _fileSystem.GetDirectories(root).Returns(new[] {instance});
            _fileSystem.GetFullPath(instance).Returns(instance);

            _fileSystem.GetSafeFolderName(Arg.Any<string>())
                       .Returns(x =>
                       {
                           var a = (string) x[0];
                           return a?.Replace("/", string.Empty);
                       });

            _fileSystem.FileExists(Arg.Any<string>()).Returns(true);

            _settingsManager.Read(instance).Returns(new SetupSettings());
        }

        [Fact]
        public void CanFindAllInstances()
        {
            var root = "c:\\instances";
            ReturnInstanceFromDirectory(root, "instance-1");
            ReturnInstanceFromService("instance-2");

            var all = _manager.FindAll(root).ToArray();

            Assert.Equal("instance-1", all[0].InstanceName);
            Assert.Equal("instance-2", all[1].InstanceName);
        }

        [Fact]
        public void CanGetBrokenWebAppInstance()
        {
            var path = "c:\\instance-1";
            _settingsManager.Read(path).Returns(new SetupSettings());
            _configurationReader.Read(path).Returns(new[] {new InstanceComponentConfiguration()});
            _fileSystem.FileExists(Arg.Any<string>()).Returns(false);

            var webApp = _manager.Get(path);

            Assert.Equal("instance-1", webApp.InstanceName);
            Assert.Equal(1, webApp.InstanceNo);
            Assert.NotNull(webApp.Settings);
            Assert.True(webApp.IsBrokenInstance);
        }

        [Fact]
        public void CanGetNewInstance()
        {
            var root = "c:\\instances";
            var iisPath = "/cpainpro";
            ReturnInstanceFromDirectory(root, "instance-1");

            var newPath = _manager.GetNewInstancePath(root, iisPath);
            Assert.Equal($"c:\\instances\\cpainpro-{Environment.MachineName}".ToLower(), newPath);
        }

        [Fact]
        public void CanGetWebApp()
        {
            var path = "c:\\instance-1";
            _settingsManager.Read(path).Returns(new SetupSettings());
            _configurationReader.Read(path).Returns(new[] {new InstanceComponentConfiguration()});
            _fileSystem.FileExists(Path.Combine(path, Constants.InprotechServer.ConfigPath)).Returns(true);

            var webApp = _manager.Get(path);

            Assert.Equal("instance-1", webApp.InstanceName);
            Assert.Equal(1, webApp.InstanceNo);
            Assert.NotNull(webApp.Settings);
            Assert.NotNull(webApp.ComponentConfigurations);
            Assert.False(webApp.IsBrokenInstance);
        }

        [Fact]
        public void OrdersByInstanceNoThenByInstanceName()
        {
            var root = "c:\\instances";
            ReturnInstanceFromDirectory(root, "abc@def");
            ReturnInstanceFromService("instance-2");

            var all = _manager.FindAll(root).ToArray();

            Assert.Equal("instance-2", all[0].InstanceName);
            Assert.Equal("abc@def", all[1].InstanceName);
        }

        [Fact]
        public void PrivateKeyPassedToSetupSettingsManager()
        {
            const string key = "IAmtheKey!!";
            _configurationReader.Read(Arg.Any<string>())
                                .Returns(new List<InstanceComponentConfiguration>
                                {
                                    new InstanceComponentConfiguration
                                    {
                                        Name = "Inprotech Server",
                                        AppSettings = new Dictionary<string, string> {{"PrivateKey", key}}
                                    }
                                });
            _fileSystem.FileExists(Arg.Any<string>()).Returns(true);

            _manager.Get("somepath");

            _settingsManagerFunc.Received(1).Invoke(key);
        }
    }
}