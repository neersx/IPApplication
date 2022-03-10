using System;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class SetupSettingsManagerFacts
    {
        public SetupSettingsManagerFacts()
        {
            _fileSystem = Substitute.For<IFileSystem>();
            _cryptoService = Substitute.For<ICryptoService>();
            _manager = new SetupSettingsManager(_privateKey, _fileSystem, _cryptoService);

            _cryptoService.TryDecrypt(Arg.Any<string>(), Arg.Any<string>()).Returns(_ => _.Args()[1]);
            _cryptoService.Encrypt(Arg.Any<string>(), Arg.Any<string>()).Returns(_ => _.Args()[1]);
        }

        readonly string _privateKey = "IAmTheKey!";
        readonly IFileSystem _fileSystem;
        readonly ICryptoService _cryptoService;
        readonly ISetupSettingsManager _manager;

        [Fact]
        public void ShouldWriteAndReadSettings()
        {
            var settings = new SetupSettings
            {
                RunMode = SetupRunMode.Update,
                IisSite = "a",
                IisPath = "b",
                StorageLocation = "c",
                Status = SetupStatus.Install,
                Version = Version.Parse("1.0"),
                NewInstancePath = "d",
                DatabaseUsername = "e",
                DatabasePassword = "f",
                AuthenticationMode = "Forms,Sso",
                IntegrationServerPort = "80",
                RemoteIntegrationServerUrl = "i",
                RemoteStorageServiceUrl = "j",
                CookiePath = "j",
                CookieName = "k",
                CookieConsentSettings = new CookieConsentSettings { CookieConsentBannerHook = "l" },
                IsE2EMode = Fixture.Boolean(),
                BypassSslCertificateCheck = Fixture.Boolean()
            };

            string output = null;

            _fileSystem.WriteAllText(@"c:\instance-1\settings.json", Arg.Do<string>(_ => output = _));
            _fileSystem.FileExists(@"c:\instance-1\settings.json").Returns(true);

            _manager.Write(@"c:\instance-1", settings);
            _cryptoService.Received(1).Encrypt(_privateKey, Arg.Any<string>());

            _fileSystem.ReadAllText(@"c:\instance-1\settings.json").Returns(output);
            var settings2 = _manager.Read(@"c:\instance-1");
            _cryptoService.Received(1).TryDecrypt(_privateKey, Arg.Any<string>());

            Assert.Equal(settings.RunMode, settings2.RunMode);
            Assert.Equal(settings.IisSite, settings2.IisSite);
            Assert.Equal(settings.IisPath, settings2.IisPath);
            Assert.Equal(settings.StorageLocation, settings2.StorageLocation);
            Assert.Equal(settings.Status, settings2.Status);
            Assert.Equal(settings.Version, settings2.Version);
            Assert.Equal(settings.NewInstancePath, settings2.NewInstancePath);
            Assert.Equal(settings.DatabaseUsername, settings2.DatabaseUsername);
            Assert.Equal(settings.DatabasePassword, settings2.DatabasePassword);
            Assert.Equal(settings.AuthenticationMode, settings2.AuthenticationMode);
            Assert.Equal(settings.IntegrationServerPort, settings2.IntegrationServerPort);
            Assert.Equal(settings.RemoteIntegrationServerUrl, settings2.RemoteIntegrationServerUrl);
            Assert.Equal(settings.RemoteStorageServiceUrl, settings2.RemoteStorageServiceUrl);
            Assert.Equal(settings.CookiePath, settings2.CookiePath);
            Assert.Equal(settings.CookieName, settings2.CookieName);
            Assert.Equal(settings.CookieConsentSettings.CookieConsentBannerHook, settings2.CookieConsentSettings.CookieConsentBannerHook);
            Assert.Equal(settings.IsE2EMode, settings2.IsE2EMode);
            Assert.Equal(settings.BypassSslCertificateCheck, settings2.BypassSslCertificateCheck);
        }
    }
}