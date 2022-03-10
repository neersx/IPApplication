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
    public class CaseSavedSearchOtherDetailsAndAttributes : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadOtherDetailsTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            menuObjects.FilterCaseMenu.SendKeys(data.otherDetailsTopic.Name);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.otherDetailsTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.otherDetailsTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            builder.ClickAndHold(editIcon).Release().Perform();

            Assert.AreEqual("/case/search?queryKey=" + data.otherDetailsTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new OtherDetailsTopic(driver);
            topic.NavigateTo();
            
            Assert.AreEqual(Operators.EqualTo, topic.FileLocationOperator.Value);
            Assert.AreEqual(Operators.StartsWith, topic.BayNoOperator.Value);
            Assert.AreEqual(Operators.StartsWith, topic.PurchaseOrderOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.InstructionOperator.Value);
            Assert.AreEqual(Operators.EqualTo, topic.CharacteristicOperator.Value);
            Assert.True(topic.Charges.Selected);
            Assert.True(topic.Letters.Selected);
            Assert.True(topic.PolicingIncomplete.Selected);
            Assert.True(topic.GncIncomplete.Selected);
            Assert.True(topic.IsCaseSpecific.Selected);
            Assert.True(topic.IsCharacteristic.Selected);
            
            var fileLocations = topic.FileLocation.Tags.ToArray();
            Assert.AreEqual(2, fileLocations.Length);
            Assert.Contains("Sent to Storage", fileLocations);
            Assert.Contains("Records Management", fileLocations);
            Assert.AreEqual("Auto req normal exam immediately when lodged", topic.Characteristic.InputValue);
            Assert.AreEqual("11234", topic.BayNo.Value());
            Assert.AreEqual("121", topic.PurchaseOrder.Value());
        }

        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadAttributesTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            menuObjects.FilterCaseMenu.SendKeys(data.attributesTopic.Name);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.attributesTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.attributesTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            builder.ClickAndHold(editIcon).Release().Perform();

            Assert.AreEqual("/case/search?queryKey=" + data.attributesTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new AttributesTopic(driver);
            topic.NavigateTo();
            
            Assert.AreEqual(Operators.EqualTo, topic.AttributeOperator1.Value);
            Assert.AreEqual(Operators.NotEqualTo, topic.AttributeOperator2.Value);
            Assert.AreEqual(Operators.EqualTo, topic.AttributeOperator3.Value);
            Assert.True(topic.BooleanAnd.Selected);
            Assert.False(topic.BooleanOr.Selected);

            Assert.AreEqual("New Office", topic.AttributeValue1.InputValue);
            Assert.AreEqual("Patents", topic.AttributeValue2.InputValue);
            Assert.AreEqual("Trade Show", topic.AttributeValue3.InputValue);

            //Assert.AreEqual("Office", topic.AttributeType1.Text);
            //Assert.AreEqual("Product Interest", topic.AttributeType2.Text);
            //Assert.AreEqual("Source", topic.AttributeType3.Text);
        }
    }
}