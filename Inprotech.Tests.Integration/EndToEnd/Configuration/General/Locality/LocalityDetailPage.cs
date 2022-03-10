using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Locality
{
    class LocalityDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public LocalityDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string Locality()
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

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field input"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("add"));
        }

        public NgWebElement Code(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        }

        public NgWebElement Name(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
        }

        public NgWebElement City(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("city")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_locality_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_locality_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_locality_duplicate")).WithJs().Click();
        }

        public NgWebElement NavigationBar(NgWebDriver driver)
        {
            return driver.FindElement(By.TagName("ip-nav-modal"));
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "locality"));
    }
}