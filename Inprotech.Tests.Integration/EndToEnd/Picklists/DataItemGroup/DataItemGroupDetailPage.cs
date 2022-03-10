using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DataItemGroup
{
    class DataItemGroupDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public DataItemGroupDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string DataItemGroupName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            DataItemGroupPicklist = new PickList(driver).ById("dataitem-group-picklist");
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("plus-circle"));
        }

        public NgWebElement DescriptionTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));
        }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[data-value='vm.searchValue']")).FindElement(By.TagName("input"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[button-icon='search']"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[button-icon='eraser']"));
        }

        public PickList DataItemGroupPicklist { get; set; }
    }
}
