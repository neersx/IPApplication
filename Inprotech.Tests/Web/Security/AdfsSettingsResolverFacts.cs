using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Web.Security;
using InprotechKaizen.Model.Components.System.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class AdfsSettingsResolverFacts
    {
        public AdfsSettingsResolverFacts()
        {
            var settings = Substitute.For<IConfigSettings>();
            Func<string, IGroupedConfig> groupedConfig = s => new GroupedConfig(ConfigPrefix, settings);
            var cryptoService = Substitute.For<ICryptoService>();

            settings.GetValues(AdfsUrlKey, ClientIdKey, RelyingPartyAddressKey, CertificateStringKey, RedirectUrlKey)
                    .Returns(new Dictionary<string, string>
                    {
                        {AdfsUrlKey, "server"},
                        {ClientIdKey, "clientId"},
                        {RelyingPartyAddressKey, "relying"},
                        {CertificateStringKey, "cert"},
                        {RedirectUrlKey, "{\"key\": \"http://abcd\"}"}
                    });
            cryptoService.Decrypt("clientId").Returns("encClientId");
            cryptoService.Decrypt("relying").Returns("encRelying");
            cryptoService.Decrypt("cert").Returns("encCert");
            _subject = new AdfsSettingsResolver(groupedConfig, cryptoService);
        }

        const string ConfigPrefix = "InprotechServer.Adfs";
        const string AdfsUrlKey = ConfigPrefix + ".Server";
        const string ClientIdKey = ConfigPrefix + ".ClientId";
        const string RelyingPartyAddressKey = ConfigPrefix + ".RelyingParty";
        const string CertificateStringKey = ConfigPrefix + ".Certificate";
        const string RedirectUrlKey = ConfigPrefix + ".RedirectUrls";
        readonly AdfsSettingsResolver _subject;

        [Fact]
        public void ResolveShouldReturnSettings()
        {
            var r = _subject.Resolve();
            Assert.Equal("server", r.AdfsUrl);
            Assert.Equal("encClientId", r.ClientId);
            Assert.Equal("encRelying", r.RelyingPartyAddress);
            Assert.Equal("encCert", r.Certificate);
            Assert.True(new List<string> {"http://abcd"}.SequenceEqual(r.RedirectUrls));
        }
    }
}