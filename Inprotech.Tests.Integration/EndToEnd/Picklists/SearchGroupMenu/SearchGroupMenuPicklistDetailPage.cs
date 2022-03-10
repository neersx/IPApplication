using System.Linq;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SearchGroupMenu
{
    public class SearchGroupMenuPicklistDetailPage : MaintenanceModal
    {
        public SearchGroupMenuPicklistDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SaveSearchButton()
        {
            return Driver.FindElement(By.Name("floppy-o"));
        }

        public NgWebElement DescriptionTextArea()
        {
            return Driver.FindElement(By.XPath("//ipx-text-field[@name='value']/div/textarea"));
        }

        public NgWebElement CaseReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='CaseReference'] input"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
    }
}
