using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Action
{
    class ActionDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public ActionDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string Action()
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

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("#searchBody span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("add"));
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }

        public NgWebElement ActionOrderWindow(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("actionOrder"));
        }

        public NgWebElement ActionOrderWindowUpButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnUp"));
        }

        public NgWebElement ActionOrderWindowDownButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnDown"));
        }

        public NgWebElement ActionOrderWindowNavigationBar(NgWebDriver driver)
        {
            return driver.FindElement(By.TagName("ip-modal-nav"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void ClickOnSelectPage(NgWebDriver driver)
        {
            driver.FindElement(By.Id("action_selectpage")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_action_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_action_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_action_duplicate")).WithJs().Click();
        }

        public NgWebElement ActionPriorityOrderLink(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("action-priority-link"));
        }

    }
}
