using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Tags
{
    class TagsDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public TagsDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string SiteControlName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement SearchSiteControl(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("#searchBody [name=search]"));
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("plus-circle"));
        }

        public NgWebElement TagNameTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("tagName")).FindElement(By.TagName("input"));
        }

        public NgWebElement TagSaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.XPath("//div[@class='modal-header-controls']//button//span[@name='floppy-o']"));
        }

        public NgWebElement SearchTag(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[data-value='vm.searchValue']")).FindElement(By.TagName("input"));
        }

        public NgWebElement SearchButtonTag(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[button-icon='search']"));
        }

        public NgWebElement ExpandSiteControl(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("#searchResults a.k-i-expand"));
        }

        public NgWebElement SelectTagInSiteControl(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ipt-typeahead-multi-select")).FindElement(By.TagName("input"));
        }

        public NgWebElement EnterNotes(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("notes"));
        }

        public NgWebElement EditIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("pencil-square-o"));
        }

        public NgWebElement DeleteIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("trash"));
        }
    }
}