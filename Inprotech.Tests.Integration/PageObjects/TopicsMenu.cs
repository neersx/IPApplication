using System.Linq;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class TopicsMenu : PageObject
    {
        public TopicsMenu(NgWebDriver driver) : base(driver)
        {
        }

        public bool IsSectionsPaneVisible => Driver.FindElements(By.CssSelector(".topics .topic-menu")).Last().FindElement(By.CssSelector(".tab-pane")).Displayed;
    }
}