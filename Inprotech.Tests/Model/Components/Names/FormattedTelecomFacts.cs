using InprotechKaizen.Model.Components.Names;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class FormattedTelecomFacts
    {
        [Theory]
        [InlineData("x364", null, null, null, "364")]
        [InlineData("+61 02 02 4283 7363 x567", "61", "02", "02 4283 7363", "567")]
        [InlineData("+1 414 382 3900", "1", "414", "382 3900", null)]
        [InlineData("1800 808 993", null, "1800", "808 993", null)]
        [InlineData("+62 0418 405 970", "+62", null, "0418 405 970", null)]
        [InlineData("someone@microsoft.com", null, null, "someone@microsoft.com", null)]
        public void ShouldFormatTelecomAccordingly(string expected, string isd, string areaCode, string number, string extension)
        {
            Assert.Equal(expected, FormattedTelecom.For(isd, areaCode, number, extension));
        }
    }
}