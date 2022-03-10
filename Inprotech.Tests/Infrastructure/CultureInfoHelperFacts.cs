using System.Globalization;
using System.Threading;
using Inprotech.Infrastructure;
using Xunit;

namespace Inprotech.Tests.Infrastructure
{
    public class CultureInfoHelperFacts
    {

        [Fact]
        public void ShouldReturnOnlyIfUriIsValid()
        {
            Thread.CurrentThread.CurrentCulture = CultureInfo.CreateSpecificCulture("en-IL");
            CultureInfoHelper.SetDefault();
            Assert.Equal(Thread.CurrentThread.CurrentCulture, CultureInfo.InvariantCulture); 
        }

        [Fact]
        public void ShouldNotReturnIllegalUrls()
        {
            var currentCulture = CultureInfo.CreateSpecificCulture("en-US");
            Thread.CurrentThread.CurrentCulture = currentCulture;
            CultureInfoHelper.SetDefault();
            Assert.Equal(Thread.CurrentThread.CurrentCulture, currentCulture);
        }
    }
}