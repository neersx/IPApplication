using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.NameTypeGroup
{
    class NameTypeGroupDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public NameTypeGroupDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string NameTypeGroupName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
           NameTypePicklist = new PickList(driver).ById("nametype-picklist");
        }

        public NgWebElement GroupName => this.Driver.FindElement(By.Name("groupName")).FindElement(By.TagName("input"));

        public NgWebElement NavigationBar(NgWebDriver driver)
        {
          return driver.FindElement(By.CssSelector("[ng-if='vm.navigation']"));
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("plus-circle"));
        }
        public PickList NameTypePicklist { get; set; }
    }
}
