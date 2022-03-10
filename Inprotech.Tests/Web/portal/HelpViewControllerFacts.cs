using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Web.Portal;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class HelpViewControllerFacts
    {
        [Fact]
        public void ReturnsData()
        {
            var linkResolver = Substitute.For<IHelpLinkResolver>();
            var settings = Substitute.For<IConfigurationSettings>();
            var fileHelper = Substitute.For<IFileHelpers>();
            var configSetting = Substitute.For<IConfigSettings>();
            var f = new HelpViewController(linkResolver, settings, fileHelper, configSetting);

            fileHelper.ReadAllLines("../App License Attributions.txt")
                      .Returns(new[] { "a", "b" });
            configSetting[KnownSetupSettingKeys.ConfigurationKey].Returns($"{{\"{KnownSetupSettingKeys.CookieDeclarationHook}\":\"abc\"}}");
            linkResolver.Resolve().ReturnsForAnyArgs("http://www.abc.com");
            settings[KnownAppSettingsKeys.InprotechWikiLink].Returns("http://www.wiki.com");
            settings[KnownAppSettingsKeys.ContactUsEmailAddress].Returns("test@test.com");
            var r = f.GetHelpData();
            Assert.Equal("http://www.abc.com", r.InprotechHelpLink);
            Assert.Equal("http://www.wiki.com", r.WikiHelpLink);
            Assert.Equal("test@test.com", r.ContactUsEmailAddress);
            Assert.Equal(new[] { "a", "b" }, r.Credits);
            Assert.True(r.CookieConsentActive);
        }
    }
}