using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class FormModal : PageObject
    {
        readonly string _name;

        public FormModal(NgWebDriver driver, string name) : base(driver)
        {
            _name = name;
        }

        public NgWebElement Modal => Driver.FindElements(By.Name(_name)).FirstOrDefault();

        public void Dismiss()
        {
            Driver.FindElement(By.Id("dismissAll")).WithJs().Click();
        }
    }
}