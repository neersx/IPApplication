using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    class CaseCategoryDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public CaseCategoryDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string CaseCategoryName()
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

        public NgWebElement CaseType => this.Driver.FindElement(By.Name("casetype")).FindElement(By.TagName("input"));
        public NgWebElement Code => this.Driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        public NgWebElement Description => this.Driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
    }
}
