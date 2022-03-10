using Inprotech.Integration.Innography;
using Inprotech.Integration.Schedules.Extensions.Innography;
using NSubstitute;
using NSubstitute.Core.Arguments;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Innography
{
    public class InnographySchedulePrerequisiteFacts
    {
        [Fact]
        public void ReturnsMissingPlatformRegistrationIfNotEnabled()
        {
            var resolver = Substitute.For<IInnographySettingsResolver>();
            resolver.Resolve(Arg.Any<string>()).Returns(new InnographySetting
            {
                IsIPIDIntegrationEnabled = false
            });

            string result;
            var subject = new InnographySchedulePrerequisite(resolver);
            Assert.False(subject.Validate(out result));
            Assert.Equal("missing-platform-registration-innography", result);
        }

        [Fact]
        public void ReturnsTrueWhenEnabled()
        {
            var resolver = Substitute.For<IInnographySettingsResolver>();
            resolver.Resolve(Arg.Any<string>()).Returns(new InnographySetting
            {
                IsIPIDIntegrationEnabled = true
            });

            var subject = new InnographySchedulePrerequisite(resolver);
            Assert.True(subject.Validate(out var result));
        }
    }
}