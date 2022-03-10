using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.PropertyType
{
    class PropertyTypeDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public PropertyTypeDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string PropertyType()
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

        public NgWebElement AnnuityOffset(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("annuityOffset")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void ClickOnSelectPage(NgWebDriver driver)
        {
            driver.FindElement(By.Id("propertyType_selectpage")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_propertyType_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_propertyType_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_propertyType_duplicate")).WithJs().Click();
        }
    }
}
