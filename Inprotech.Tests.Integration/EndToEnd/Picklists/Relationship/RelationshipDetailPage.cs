using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Relationship
{
    class RelationshipDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public RelationshipDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement Code => Driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        public NgWebElement Description => Driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
        public NgWebElement Notes => Driver.FindElement(By.Name("notes")).FindElement(By.TagName("input"));
        public NgWebElement FromEvent => Driver.FindElement(By.Name("fromEvent")).FindElement(By.TagName("input"));
        public NgWebElement ToEvent => Driver.FindElement(By.Name("toEvent")).FindElement(By.TagName("input"));
        public NgWebElement DisplayEvent => Driver.FindElement(By.Name("displayEvent")).FindElement(By.TagName("input"));
        public NgWebElement EarliestDateFlag => Driver.FindElement(By.Name("earliestDateFlag")).FindElement(By.TagName("input"));
        public NgWebElement PointsToParent => Driver.FindElement(By.Name("pointsToParent")).FindElement(By.TagName("input"));
        public NgWebElement ShowFlag => Driver.FindElement(By.Name("showFlag")).FindElement(By.TagName("input"));
        public NgWebElement ReportPriorArt => Driver.FindElement(By.Name("reportPriorArt")).FindElement(By.TagName("input"));
    }
}