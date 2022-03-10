using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class MenuItems : PageObject
    {
        public MenuItems(NgWebDriver driver) : base(driver)
        {

        }

        public NgWebElement Menu => Driver.FindElement(By.CssSelector("div.menu-container>ul"));

        public NgWebElement Utilities => Menu.FindElement(By.CssSelector("li>span>menu-item#Utilities_"));

        public NgWebElement UtilitiesExpandIcon => Utilities.GetParent().FindElement(By.CssSelector("li>span>span.k-menu-expand-arrow"));

        public NgWebElement NamesConsolidation => Driver.FindElements(By.TagName("menu-item")).SingleOrDefault(m => m.Text.Equals("Name Consolidation"));

        public NgWebElement TogglElement => Driver.FindElement(By.CssSelector("div.pin-menu>a"));

        public NgWebElement Inprotech => Menu.FindElements(By.CssSelector("li>span>menu-item#Inprotech_")).SingleOrDefault();

        public NgWebElement TimeRecording => Menu.FindElements(By.TagName("menu-item")).SingleOrDefault(m => m.Text.Equals("Time Recording"));
        public NgWebElement TaskPlanner => Menu.FindElements(By.TagName("menu-item")).SingleOrDefault(m => m.Text.Equals("Task Planner"));

    }
}
