using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.PropertyType
{
    class PropertyTypeDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public PropertyTypeDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement Code => Driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        public NgWebElement Description => Driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
        public DropDown AllowSubClass => new DropDown(Driver, "ip-DropDown").ByName("allowSubClass");
        public NgWebElement Icon => Driver.FindElement(By.Name("imageDescription")).FindElement(By.TagName("input"));
    }
}