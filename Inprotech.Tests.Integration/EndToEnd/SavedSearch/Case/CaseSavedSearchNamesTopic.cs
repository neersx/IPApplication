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
    public class CaseSavedSearchNamesTopic : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadNamesTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            menuObjects.FilterCaseMenu.SendKeys(data.namesTopic.Name);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.namesTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.namesTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            builder.ClickAndHold(editIcon).Release().Perform();
            //editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.namesTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new NamesTopic(driver);
            topic.NavigateTo();
            
            Assert.AreEqual(Operators.EqualTo, topic.InstructorOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.OwnerOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.AgentOperator.Value);
            Assert.AreEqual(Operators.NotEqualTo, topic.SignatoryOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.StaffOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.DefaultRelationshipOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.InheritedNameTypeOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.ParentNameOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.NamesOperator.Value);
            Assert.True(topic.IsStaffMyself.Selected);
            Assert.False(topic.IsSignatoryMyself.Selected);
            Assert.True(topic.SearchAttentionName.Selected);
            
            var instructors = topic.Instructor.Tags.ToArray();
            Assert.AreEqual(2, instructors.Length);
            Assert.AreEqual("{010000} Acorn & Associates", instructors[0]);
            Assert.AreEqual(2, topic.Owner.Tags.Count());
            Assert.AreEqual(2, topic.Agent.Tags.Count());
            Assert.AreEqual(2, topic.Staff.Tags.Count());
            Assert.AreEqual(1, topic.Signatory.Tags.Count());
            Assert.Contains("Grey, George", topic.Signatory.Tags.ToArray());
            Assert.Contains("Asparagus Farming Equipment Pty Ltd", topic.Names.Tags.ToArray());
            Assert.AreEqual("1234/B", topic.IncludeCaseValue.InputValue);
            Assert.Contains("Renewal Agent", topic.NameTypeValue.Tags.ToArray());
            Assert.Contains("Renewal Agent For", topic.Relationship.Tags.ToArray());
            Assert.AreEqual("Send Bills To", topic.DefaultRelationship.InputValue);
            Assert.AreEqual("D", topic.NamesType.Value);
            Assert.AreEqual("Owner", topic.InheritedNameType.InputValue);
            Assert.AreEqual("Adams, Zenith", topic.ParentName.InputValue);
        }
    }
}