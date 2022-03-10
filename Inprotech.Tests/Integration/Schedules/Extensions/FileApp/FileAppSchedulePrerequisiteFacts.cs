using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.Schedules.Extensions.FileApp;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.FileApp
{
    public class FileAppSchedulePrerequisiteFacts
    {
        [Fact]
        public void ReturnsMissingPlatformRegistrationIfNotEnabled()
        {
            var resolver = Substitute.For<IFileSettingsResolver>();
            resolver.Resolve().Returns(new FileSettings
            {
                IsEnabled = false
            });

            string result;
            var subject = new FileAppSchedulePrerequisite(resolver);
            Assert.False(subject.Validate(out result));
            Assert.Equal("missing-platform-registration-file", result);
        }

        [Fact]
        public void ReturnsTrueWhenEnabled()
        {
            var resolver = Substitute.For<IFileSettingsResolver>();
            resolver.Resolve().Returns(new FileSettings
            {
                IsEnabled = true
            });

            var subject = new FileAppSchedulePrerequisite(resolver);
            Assert.True(subject.Validate(out var result));
        }
    }
}