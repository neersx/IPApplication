using System;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core.Actions
{
    public class InitInstallFacts
    {
        public InitInstallFacts()
        {
            var versionManager = Substitute.For<IVersionManager>();
            var validator = Substitute.For<IValidator>();

            ISetupSettingsManager SettingsManagerFunc(string privateKey)
            {
                return _settingsManager;
            }

            IIisAppInfoManager IIisAppInfoManagerFunc(string value)
            {
                return _iisAppManager;
            }

            _action = new InitInstall(versionManager, SettingsManagerFunc, _fileSystem, _webAppManager, IIisAppInfoManagerFunc, validator, _cryptoService);
        }

        readonly ISetupSettingsManager _settingsManager = Substitute.For<ISetupSettingsManager>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IWebAppInfoManager _webAppManager = Substitute.For<IWebAppInfoManager>();
        readonly IIisAppInfoManager _iisAppManager = Substitute.For<IIisAppInfoManager>();
        readonly IEventStream _eventStream = Substitute.For<IEventStream>();
        readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
        readonly InitInstall _action;

        [Fact]
        public void ShouldInitialize()
        {
            var iisPath = "abc";
            var iisApp = new IisAppInfo
            {
                VirtualPath = iisPath,
                WebConfig = new WebConfig()
            };

            var ctx = new SetupContext
            {
                IisSite = "a",
                IisPath = iisPath,
                RootPath = "instances",
                StorageLocation = "storage",
                DatabaseUsername = "user",
                DatabasePassword = "pwd",
                AuthenticationMode = "Forms,Sso",
                Authentication2FAMode = "Internal",
                IpPlatformSettings = new IpPlatformSettings("client", "secret"),
                AdfsSettings = new AdfsSettings { Certificate = "cert", ClientId = "cli", ServerUrl = "http://a.com", RelyingPartyTrustId = "r" },
                IntegrationServerPort = "80",
                CookieConsentSettings = new CookieConsentSettings { CookieConsentBannerHook = "<script />" }
            };

            _iisAppManager.Find("a", iisPath).Returns(iisApp);
            _webAppManager.GetNewInstancePath("instances", iisPath).Returns($"{iisPath}-{Environment.MachineName}".ToLower());

            SetupSettings settings = null;
            _settingsManager
                .When(x => x.Write(Arg.Any<string>(), Arg.Any<SetupSettings>()))
                .Do(x => settings = x.ArgAt<SetupSettings>(1));

            _cryptoService
                .When(x => x.Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>()))
                .Do(x => { ((AdfsSettings)x.Args()[1]).ClientId = "enc"; });

            _action.Run(ctx, _eventStream);

            _fileSystem.Received().EnsureDirectory($"{iisPath}-{Environment.MachineName}".ToLower());
            _fileSystem.Received().EnsureDirectory(ctx.StorageLocation);

            Assert.Equal(ctx.PairedIisApp, iisApp);
            Assert.Equal(ctx.IisSite, settings.IisSite);
            Assert.Equal(ctx.IisPath, settings.IisPath);
            Assert.Equal(ctx.StorageLocation, settings.StorageLocation);
            Assert.Equal(ctx.DatabaseUsername, settings.DatabaseUsername);
            Assert.Equal(ctx.DatabasePassword, settings.DatabasePassword);
            Assert.Equal(SetupRunMode.New, settings.RunMode);
            Assert.Equal(ctx.Authentication2FAMode, settings.Authentication2FAMode);
            Assert.Equal(ctx.AuthenticationMode, settings.AuthenticationMode);
            Assert.Equal(ctx.IpPlatformSettings.ClientId, settings.IpPlatformSettings.ClientId);
            Assert.Equal(ctx.IpPlatformSettings.ClientSecret, settings.IpPlatformSettings.ClientSecret);

            _cryptoService.ReceivedWithAnyArgs(1).Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
            Assert.Equal(ctx.AdfsSettings.RelyingPartyTrustId, settings.AdfsSettings.RelyingPartyTrustId);
            Assert.Equal("cert", settings.AdfsSettings.Certificate);
            Assert.Equal("enc", settings.AdfsSettings.ClientId);

            Assert.Equal(ctx.IntegrationServerPort, settings.IntegrationServerPort);

            Assert.Equal(ctx.CookieConsentSettings, settings.CookieConsentSettings);
        }
    }
}