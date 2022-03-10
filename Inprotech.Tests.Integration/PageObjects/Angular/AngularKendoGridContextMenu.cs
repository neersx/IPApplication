using System.Collections.Generic;
using System.Linq;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularKendoGridContextMenu : PageObject
    {
        public AngularKendoGridContextMenu(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement Menu()
        {
            return Driver.FindElements(By.CssSelector("kendo-popup.k-context-menu-popup kendo-menu > ul"))
                         .FirstOrDefault();
        }

        public IEnumerable<NgWebElement> Options(string id = null)
        {
            return Menu().FindElements(By.CssSelector($"div#{id}"));
        }

        public NgWebElement Option(string id = null)
        {
            return Options(id).FirstOrDefault();
        }

        public bool IsDisabled(string id)
        {
            return Option(id).Disabled();
        }
    }
}