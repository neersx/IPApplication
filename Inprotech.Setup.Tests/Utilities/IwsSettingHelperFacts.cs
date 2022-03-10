using Inprotech.Setup.Actions.Utilities;
using Xunit;

namespace Inprotech.Setup.Tests.Utilities
{
    public class IwsSettingHelperFacts
    {
        public IwsSettingHelper GetSubject()
        {
            return new IwsSettingHelper();
        }

        [Fact]
        public void GeneratePrivateKey()
        {
            var subject = GetSubject();

            var result = subject.GeneratePrivateKey();
            Assert.NotNull(result);
            Assert.Equal(result.Length, 16);
        }

        [Fact]
        public void IsValidLocalAddress()
        {
            var subject = GetSubject();

            var result = subject.IsValidLocalAddress("localhost");
            Assert.True(result);
            result = subject.IsValidLocalAddress("invalid-host");
            Assert.False(result);
        }
    }
}
