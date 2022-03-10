using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.EventGroup
{
    public class EventGroupPickListModal : DetailPage
    {
        public EventGroupPickListModal(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement Description => this.Driver.FindElement(By.Name("value")).FindElement(By.TagName("textarea"));
        public NgWebElement UserCode => this.Driver.FindElement(By.Name("code")).FindElement(By.TagName("textarea"));
    }
}
