using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ResetPassword
{
    class SendEmailPageObject : PageObject
    {
        readonly NgWebDriver _driver;
        public SendEmailPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _driver = driver;
        }
        public NgWebElement ForgotPasswordElement => Driver.FindElement(By.Id("lnkForgotPassword"));
        public NgWebElement Title => Driver.FindElement(By.Id("titleForgotPassword"));

        public NgWebElement LoginId => Driver.FindElement(By.Name("loginId"));
        public NgWebElement SendEmailButton => Driver.FindElement(By.Name("send"));
        public NgWebElement ErrorMessageDiv => Driver.FindElement(By.Id("errorMessage"));
        public NgWebElement SuccessMessageDiv => Driver.FindElement(By.Id("successMessage"));

        public void CancelButton()
        {
            new ButtonInput(_driver).ByName("cancel").Element.WithJs().Click();
        }
    }
}
