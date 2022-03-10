using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.CopyValidCombination
{
    class CopyValidCombinationDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public CopyValidCombinationDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string CopyValidCombination()
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

        public NgWebElement CopyRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("copy"));
        }
    }
}