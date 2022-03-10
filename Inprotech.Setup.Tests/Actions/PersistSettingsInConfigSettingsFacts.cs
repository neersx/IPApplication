using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class PersistSettingsInConfigSettingsFacts
    {
        public class IpPlatformSettingsFacts
        {
            [Fact]
            public void CallsPersistConfigWithCorrectParameters()
            {
                var f = new Fixture();

                f.Context["IpPlatformSettings"] = new IpPlatformSettings("SomeClientId", "This is a Secret!");
                f.Context["AuthenticationMode"] = "Forms,Windows,Sso";
                f.Context["PrivateKey"] = "key";

                f.Subject.Run(f.Context, f.EventStream);

                f.InprotechServerpersistingConfigMgr.Received(1).SetIpPlatformSettings((string) f.Context["InprotechConnectionString"], (string) f.Context["PrivateKey"], (IpPlatformSettings) f.Context["IpPlatformSettings"]);
            }

            [Fact]
            public void DoesNotCallPersistSettingsIfIpPlatformSettingsIsNull()
            {
                var f = new Fixture();
                f.Context["AuthenticationMode"] = "Forms,Windows,Sso";
                f.Context["IpPlatformSettings"] = null;

                f.Subject.Run(f.Context, f.EventStream);

                f.InprotechServerpersistingConfigMgr.Received(0).SetIpPlatformSettings(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<IpPlatformSettings>());
            }

            [Fact]
            public void DoesNotCallPersistSettingsIfIpPlatformSettingsNotSet()
            {
                var f = new Fixture();
                f.Context["AuthenticationMode"] = "Forms,Windows";
                f.Subject.Run(f.Context, f.EventStream);

                f.InprotechServerpersistingConfigMgr.Received(0).SetIpPlatformSettings(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<IpPlatformSettings>());
            }
        }

        public class AdfsSettingsFacts
        {
            [Fact]
            public void CallsPersistConfigWithCorrectParameters()
            {
                var f = new Fixture();
                var settings = new AdfsSettings {Certificate = "cert", ClientId = "client", RelyingPartyTrustId = "r", ServerUrl = "http://a.com"};

                f.Context["PrivateKey"] = "a";
                f.Context["AdfsSettings"] = settings;
                f.Context["AuthenticationMode"] = "Forms,Windows,Sso,Adfs";

                AdfsSettings resultSettings = null;
                var resultKey = string.Empty;
                f.CryptoService.When(x => x.Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>()))
                 .Do(x =>
                 {
                     resultKey = x.ArgAt<string>(0);
                     resultSettings = x.ArgAt<AdfsSettings>(1);
                 });

                f.Subject.Run(f.Context, f.EventStream);
                Assert.Equal(f.Context["PrivateKey"], resultKey);
                Assert.Equal(settings.ToString(), resultSettings.ToString());
                f.PersistingConfigManager.Received(1).SetValues(Arg.Any<string>(), Arg.Any<Dictionary<string, string>>());
            }

            [Fact]
            public void DoesNotCallPersistSettingsIfAdfsSettingsNotSet()
            {
                var f = new Fixture();
                f.Context["PrivateKey"] = "a";
                f.Context["AuthenticationMode"] = "Forms,Windows,Sso,Adfs";
                f.Subject.Run(f.Context, f.EventStream);

                f.CryptoService.DidNotReceive().Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
                f.PersistingConfigManager.DidNotReceive().SetValues(Arg.Any<string>(), Arg.Any<Dictionary<string, string>>());
            }

            [Fact]
            public void DoesNotSaveSettingsIfAuthModeAdfsIsDisabled()
            {
                var f = new Fixture();
                var settings = new AdfsSettings {Certificate = "cert", ClientId = "client", RelyingPartyTrustId = "r", ServerUrl = "http://a.com"};
                f.Context["PrivateKey"] = "a";
                f.Context["AdfsSettings"] = settings;
                f.Context["AuthenticationMode"] = "Forms,Windows,Sso";

                f.Subject.Run(f.Context, f.EventStream);
                f.CryptoService.DidNotReceive().Encrypt(Arg.Any<string>(), Arg.Any<AdfsSettings>());
                f.PersistingConfigManager.DidNotReceive().SetValues(Arg.Any<string>(), Arg.Any<Dictionary<string, string>>());
            }
        }

        public class AuthModeSettingsFacts
        {
            [Fact]
            public void CallsPersistConfigWithCorrectParameters()
            {
                var f = new Fixture();
                var modes = "Forms,Windows,Sso,Adfs";
                f.Context["AuthenticationMode"] = modes;
                f.Subject.Run(f.Context, f.EventStream);

                f.InprotechServerpersistingConfigMgr.Received(1).SaveAuthMode((string) f.Context["InprotechConnectionString"], modes);
            }

            [Fact]
            public void DoesNotCallPersistSettingsIfAuthenticationModeNotSet()
            {
                var f = new Fixture();
                f.Subject.Run(f.Context, f.EventStream);

                f.InprotechServerpersistingConfigMgr.DidNotReceive().SaveAuthMode(Arg.Any<string>(), Arg.Any<string>());
            }
        }

        class Fixture
        {
            public Fixture()
            {
                InprotechServerpersistingConfigMgr = Substitute.For<IInprotechServerPersistingConfigManager>();
                CryptoService = Substitute.For<ICryptoService>();
                PersistingConfigManager = Substitute.For<IPersistingConfigManager>();
                AdfsConfigPersistence = new AdfsConfigPersistence("localdb.", CryptoService, PersistingConfigManager); //Substitute.For<IAdfsConfigPersistence>();
                Subject = new PersistSettingsInConfigSettings(InprotechServerpersistingConfigMgr, AdfsConfigPersistence);

                Context = new Dictionary<string, object>();
                EventStream = Substitute.For<IEventStream>();
                Context["InprotechConnectionString"] =
                    new SqlConnectionStringBuilder(
                                                   "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                        .ConnectionString;
            }

            public IInprotechServerPersistingConfigManager InprotechServerpersistingConfigMgr { get; }
            public PersistSettingsInConfigSettings Subject { get; }
            public IDictionary<string, object> Context { get; }
            public IEventStream EventStream { get; }
            public IAdfsConfigPersistence AdfsConfigPersistence { get; }

            public ICryptoService CryptoService { get; }
            public IPersistingConfigManager PersistingConfigManager { get; }
        }
    }
}