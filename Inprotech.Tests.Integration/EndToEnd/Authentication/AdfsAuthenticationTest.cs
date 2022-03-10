using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Settings;
using Newtonsoft.Json;
using NUnit.Framework;
using CryptoService = Inprotech.Tests.Integration.Utils.CryptoService;

namespace Inprotech.Tests.Integration.EndToEnd.Authentication
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "AuthenticationMode", "Forms,Windows,Sso,Adfs", ConfigSettingsKey = "InprotechServer.AppSettings.AuthenticationMode")]
    public class AdfsAuthenticationTest : IntegrationTest
    {
        [TearDown]
        public void TearDown()
        {
            using (var setup = new DbSetup())
            {
                const string appsettings = "InprotechServer.AppSettings.AuthenticationMode";
                const string authenticationModeValues = "Forms,Windows,Sso";

                var setting = setup.DbContext.Set<ConfigSetting>().Single(_ => _.Key.Equals(appsettings));
                setting.Value = authenticationModeValues;
                setup.DbContext.SaveChanges();
            }
        }

        [TestCase(BrowserType.Chrome, Ignore = "To be reinstated in SDR-31119")]
        [TestCase(BrowserType.FireFox, Ignore = "To be reinstated in SDR-31119")]
        public void AdfsLoginTest(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).CreateAdfsUser();
            Setup();

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/priorartold/search", false, true);
            Assert.True(driver.WithJs().GetUrl().Contains("/apps/signin"), "despite going to protected page, should end up on login page");

            var page = new AuthenticationPage(driver);
            page.SignInWithTheAdfs();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl().Contains("adfs/oauth2/authorize?response_type=code"));
            Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "should have signin page in resumeUri");

            var adfs = new AdfsAuthentication(driver.WrappedDriver);
            adfs.SignIn(user.Email, user.Password);
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl().Contains("apps/#/priorartold/search"), 20000);

            driver.WrappedDriver.Url = Env.RootUrl + "/signin";
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(true).Contains("portal"), 20000);

            page.Logout();
            Assert.True(driver.WithJs().GetUrl().Contains("adfs/ls/?wa=wsignout1.0"), "should go to cloud logout page");
            Assert.True(driver.WithJs().GetUrl().Contains(HttpUtility.UrlEncode("/apps/signin")), "should have signin page in resumeUri");
        }

        void Setup()
        {
            using (var setup = new DbSetup())
            {
                const string configPrefix = "InprotechServer.Adfs.";
                const string adfsUrlKey = configPrefix + "Server";
                const string clientIdKey = configPrefix + "ClientId";
                const string relyingPartyAddressKey = configPrefix + "RelyingParty";
                const string certificateStringKey = configPrefix + "Certificate";
                const string redirectUrlsKey = configPrefix + "RedirectUrls";
                
                setup.Insert(new ConfigSetting(adfsUrlKey) { Value = "https://ssotest-vm1.cloudapp.net" });
                setup.Insert(new ConfigSetting(clientIdKey) { Value = "7XWAkW5CeFqdc8wXWLqxlnyD6DV7Qzesa9pIYlJRp7pc7KhEWQsCIXuxCdNgsBdv" });//92cd67dd-9423-41f9-b7a7-ee556a94cfeb
                setup.Insert(new ConfigSetting(relyingPartyAddressKey) { Value = "hgIuGD7S8OxHbQoh5BCFKQ==" });//InprotechTrust
                var cert = @"-----BEGIN CERTIFICATE-----
MIIC5jCCAc6gAwIBAgIQTv4QKvMFl5tPcivJ+NeqIDANBgkqhkiG9w0BAQsFADAv
MS0wKwYDVQQDEyRBREZTIFNpZ25pbmcgLSBzc290ZXN0LmNwYWdsb2JhbC5jb20w
HhcNMjAxMjA2MjMwMDEzWhcNMjMxMjA2MjMwMDEzWjAvMS0wKwYDVQQDEyRBREZT
IFNpZ25pbmcgLSBzc290ZXN0LmNwYWdsb2JhbC5jb20wggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDP3ZYgLj/pUovzeCL1KkmX952OfcgoEkb+wuxnLqGl
/koI9pVfyfe0Xr1DkPNLtzusUYj3o7NAL3uoZkrf+chou19wzyPB2TDKXJmmmL/v
ya54qakv+wTRWcQs/Cxx4IoKdqgcgDF3SIkWUk2SgSNhpJ0TM0WKZVcPWk6yVn2w
7FrHnmMeohcrW7341As41vOLSWQlEVWAm4aGC/yzXzbIF57bNxqtWa4Tjp1I8fjc
J6MoLV8hN0/umY9ZxEXoYatV2hFOzoum50q1t/HcZrQYenfmUFrw1KyPOgrKT+MS
/fGM9Uz61TjwwNp/dyPwIxzZ3+IXy03aQJWNUeZHxYcDAgMBAAEwDQYJKoZIhvcN
AQELBQADggEBACjrqh2YEDDMKeoIADgkZ9Z3/1T3hueh9y2q0Ms4sDk+qBlfW86K
qcAjRBWIP/UiHqKkvKQ8XFLspD2hya3nMUGoRdQWgBqXUR32nBgKOKeELot2cwwH
Bss9Q7W7tWSmbaQmSXfatsJplRja6L1PLYI8KSYu1QH5PX3L8dWBD8s2mJdkxNXp
XjgWP0LuHyd12BB4ku9CJ0KeCXEGZfUkrbauGkabZdzFvAnH49KFlPZMMcJVuc7u
vdA73sLr0DkFCKhNNf1O+6IsPGSxY5qGwLoRM0l3BMKz7YCCUY3L4IWMT7RY7Aeg
H4NC3PyVZsFCAmGyxOCFs6i1UXoOWgLfKTE=
-----END CERTIFICATE-----
".Replace("-----END CERTIFICATE-----", string.Empty).Replace("-----BEGIN CERTIFICATE-----", string.Empty).Trim();
                setup.Insert(new ConfigSetting(certificateStringKey) { Value = CryptoService.Encrypt(cert) });

                var redirectUrls = new Dictionary<string, string>
                {
                    {"url-0", $"{Env.RootUrl.ToLower()}/api/signin/adfsreturn"}
                };

                if (redirectUrls["url-0"] != "http://localhost/cpainproma/apps/api/signin/adfsreturn")
                {
                    redirectUrls.Add("url-1", "http://localhost/cpainproma/apps/api/signin/adfsreturn");
                }

                setup.Insert(new ConfigSetting(redirectUrlsKey)
                {
                    Value = JsonConvert.SerializeObject(redirectUrls)
                });
            }
        }
    }
}
