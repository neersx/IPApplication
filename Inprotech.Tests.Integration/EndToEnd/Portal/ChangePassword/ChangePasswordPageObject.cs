using System.ComponentModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ChangePassword
{
    public class ChangePasswordPageObject : PageObject
    {
        public ChangePasswordPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SubmitButton => Driver.FindElement(By.Id("btnSubmit"));
        public NgWebElement OldPasswordTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='oldPassword'] input[type='password']"));
        public NgWebElement NewPasswordTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='newPassword'] input[type='password']"));
        public NgWebElement ConfirmNewPasswordTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='confirmNewPassword'] input[type='password']")); 
        public NgWebElement ErrorMessageDiv => Driver.FindElement(By.Id("errorMessage")); 
        public NgWebElement CloseButton => Driver.FindElement(By.CssSelector(".modal-header .modal-header-controls ipx-close-button button")); 
        
        public void Close()
        {
            CloseButton.ClickWithTimeout();
        }
    }
}
