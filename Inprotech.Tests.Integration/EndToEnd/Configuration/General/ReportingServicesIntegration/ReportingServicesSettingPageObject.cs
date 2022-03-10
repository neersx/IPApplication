using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ReportingServicesIntegration
{
    public class ReportingServicesSettingPageObject : PageObject
    {
        public ReportingServicesSettingPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement RootFolderTextField => Driver.FindElement(By.XPath("//label[text()='Inprotech Root Folder']/following-sibling::input"));
        public NgWebElement BaseUrlTextField => Driver.FindElement(By.XPath("//label[text()='Report Server Base URL']/following-sibling::input"));
        public NgWebElement MaxSizeTextField => Driver.FindElement(By.XPath("//label[text()='Max Size (MB)']/following-sibling::input"));
        public NgWebElement UsernameTextField => Driver.FindElement(By.XPath("//label[text()='Username']/following-sibling::input"));
        public NgWebElement TimeoutTextField => Driver.FindElement(By.XPath("//label[text()='Time Out (minutes)']/following-sibling::input"));
        public NgWebElement PasswordTextField => Driver.FindElement(By.XPath("//label[text()='Password']/following-sibling::input"));
        public NgWebElement DomainTextField => Driver.FindElement(By.XPath("//label[text()='Domain']/following-sibling::input"));
        public NgWebElement ApplyButton => Driver.FindElement(By.CssSelector("ipx-save-button button.btn.btn-icon.btn-save"));
        public NgWebElement DiscardButton => Driver.FindElement(By.CssSelector("ipx-revert-button button.btn.btn-icon.btn-warning"));
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));

        public NgWebElement TestButton => Driver.FindElement(By.Id("btnTestConnection"));

        public NgWebElement SuccessElement => Driver.FindElement(By.CssSelector("span.alert-success span:nth-child(2)"));

        public NgWebElement FailureElement => Driver.FindElement(By.ClassName("alert-danger"));
    }
}