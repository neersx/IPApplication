using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.EventCategory
{
    public class EventCategoryDetailPage : DetailPage
    {
        public EventCategoryDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement Category => this.Driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
        public NgWebElement CategoryDescription => this.Driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
        public PickList ImagePicklist => new PickList(Driver).ByName(string.Empty, "imageDescription");
    }
}
