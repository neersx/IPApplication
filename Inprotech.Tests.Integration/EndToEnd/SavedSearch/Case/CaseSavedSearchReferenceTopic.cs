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
    public class CaseSavedSearchReferenceTopic : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadReferenceTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.referenceTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.referenceTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.referenceTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topic = new ReferencesTopic(driver);
            
            Assert.AreEqual(Operators.EqualTo,topic.CaseReferenceOperator.Value);
            Assert.AreEqual(3,topic.CasePickList.Tags.Count());
            Assert.AreEqual(string.Empty,topic.OfficalNumberType.Value);
            Assert.AreEqual("1234",topic.OfficialNumber.Value());
            Assert.AreEqual(Operators.StartsWith, topic.OfficialNumberOperator.Value);
            Assert.AreEqual("xyz",topic.CaseNameReference.Value());
            Assert.AreEqual(Operators.EndsWith, topic.CaseNameReferenceOperator.Value);
            Assert.AreEqual("I", topic.CaseNameReferenceType.Value);
            Assert.AreEqual(2, topic.CaseFamily.Tags.Count());
            Assert.AreEqual(Operators.EqualTo, topic.FamilyOperator.Value);
            Assert.IsFalse(topic.SearchNumbersOnly.Selected);
            Assert.IsFalse(topic.SearchRelatedCases.Selected);
            Assert.AreEqual("Current Working List",topic.CaseList.GetText());
            Assert.AreEqual(Operators.NotEqualTo, topic.CaseListOperator.Value);
        }
    }
}