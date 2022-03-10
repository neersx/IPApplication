using Inprotech.Integration.Schedules.Extensions.Epo;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Epo
{
    public class EpoSchedulePrerequisiteFacts
    {
        public EpoSchedulePrerequisiteFacts()
        {
            _f = new EpoSchedulePrerequisite(_epoIntegrationSettings);
        }

        readonly IEpoIntegrationSettings _epoIntegrationSettings = Substitute.For<IEpoIntegrationSettings>();
        readonly EpoSchedulePrerequisite _f;

        [Fact]
        public void ReturnsFalseIfKeysAreBlank()
        {
            _epoIntegrationSettings.Keys.Returns(new EpoKeys("abcd", "  "));
            var result = _f.Validate(out var returnCode);

            Assert.False(result);
            Assert.Equal("epo-missing-keys", returnCode);
        }

        [Fact]
        public void ReturnsTrueIfKeysAreValid()
        {
            _epoIntegrationSettings.Keys.Returns(new EpoKeys("Rob", "Bran"));
            var result = _f.Validate(out var returnCode);

            Assert.True(result);
            Assert.Empty(returnCode);
        }
    }
}