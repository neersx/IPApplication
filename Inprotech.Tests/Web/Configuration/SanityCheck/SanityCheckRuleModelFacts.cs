using Inprotech.Web.Configuration.SanityCheck;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckRuleModelFacts
    {
        [Theory]
        [InlineData(null, false, false, false)]
        [InlineData(0, true, false, false)]
        [InlineData(1, false, true, false)]
        [InlineData(2, false, false, true)]
        [InlineData(3, false, true, true)]
        public void SetStatusIncludeFlags(int? flag, bool isDead, bool isPending, bool isRegistered)
        {
            var f = new CaseRelatedDataModel();
            f.SetStatusIncludeFlags((short?) flag);

            Assert.Equal(isDead, f.StatusIncludeDead);
            Assert.Equal(isPending, f.StatusIncludePending);
            Assert.Equal(isRegistered, f.StatusIncludeRegistered);
        }

        [Theory]
        [InlineData(null, false, false)]
        [InlineData(1, false, true)]
        [InlineData(2, true, false)]
        [InlineData(3, true, true)]
        public void SetEventIncludeFlags(int? flag, bool isDue, bool isOccurred)
        {
            var f = new OtherDataModel();
            f.SetEventIncludeFlags((short?) flag);

            Assert.Equal(isDue, f.EventIncludeDue);
            Assert.Equal(isOccurred, f.EventIncludeOccurred);
        }
    }
}