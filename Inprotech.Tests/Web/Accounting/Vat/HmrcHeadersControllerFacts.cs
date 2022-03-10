using System.Linq;
using Http=System.Net.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Profiles;
using Microsoft.Owin;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class FraudPreventionHeadersFacts
    {
        public class FraudPreventionHeadersFixture : IFixture<FraudPreventionHeaders>
        {
            public FraudPreventionHeadersFixture(InMemoryDbContext db)
            {
                Db = db;
                AppVersion = Substitute.For<IAppVersion>();
                AppSettingsProvider = Substitute.For<IAppSettingsProvider>();
                SecurityContext = Substitute.For<ISecurityContext>();

                Subject = new FraudPreventionHeaders(Db, AppVersion, AppSettingsProvider, SecurityContext);
            }
            
            InMemoryDbContext Db { get; }
            public IAppVersion AppVersion { get; set; }
            public IAppSettingsProvider AppSettingsProvider { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public FraudPreventionHeaders Subject { get; }

            public ExternalSettings AddDefaultHmrcHeaders(string eSettings)
            {
                return new ExternalSettings(KnownExternalSettings.HmrcHeaders) { Settings = eSettings }.In(Db);
            }

            public Name AddDefaultHmrcEntityName()
            {
                return new Name(123) { LastName = "Test Name"}.In(Db);
            }
            public SiteControl AddDefaultHmrcSiteControl()
            {
                return new SiteControl("HOMENAMENO", 123) {}.In(Db);
            }

            public ExternalSettings AddDefaultHmrcSettings(string eSettings)
            {
                eSettings = eSettings == string.Empty ? "{\"RedirectUri\": \"http://localhost/cpainproma/apps/hmrc/accounting/vat\", \"ClientId\": \"pfls3O23xL5xxckKDEXwxv7j7OKZIZg9RPiORCmT9i0=\", \"ClientSecret\": \"iq8E6wqWZh4+lZCEiMfrwA75c/bOzfVz8hTQlBTyppyzb9HE6RyuPlmL4QMdCujl\", \"IsProduction\": true, \"HmrcApplicationName\": \"Inprotech-Internal\"}" : eSettings;
                return new ExternalSettings(KnownExternalSettings.HmrcVatSettings) { Settings = eSettings }.In(Db);
            }

            public FraudPreventionHeadersFixture WithPublicIpAddress(string ipAddress)
            {
                AppSettingsProvider["PublicIpAddress"].Returns(ipAddress);
                return this;
            }

            public FraudPreventionHeadersFixture WithAppVersion(string version)
            {
                AppVersion.CurrentVersion.Returns(version);
                return this;
            }

            public Http.HttpRequestMessage ConstructHttpRequest()
            {
                var httpRequest = new Http.HttpRequestMessage(Http.HttpMethod.Get, "http://localhost/api/products");
                httpRequest.Headers.Add("x-inprotech-current-timezone", "UTC+10:00");
                httpRequest.Headers.Add("x-inprotech-client-public-ip", "1.2.2.2");
                httpRequest.Properties["MS_OwinContext"] = new OwinContext();
                httpRequest.GetOwinContext().Environment.Add("Auth2FaMode", Fixture.String());
                httpRequest.GetOwinContext().Environment.Add("Auth2FaModeGranted", Fixture.Date());
                httpRequest.GetOwinContext().Request.RemoteIpAddress = Fixture.String();
                return httpRequest;
            }
        }

        public class HmrcHeaders : FactBase
        {
            [Fact]
            public void IncludeHmrcClientHeadersCorrectly()
            {
                var req = new Http.HttpRequestMessage();
                var s = new FraudPreventionHeadersFixture(Db);
                s.AddDefaultHmrcHeaders(string.Empty);
                s.AddDefaultHmrcSettings(string.Empty);
                s.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                
                s.Subject.Include(req, s.ConstructHttpRequest());
                Assert.Equal(string.Empty, req.Headers.First(x => x.Key == "Gov-Client-Public-Port").Value.First());
                Assert.Equal("UTC+10:00", req.Headers.First(x => x.Key == "Gov-Client-Timezone").Value.First());
                Assert.Equal("1.2.2.2", req.Headers.First(x => x.Key == "Gov-Client-Public-IP").Value.First());
            }

            [Fact]
            public void IncludeHmrcHeadersFromDbCorrectly()
            {
                var req = new Http.HttpRequestMessage();
                var s = new FraudPreventionHeadersFixture(Db);
                s.AddDefaultHmrcHeaders("Gov-Client-Connection-Method: Other-Web-App\\n Gov-Client-User-IDs: inprotech-carpels");
                s.AddDefaultHmrcSettings(string.Empty);
                s.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                
                s.Subject.Include(req, s.ConstructHttpRequest());
                Assert.Equal("UTC+10:00", req.Headers.First(x => x.Key == "Gov-Client-Timezone").Value.First());
                Assert.Equal("inprotech-carpels", req.Headers.First(x => x.Key == "Gov-Client-User-IDs").Value.First());
                Assert.Equal("Other-Web-App", req.Headers.First(x => x.Key == "Gov-Client-Connection-Method").Value.First());
            }

            [Fact]
            public void IncludeHmrcHeadersServerSideCorrectly()
            {
                var req = new Http.HttpRequestMessage();
                var s = new FraudPreventionHeadersFixture(Db).WithPublicIpAddress("8.8.8.8");
                s.AddDefaultHmrcHeaders(string.Empty);
                s.AddDefaultHmrcSettings(string.Empty);
                s.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                s.AddDefaultHmrcSiteControl();
                s.AddDefaultHmrcEntityName();
                
                s.Subject.Include(req, s.ConstructHttpRequest());
                Assert.Equal("WEB_APP_VIA_SERVER", req.Headers.First(x => x.Key == "Gov-Client-Connection-Method").Value.First());
                Assert.Equal("8.8.8.8", req.Headers.First(x => x.Key == "Gov-Vendor-Public-IP").Value.First());
                Assert.Equal("1.2.2.2", req.Headers.First(x => x.Key == "Gov-Client-Public-IP").Value.First());
                Assert.Equal("by=8.8.8.8&for=1.2.2.2", req.Headers.First(x => x.Key == "Gov-Vendor-Forwarded").Value.First());
                Assert.NotEqual(string.Empty, req.Headers.First(x => x.Key == "Gov-Vendor-License-IDs").Value.First());
                Assert.True(req.Headers.First(x => x.Key == "Gov-Client-Multi-Factor").Value.First().Contains("type=AUTH_CODE&timestamp="));
                Assert.True(req.Headers.First(x => x.Key == "Gov-Client-Multi-Factor").Value.First().Contains("&unique-reference="));
            }

            [Fact]
            public void IncludeHmrcVersionHeaderCorrectly()
            {
                var req = new Http.HttpRequestMessage();
                var s = new FraudPreventionHeadersFixture(Db).WithAppVersion("123");
                s.AddDefaultHmrcHeaders(string.Empty);
                s.AddDefaultHmrcSettings(string.Empty);
                s.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                
                s.Subject.Include(req, s.ConstructHttpRequest());
                Assert.Equal("WEB_APP_VIA_SERVER", req.Headers.First(x => x.Key == "Gov-Client-Connection-Method").Value.First());
                Assert.Equal("Inprotech-Internal=App123", req.Headers.First(x => x.Key == "Gov-Vendor-Version").Value.First());
                Assert.NotEqual(string.Empty, req.Headers.First(x => x.Key == "Gov-Vendor-License-IDs").Value.First());
                Assert.True(req.Headers.First(x => x.Key == "Gov-Vendor-License-IDs").Value.First().Contains("LicenseId="));
                Assert.NotEqual(string.Empty, req.Headers.First(x => x.Key == "Gov-Client-Local-IPs").Value.First());
            }
        }
    }
}