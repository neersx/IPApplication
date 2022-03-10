using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Compatibility;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class InprotechVersionCheckerFacts : FactBase
    {
        public class CheckMinimumVersionMethod
        {
            [Theory]
            [InlineData("13.0.1", true)]
            [InlineData("12.1.0", true)]
            [InlineData("20.0.0", true)]
            [InlineData("13", true)]
            [InlineData("12", false)]
            [InlineData("9.1.0", false)]
            [InlineData("12.0.1", false)]
            [InlineData("10.2.1", false)]
            [InlineData("", false)]
            [InlineData("NAN", false)]
            public void ReturnsIfGreaterOrEqualToVersionNumber(string inprotechVersionNumber, bool expectedResult)
            {
                var configurationSettings = Substitute.For<IConfigurationSettings>();
                var subject = new InprotechVersionChecker(configurationSettings);

                configurationSettings[Arg.Any<string>()].ReturnsForAnyArgs(inprotechVersionNumber);

                var r = subject.CheckMinimumVersion(12, 1);

                Assert.Equal(r, expectedResult);
            }
        }
    }
}