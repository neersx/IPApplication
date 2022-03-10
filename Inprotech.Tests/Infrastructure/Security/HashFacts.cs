using Inprotech.Infrastructure.Security;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    public class HashFacts
    {
        [Fact]
        public void ShouldHashString()
        {
            var toHash = "the quick brown fox jumps over the lazy dog";
            var expected = "77add1d5f41223d5582fca736a5cb335";
            var result = Hash.Md5(toHash);

            Assert.Equal(expected, result);
        }
    }
}
