using System.Text;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.Schedules;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingManifestControllerFacts : FactBase
    {
        public class SettingManifestControllerFixture : IFixture<SettingManifestController>
        {
            public SettingManifestControllerFixture()
            {
                ArtifactService = Substitute.For<IArtifactsService>();
                SettingYamlMapper = Substitute.For<ISettingYamlMapper>();
                Subject = new SettingManifestController(ArtifactService, SettingYamlMapper);
            }

            public IArtifactsService ArtifactService { get; set; }
            public ISettingYamlMapper SettingYamlMapper { get; set; }
            public SettingManifestController Subject { get; }
        }

        [Fact]
        public void ShouldCallCorrectMethodsOnMapperAndCompression()
        {
            var fixture = new SettingManifestControllerFixture();
            var settings = new IManageSettings.SiteDatabaseSettings {AccessTokenUrl = Fixture.String(), Server = Fixture.String()};
            var yaml = new StringBuilder(Fixture.String());
            fixture.SettingYamlMapper.GetYamlStringForSiteConfig(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(yaml);

            fixture.Subject.GetYaml(settings);

            fixture.SettingYamlMapper.Received(1).GetYamlStringForSiteConfig(settings);
            fixture.ArtifactService.Received(1).Compress("manifest.yaml", yaml.ToString());
        }
    }
}