using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    public class CaseTypeDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public CaseTypeDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string CaseTypeName()
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

        public NgWebElement Code => this.Driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        public NgWebElement Description => this.Driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
    }
}