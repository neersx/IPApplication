using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameType
{
    class NameTypePageObject : PageObject
    {
        public NameTypePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NameTypeMaintenanceModal MaintenanceModal => new NameTypeMaintenanceModal(Driver);

        public NgWebElement Add()
        {
            return Driver.FindElement(By.Id("add"));
        }
    }

    class NameTypeMaintenanceModal : PageObject
    {
        public NameTypeMaintenanceModal(NgWebDriver driver) : base(driver)
        {
        }

        NgWebElement Modal
        {
            get { return Driver.Wait().ForVisible(By.CssSelector(".modal-dialog")); }
        }

        public NgWebElement Save()
        {
            return Modal.FindElement(By.CssSelector(".btn-save"));
        }

        public NgWebElement Discard()
        {
            return Modal.FindElement(By.CssSelector(".btn-discard"));
        }

        public TextInput NameTypeCode()
        {
            return new TextInput(Driver).ByCssSelector("[name=nameTypeCode] input");
        }

        public TextInput NameTypeDescription()
        {
            return new TextInput(Driver).ByCssSelector("[name=name] input");
        }

        public NgWebElement MaxAllowed()
        {
            return Modal.FindElement(By.CssSelector("[name=maximumAllowed] input"));
        }
    }
}