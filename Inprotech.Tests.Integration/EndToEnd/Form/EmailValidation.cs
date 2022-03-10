using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Tests.Integration.EndToEnd.Form
{
    [Category(Categories.E2E)]
    [TestFixture]
    class EmailValidation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MinLengthValidatesCorrectly(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/deve2e/formvalidation");

            EmailValidationWorksAsIntended(driver);
            MinLengthValidationWorksAsIntended(driver);
            MaxLengthValidatesAsIntended(driver);
        }

        private static void MinLengthValidationWorksAsIntended(NgWebDriver driver)
        {
            var minLength = new ValidationTextField(driver, "minLengthValue");
            Assert.False(minLength.HasError());

            minLength.SetText("a");
            Assert.True(minLength.HasError());

            minLength.SetText(string.Empty);
            Assert.False(minLength.HasError());

            minLength.SetText("abcd");
            Assert.False(minLength.HasError());
        }

        private static void MaxLengthValidatesAsIntended(NgWebDriver driver)
        {
            var maxLength = new ValidationTextField(driver, "maxLengthValue");
            Assert.False(maxLength.HasError());

            maxLength.SetText("a");
            Assert.False(maxLength.HasError());

            maxLength.SetText(string.Empty);
            Assert.False(maxLength.HasError());

            maxLength.SetText("abcd");
            Assert.True(maxLength.HasError());
        }

        private static void EmailValidationWorksAsIntended(NgWebDriver driver)
        {
            var emailValidator = new ValidationTextField(driver, "emailValue");

            Assert.False(emailValidator.HasError());

            emailValidator.SetText("failedEmail");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText(string.Empty);
            Assert.False(emailValidator.HasError());

            emailValidator.SetText("failedEmail@testdomain");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("failedEmail@.com");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("failedEmail@test.c");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("failedEmail@test.tester");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("failedEmail@test.123");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("failed@Email@test.com");
            Assert.True(emailValidator.HasError());

            emailValidator.SetText("test@testdomain.com");
            Assert.False(emailValidator.HasError());
        }

        public class ValidationTextField
        {
            public NgWebElement Wrapper { get; set; }
            public ValidationTextField(NgWebDriver driver, string name)
            {
                this.Wrapper = driver.FindElement(By.CssSelector($"ipx-text-field[name='{name}']"));
            }
            NgWebElement TextBox => Wrapper.FindElement(By.TagName("input"));
            public void SetText(string value)
            {
                TextBox.Clear();
                TextBox.SendKeys(value);
                Wrapper.Click();
            }
            public bool HasError()
            {
                return Wrapper.FindElement(By.CssSelector(".tooltip-error")).Displayed && Wrapper.FindElements(By.CssSelector(".input-wrap.error")).Any();
            }

        }
    }
}
