using Inprotech.IntegrationServer.PtoAccess.Epo;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo
{
    public class EpoUtilityFacts
    {
        [Fact]
        public void ShouldFormatEpNumber()
        {
            const string appNumber = "1234.1";

            var r = Utility.FormatEpNumber(appNumber);

            Assert.Equal("EP1234", r);
        }
    }
}