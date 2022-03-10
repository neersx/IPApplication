using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    class ValidCaseCategoryDetailPage : DetailPage
    {
        ValidCaseCategoryDefaultsTopic _defaultsTopic;

        public ValidCaseCategoryDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidCaseCategoryDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidCaseCategoryDefaultsTopic(Driver));

        public string ActionName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class ValidCaseCategoryDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidCaseCategoryDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }
    }
}