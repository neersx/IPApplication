using Inprotech.Infrastructure.StorageService;
using Xunit;

namespace Inprotech.Tests.Infrastructure.StorageService
{
    public class ValidateHttpOrHttpsStringFacts
    {
        [Theory]
        [InlineData("http://www.google.com",true)]
        [InlineData("https://www.google.com",true)]
        [InlineData("iwl://www.google.com",true)]
        [InlineData("ftp://www.google.com",true)]
        [InlineData("http://google.com",true)]
        [InlineData("google.com",false)]
        [InlineData("htp://www.google.com",false)]
        [InlineData("http://www.google.co.uk", true)]
        [InlineData("http://www.google.dk", true)]
        [InlineData("http://www.google", true)]
        [InlineData("http://google", true)]
        [InlineData("htt p://google", false)]
        [InlineData("wwww.google.com", false)]
        [InlineData("www.google", false)]
        [InlineData("google", false)]
        public void ShouldResolveValidationCorrectly(string input, bool expectedOutput)
        {
            var fixture = new ValidateHttpOrHttpsStringFixture();

            var output = fixture.Subject.Validate(input);

            Assert.Equal(expectedOutput, output);
        }
    }

    public class ValidateHttpOrHttpsStringFixture : IFixture<ValidateHttpOrHttpsString>
    {
        public ValidateHttpOrHttpsStringFixture()
        {
            Subject = new ValidateHttpOrHttpsString();
        }

        public ValidateHttpOrHttpsString Subject { get; }
    }
}