using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.SavedSearch.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseSaveSearchTextAndStatusTopics : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadTextTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.textTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions (driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.textTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.textTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new TextTopic(driver);
            topic.NavigateTo();
            Assert.AreEqual(Operators.Contains,topic.TitleMarkOperator.Value);
            Assert.AreEqual("The",topic.TitleMarkValue.Value());
            Assert.AreEqual(Operators.NotEqualTo,topic.TypeOfMarkOperator.Value);
            Assert.AreEqual("Colour Mark",topic.TypeOfMarkValue.GetText());
            Assert.AreEqual("_B",topic.TextType.Value);
            Assert.AreEqual(Operators.EndsWith,topic.TextTypeOperator.Value);
            Assert.AreEqual("xyz",topic.TextTypeValue.Value());
            Assert.AreEqual(Operators.NotEqualTo,topic.KeywordOperator.Value);
            Assert.AreEqual("RONDON",topic.KeywordValue.GetText());
        }

        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadStatusTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.statusTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions (driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.statusTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.statusTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new StatusTopic(driver);
            topic.NavigateTo();
           
            Assert.NotNull(topic);
            Assert.False(topic.IsDead.Selected);
            Assert.True(topic.IsPending.Selected);
            Assert.True(topic.IsRegistered.Selected);
            var caseStatus = topic.CaseStatus.Tags.ToArray();
            Assert.AreEqual(2,caseStatus.Count());
            Assert.AreEqual("EP Granted",caseStatus[0]);
            Assert.AreEqual(Operators.EqualTo, topic.CaseStatusOperator.Value);
            Assert.AreEqual(2, topic.RenewalStatus.Tags.Count());
            Assert.AreEqual(Operators.EqualTo,topic.RenewalStatusOperator.Value);
            Assert.AreEqual("Renewal not our responsibility",topic.RenewalStatus.Tags.ToArray()[0]);

        }
    }
}