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
    public class CaseSavedSearchPtaAndDataManagement : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadPatentTermAdjustmentsTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            menuObjects.FilterCaseMenu.SendKeys(data.ptaTopic.Name);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.ptaTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.ptaTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            builder.ClickAndHold(editIcon).Release().Perform();

            Assert.AreEqual("/case/search?queryKey=" + data.ptaTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new PtaTopic(driver);
            topic.NavigateTo();

            Assert.AreEqual(Operators.Between, topic.SuppliedPtaOperator.Value);
            Assert.AreEqual(Operators.NotBetween, topic.DeterminedByUsOperator.Value);
            Assert.AreEqual(Operators.Between, topic.IpOfficeDelayOperator.Value);
            Assert.AreEqual(Operators.NotBetween, topic.ApplicantDelayOperator.Value);
            Assert.True(topic.PtaDiscrepancies.Selected);
            
            Assert.AreEqual("1", topic.FromSuppliedPta.Value());
            Assert.AreEqual("10", topic.ToSuppliedPta.Value());
            Assert.AreEqual("0", topic.FromPtaDeterminedByUs.Value());
            Assert.AreEqual("20", topic.ToPtaDeterminedByUs.Value());
            Assert.AreEqual("1", topic.FromIpOfficeDelay.Value());
            Assert.AreEqual("100", topic.ToIpOfficeDelay.Value());
            Assert.AreEqual("1", topic.FromApplicantDelay.Value());
            Assert.AreEqual("10", topic.ToApplicantDelay.Value());
        }

        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadDataManagementTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            menuObjects.FilterCaseMenu.SendKeys(data.dmTopic.Name);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.dmTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.dmTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            builder.ClickAndHold(editIcon).Release().Perform();

            Assert.AreEqual("/case/search?queryKey=" + data.dmTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new DataManagementTopic(driver);
            topic.NavigateTo();

            Assert.AreEqual("Maxim Yarrow and Colman", topic.DataSource.InputValue);
            Assert.AreEqual("112", topic.BatchIdentifier.Value());
            Assert.AreEqual("501", topic.SentToCpa.Value);
        }
    }
}