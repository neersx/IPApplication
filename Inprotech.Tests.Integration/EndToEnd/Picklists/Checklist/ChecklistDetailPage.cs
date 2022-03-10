using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Checklist
{
    class ChecklistDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public ChecklistDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string CheckListName()
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

        public NgWebElement Description => Driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
        public NgWebElement Renewal => Driver.FindElement(By.Name("Renewal")).FindElement(By.TagName("input"));
        public NgWebElement Examination => Driver.FindElement(By.Name("Examination")).FindElement(By.TagName("input"));
        public NgWebElement Other => Driver.FindElement(By.Name("Other")).FindElement(By.TagName("input"));
    }
}