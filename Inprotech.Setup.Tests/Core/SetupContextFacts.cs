using Inprotech.Setup.Core;
using Microsoft.Web.Administration;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class SetupContextFacts
    {
        [Fact]
        public void ShouldAssignCorrespondingValuesFromIisAppInfo()
        {
            var iisAppInfo = new IisAppInfo
            {
                Site = "a",
                VirtualPath = "b",
                PhysicalPath = "c",
                ApplicationPool = "d",
                Protocols = "e",
                ServiceUser = "f",
                IsBuiltInServiceUser = true,
                IdentityType = ProcessModelIdentityType.LocalSystem,
                Username = "g",
                Password = "h",
                BindingUrls = "i",
                WebConfig = new WebConfig
                {
                    InprotechConnectionString = "j",
                    AuthenticationMode = "k",
                    SmtpServer = "m",
                    CookieName = "n",
                    CookiePath = "o",
                    CookieDomain = "j",
                    TimeoutInterval = "p",
                    FeaturesAvailable = new[] { "l" }
                }
            };

            var ctx = new SetupContext { PairedIisApp = iisAppInfo };

            Assert.Equal("a", ctx["Site"]);
            Assert.Equal("b", ctx["VirtualPath"]);
            Assert.Equal("c", ctx["PhysicalPath"]);
            Assert.Equal("d", ctx["ApplicationPool"]);
            Assert.Equal("e", ctx["Protocols"]);
            Assert.Equal("f", ctx["ServiceUser"]);
            Assert.True((bool)ctx["IsBuiltInServiceUser"]);
            Assert.Equal("LocalSystem", ctx["ProcessModelIdentityType"]);
            Assert.Equal("g", ctx["Username"]);
            Assert.Equal("h", ctx["Password"]);
            Assert.Equal("i", ctx["BindingUrls"]);
            Assert.Equal("j", ctx["InprotechConnectionString"]);
            Assert.Equal("k", ctx["IisAuthenticationMode"]);
            Assert.Equal(new[] { "l" }, ctx["FeaturesAvailable"]);
            Assert.Equal("m", ctx["SmtpServer"]);
            Assert.Equal("n", ctx["SessionCookieName"]);
            Assert.Equal("o", ctx["SessionCookiePath"]);
            Assert.Equal("j", ctx["SessionCookieDomain"]);
            Assert.Equal("p", ctx["SessionTimeout"]);
        }

        [Fact]
        public void ShouldAssignCorrespondingValuesFromSetupSettings()
        {
            var ctx = new SetupContext
            {
                SetupSettings = new SetupSettings
                {
                    IisSite = "a",
                    IisPath = "b",
                    StorageLocation = "c",
                    DatabaseUsername = "d",
                    DatabasePassword = "e",
                    NewInstancePath = "f",
                    AuthenticationMode = "Forms,Sso",
                    IntegrationServerPort = "80",
                    RemoteIntegrationServerUrl = "abc",
                    RemoteStorageServiceUrl = "xyz",
                    CookiePath = "i",
                    CookieName = "j",
                    CookieDomain = "k",
                    IsE2EMode = true,
                    BypassSslCertificateCheck = true
                }
            };

            Assert.Equal("a", ctx["Site"]);
            Assert.Equal("b", ctx["VirtualPath"]);
            Assert.Equal("c", ctx["StorageLocation"]);
            Assert.Equal("d", ctx["Database.Username"]);
            Assert.Equal("e", ctx["Database.Password"]);
            Assert.Equal("f", ctx.NewInstancePath);
            Assert.Equal("Forms,Sso", ctx.AuthenticationMode);
            Assert.Equal("80", ctx.IntegrationServerPort);
            Assert.Equal("abc", ctx.RemoteIntegrationServerUrl);
            Assert.Equal("xyz", ctx.RemoteStorageServiceUrl);
            Assert.Equal("i", ctx["SessionCookiePath"]);
            Assert.Equal("j", ctx["SessionCookieName"]);
            Assert.Equal("k", ctx["SessionCookieDomain"]);
            Assert.Equal(true, ctx["IsE2EMode"]);
            Assert.Equal(true, ctx["BypassSslCertificateCheck"]);
        }
    }
}