using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Validations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Validations
{
    public class EmailValidatorFacts
    {
        readonly ISiteControlReader _siteControls = Substitute.For<ISiteControlReader>();
        const string MultiAddressPattern = @"^(([a-zA-Z0-9_+\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5}){1,25})+([;,.][ ]{0,1}(([a-zA-Z0-9_+\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5}){1,25})+)*[;]{0,1}$";

        [Theory]
        [InlineData("abc@cpaglobal.com;xyz@cpaglobal.com;")]
        [InlineData("klm+abc@cpaglobal.com;xyz@cpaglobal.com;")]
        [InlineData("klm+abc@cpaglobal.com ; xyz@cpaglobal.com;")]
        [InlineData("xyz@cpaglobal.com")]
        public void ShouldValidateAgainstProvidedRegexAndReturnTrue(string stringToValidate)
        {
            _siteControls.Read<string>(SiteControls.ValidPatternForEmailAddresses)
                         .Returns(MultiAddressPattern);
            var subject = new EmailValidator(_siteControls);
            Assert.True(subject.IsValid(stringToValidate));
        }

        [Theory]
        [InlineData("abc@cpaglobal.com;xyz@")]
        public void ShouldValidateAgainstProvidedRegex(string stringToValidate)
        {
            _siteControls.Read<string>(SiteControls.ValidPatternForEmailAddresses)
                         .Returns(MultiAddressPattern);
            var subject = new EmailValidator(_siteControls);
            Assert.False(subject.IsValid(stringToValidate));
        }

        [Fact]
        public void ShouldValidateEveryThingIfSiteControlIsEmpty()
        {
            _siteControls.Read<string>(SiteControls.ValidPatternForEmailAddresses)
                         .Returns(string.Empty);
            var subject = new EmailValidator(_siteControls);
            const string stringToValidate = "abc@cpaglobal.com;xyz@";
            Assert.True(subject.IsValid(stringToValidate));
        }
    }
}