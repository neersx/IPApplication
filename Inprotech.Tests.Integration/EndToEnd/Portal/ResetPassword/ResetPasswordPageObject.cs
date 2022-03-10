using System.ComponentModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ResetPassword
{
    public class ResetPasswordPageObject : PageObject
    {
        public ResetPasswordPageObject(NgWebDriver driver) : base(driver)
        {
        }
        
        public NgWebElement NewPasswordTextbox => Driver.FindElement(By.CssSelector("input[type='password'][name='newPassword']"));
        public NgWebElement ConfirmPasswordTextbox => Driver.FindElement(By.CssSelector("input[type='password'][name='confirmPassword']")); 
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("button[type='submit'][name='send']"));
        public NgWebElement ErrorMessageDiv => Driver.FindElement(By.Id("errorMessage"));  
        public NgWebElement ForgotPasswordButtonOnSignIn => Driver.FindElement(By.Id("lnkForgotPassword"));
        public NgWebElement OldPasswordTextField => Driver.FindElement(By.XPath("//label[text()='Old Password']/../following-sibling::div/input"));
        public NgWebElement NewPasswordTextField => Driver.FindElement(By.XPath("//label[text()='New Password']/../following-sibling::div/input"));
        public NgWebElement ConfirmPasswordTextField => Driver.FindElement(By.XPath("//label[text()='Confirm Password']/../following-sibling::div/input"));
        public NgWebElement ErrorMessage => Driver.FindElement(By.CssSelector("#errorMessage"));
    }

}
