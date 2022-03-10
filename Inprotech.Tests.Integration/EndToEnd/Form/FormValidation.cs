using Inprotech.Tests.Integration.PageObjects.Angular;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Form
{
    [Category(Categories.E2E)]
    [TestFixture]
    internal class FormValidation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TextFieldValidation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/formvalidation");

            EmailValidationDisplaysErrorsForRightValues(driver);
            MinLengthValidationDisplaysErrorsForRightValues(driver);
            MaxLengthValidationDisplaysErrorsForRightValues(driver);
        }

        static void MinLengthValidationDisplaysErrorsForRightValues(NgWebDriver driver)
        {
            var minLength = new AngularTextField(driver, "minLengthValue");
            Assert.False(minLength.HasError);

            minLength.Text = "a";
            minLength.Input.Click();
            Assert.True(minLength.HasError);

            minLength.Text = string.Empty;
            Assert.False(minLength.HasError);

            minLength.Text = "abcd";
            Assert.False(minLength.HasError);
        }

        static void MaxLengthValidationDisplaysErrorsForRightValues(NgWebDriver driver)
        {
            var maxLength = new AngularTextField(driver, "maxLengthValue");
            Assert.False(maxLength.HasError);

            maxLength.Text = "a";
            Assert.False(maxLength.HasError);

            maxLength.Text = string.Empty;
            Assert.False(maxLength.HasError);

            maxLength.Text = "abcd";
            maxLength.Input.Click();
            Assert.True(maxLength.HasError);
        }

        static void EmailValidationDisplaysErrorsForRightValues(NgWebDriver driver)
        {
            var emailValidator = new AngularTextField(driver, "emailValue");
            emailValidator.Input.Click();
            Assert.False(emailValidator.HasError);

            emailValidator.Text = "failedEmail";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = string.Empty;
            Assert.False(emailValidator.HasError);

            emailValidator.Text = "failedEmail@testdomain";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "failedEmail@.com";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "failedEmail@test.c";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "failedEmail@test.tester";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "failedEmail@test.123";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "failed@Email@test.com";
            Assert.True(emailValidator.HasError);

            emailValidator.Text = "test@testdomain.com";
            Assert.False(emailValidator.HasError);
        }
    }
}