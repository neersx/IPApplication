using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.DocumentGeneration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration
{
    public class SettingsResolverFacts
    {
        readonly IGroupedConfig _configSettings = Substitute.For<IGroupedConfig>();

        [Theory]
        [InlineData("ContentId", EmbedImagesUsing.ContentId)]
        [InlineData("DataStream", EmbedImagesUsing.DataStream)]
        public void ShouldResolveEmbedImageUsingSetting(string settingValue, EmbedImagesUsing expectedValue)
        {
            _configSettings.GetValueOrDefault<string>("Email.EmbedImagesUsing").Returns(settingValue);

            var subject = new SettingsResolver(x => _configSettings);

            var result = subject.Resolve();

            Assert.Equal(expectedValue, result.EmbedImagesUsing);
        }

        [Fact]
        public void ShouldDefaultEmbedImagesUsingToContentId()
        {
            var subject = new SettingsResolver(x => _configSettings);

            var result = subject.Resolve();

            Assert.Equal(EmbedImagesUsing.ContentId, result.EmbedImagesUsing);
        }
    }
}