using System.Data.SqlClient;
using System.IO;
using System.Xml.Linq;
using Inprotech.Setup.Core;
using Microsoft.Web.Administration;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class WebConfigReaderFacts
    {
        const string WebConfigRelease8AndBeyond = ".\\WebConfigs";

        readonly IAuthenticationMode _authMode = Substitute.For<IAuthenticationMode>();
        readonly IAvailableFeatures _availableFeatures = Substitute.For<IAvailableFeatures>();
        readonly IWebConfigBackupReader _webConfigBackupReader = Substitute.For<IWebConfigBackupReader>();

        IWebConfigReader CreateSubject(string mode = "Windows", string baseFeatures = "AppsBridgeHttpModule")
        {
            _authMode.Resolve(Arg.Any<XElement>()).Returns(mode);
            _availableFeatures.Resolve(Arg.Any<XElement>(), Arg.Any<ManagedPipelineMode>()).Returns(new[] {baseFeatures});

            return new WebConfigReader(new FileSystem(), _availableFeatures, _authMode, _webConfigBackupReader);
        }

        [Theory]
        [InlineData("windows")]
        [InlineData("forms")]
        public void SetResultsFromAuthenticationModeResolver(string mode)
        {
            var reader = CreateSubject(mode);
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.Equal(mode, webconfig.AuthenticationMode);

            _authMode.Received(1).Resolve(Arg.Any<XElement>());
        }

        [Theory]
        [InlineData("")]
        [InlineData("AppsBridgeHttpModule")]
        public void SetResultsFromAvailableFeaturesResolver(string feature)
        {
            var reader = CreateSubject("windows", feature);
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.Contains(feature, webconfig.FeaturesAvailable);

            _availableFeatures.Received(1).Resolve(Arg.Any<XElement>(), Arg.Any<ManagedPipelineMode>());
        }

        [Theory]
        [InlineData(ManagedPipelineMode.Classic)]
        [InlineData(ManagedPipelineMode.Integrated)]
        public void PassesManagedPipelineModeToAvailableFeatureResolver(ManagedPipelineMode mode)
        {
            var reader = CreateSubject();
            reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), mode);

            _availableFeatures.Received(1).Resolve(Arg.Any<XElement>(), mode);
        }

        [Fact]
        public void ReadsWebConfigBackupfile()
        {
            var webConfigBackupData = new WebConfigBackup {Exists = true, AuthenticationMode = "Some selected auth modes"};

            _webConfigBackupReader.Read(Arg.Any<string>()).Returns(webConfigBackupData);
            var reader = CreateSubject();

            var data = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            _webConfigBackupReader.Received(1).Read(Path.GetFullPath(WebConfigRelease8AndBeyond));
            Assert.Equal(webConfigBackupData, data.Backup);
        }

        [Fact]
        public void ReturnsAdministrationConnectionString()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotNull(webconfig.InprotechAdministrationConnectionString);

            var connectionString = new SqlConnectionStringBuilder(webconfig.InprotechAdministrationConnectionString);
            Assert.Equal("IPDEV", connectionString.InitialCatalog);
            Assert.True(connectionString.IntegratedSecurity);
        }

        [Fact]
        public void ReturnsConnectionString()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotNull(webconfig.InprotechConnectionString);

            var connectionString = new SqlConnectionStringBuilder(webconfig.InprotechConnectionString);
            Assert.Equal("Inprotech", connectionString.ApplicationName);
            Assert.Equal(".", connectionString.DataSource);
            Assert.Equal("IPDEV", connectionString.InitialCatalog);
            Assert.True(connectionString.PersistSecurityInfo);
            Assert.Equal("SYSADM", connectionString.UserID);
            Assert.Equal("SYSADM", connectionString.Password);
        }

        [Fact]
        public void ReturnsCookieName()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotEmpty(webconfig.CookieName);

            Assert.Equal(".CPASSInprotechBlahBlah", webconfig.CookieName);
        }

        [Fact]
        public void ReturnsCookiePath()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotEmpty(webconfig.CookieName);

            Assert.Equal("/", webconfig.CookiePath);
        }

        [Fact]
        public void ReturnsCookieDomain()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotEmpty(webconfig.CookieName);

            Assert.Equal("localhost", webconfig.CookieDomain);
        }

        [Fact]
        public void ReturnsIntegrationAdministrationConnectionString()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotNull(webconfig.IntegrationAdministrationConnectionString);

            var connectionString = new SqlConnectionStringBuilder(webconfig.IntegrationAdministrationConnectionString);
            Assert.Equal("IPDEVIntegration", connectionString.InitialCatalog);
            Assert.True(connectionString.IntegratedSecurity);
        }

        [Fact]
        public void ReturnsIntegrationConnectionString()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotNull(webconfig.IntegrationConnectionString);

            var connectionString = new SqlConnectionStringBuilder(webconfig.IntegrationConnectionString);
            Assert.Equal("Inprotech", connectionString.ApplicationName);
            Assert.Equal(".", connectionString.DataSource);
            Assert.Equal("IPDEVIntegration", connectionString.InitialCatalog);
            Assert.True(connectionString.PersistSecurityInfo);
            Assert.Equal("SYSADM", connectionString.UserID);
            Assert.Equal("SYSADM", connectionString.Password);
        }

        [Fact]
        public void VerifyInprotechVersionFriendlyName()
        {
            var reader = CreateSubject();
            var webConfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);
            Assert.Equal("16R17", webConfig.InprotechVersionFriendlyName);
        }

        [Fact]
        public void ReturnsNullIfFileNotFound()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read("somepath", ManagedPipelineMode.Integrated);

            Assert.Null(webconfig);
        }

        [Fact]
        public void ReturnsSmtpServerString()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotEmpty(webconfig.SmtpServer);

            Assert.Equal("smtp.ourdomain.com", webconfig.SmtpServer);
        }

        [Fact]
        public void ReturnsTimeoutvalue()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.NotEmpty(webconfig.TimeoutInterval);

            Assert.Equal("20", webconfig.TimeoutInterval);
        }

        [Fact]
        public void ReturnsHstsValue()
        {
            var reader = CreateSubject();
            var webconfig = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond), ManagedPipelineMode.Integrated);

            Assert.Equal("True",webconfig.EnableHsts);

            Assert.Equal("31536000", webconfig.HstsMaxAge);
        }
    }
}