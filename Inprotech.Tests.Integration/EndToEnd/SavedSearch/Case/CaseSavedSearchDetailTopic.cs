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
    public class CaseSavedSearchDetailTopic : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadDetailTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.detailTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.detailTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.detailTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new DetailsTopic(driver);
            topic.NavigateTo();
            
            Assert.AreEqual(Operators.EqualTo, topic.CaseOfficeOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.CaseTypeOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.JurisdictionOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.PropertyTypeOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.CaseCategoryOperator.Value);
            Assert.AreEqual(Operators.NotEqualTo, topic.SubTypeOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.BasisOperator.Value);
            Assert.AreEqual(Operators.StartsWith, topic.ClassOperator.Value);
            Assert.True(topic.IncludeDraftCases.Selected);
            Assert.True(topic.IncludeWhereDesignated.Selected);
            Assert.False(topic.IncludeGroupMembers.Selected);
            Assert.True(topic.Local.Selected);
            Assert.True(topic.International.Selected);
            Assert.AreEqual("12,24,48", topic.Class.Value());
            var offices = topic.CaseOffice.Tags.ToArray();
            Assert.AreEqual(2, offices.Count());
            Assert.AreEqual("City Office", offices[0]);
            Assert.AreEqual("Properties",topic.CaseType.Tags.First());
            Assert.AreEqual(2, topic.PropertyType.Tags.Count());
            Assert.AreEqual(2, topic.Jursidiction.Tags.Count());
            Assert.AreEqual(2, topic.CaseCategory.Tags.Count());
            Assert.AreEqual("Normal", topic.SubType.GetText());
            Assert.AreEqual("Non-Convention", topic.Basis.GetText());          
        }
    }
}