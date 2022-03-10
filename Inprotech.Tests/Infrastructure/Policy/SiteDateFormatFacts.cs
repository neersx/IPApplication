using System.Globalization;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Policy;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Policy
{
    public class SiteDateFormatFacts
    {
        readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();
        
        [Theory]
        [InlineData(0)]
        [InlineData(1, "dd-MMM-yyyy")]
        [InlineData(2, "MMM-dd-yyyy")]
        [InlineData(3, "yyyy-MMM-dd")]
        public void ShouldTransformsSiteControlValueToCorrectDateFormat(int configuredDateStyle, string expectedDateFormat = null)
        {
            _siteControl.Read<int>(SiteControls.DateStyle).Returns(configuredDateStyle);
            Assert.Equal(configuredDateStyle == 0 ? CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern : expectedDateFormat, new SiteDateFormat(_siteControl).Resolve());
        }

        [Theory]
        [InlineData(0, "de-DE", "dd.MM.yyyy")]
        [InlineData(1, "de-DE", "dd-MMM-yyyy")]
        [InlineData(2, "de-DE", "MMM-dd-yyyy")]
        [InlineData(3, "de-DE", "yyyy-MMM-dd")]
        [InlineData(0, "fr-FR", "dd/MM/yyyy")]
        [InlineData(0, "en-US", "M/d/yyyy")]
        [InlineData(0, "zh-CN")]
        [InlineData(1, "zh-CN")]
        [InlineData(2, "zh-CN")]
        [InlineData(3, "zh-CN")]
        [InlineData(0, "ko-KR")]
        [InlineData(1, "ko-KR")]
        [InlineData(2, "ko-KR")]
        [InlineData(3, "ko-KR")]
        [InlineData(0, "ko")]
        [InlineData(1, "ko")]
        [InlineData(2, "ko")]
        [InlineData(3, "ko")]
        [InlineData(1, "kok", "dd-MMM-yyyy")]
        [InlineData(2, "kok", "MMM-dd-yyyy")]
        [InlineData(3, "kok", "yyyy-MMM-dd")]
        public void ShouldReturnCultureShortDatePatternWhereCultureSpecified(int configuredDateStyle, string culture, string expectedDateFormat = null)
        {
            _siteControl.Read<int>(SiteControls.DateStyle).Returns(configuredDateStyle);
            Assert.Equal(expectedDateFormat ?? CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern, new SiteDateFormat(_siteControl).Resolve(culture));
        }
    }
}