using System.Linq;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.FilePart
{
    public class FilePartPicklistDetailPage : MaintenanceModal
    {
        public FilePartPicklistDetailPage(NgWebDriver driver) : base(driver)
        {

        }
        public NgWebElement DescriptionTextArea()
        {
            return Driver.FindElement(By.XPath("//ipx-text-field[@name='value']/div/textarea"));
        }

        public NgWebElement CloseButton()
        {
            return Driver.FindElements(By.Name("times")).Last();
        }
    }
}
