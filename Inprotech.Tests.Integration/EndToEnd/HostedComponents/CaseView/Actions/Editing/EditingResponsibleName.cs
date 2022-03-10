using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EditingResponsibleName : HostedActionComponentEditing
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentEditingResponsibleName(BrowserType browserType)
        {
            TurnOffDataValidations();
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");
            var name = string.Empty;
            var nameTypeValue = string.Empty;
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
                var actions = new ActionTopic(driver);
                actions.EventsColumnSelector.ColumnMenuButton.Click();
                actions.EventsColumnSelector.ToggleGridColumn("name");
                actions.EventsColumnSelector.ToggleGridColumn("nameType");
                actions.ActionGrid.ClickRow(1);
                driver.WaitForAngular();
                Assert.AreEqual(2, actions.EventsGrid.Rows.Count);
                actions.EventsGrid.OpenTaskMenuFor(0);
                actions.ContextMenu.Edit();
                var rowOne = new EditRow(driver, actions.EventsGrid.Rows[0]);

                rowOne.NamePicklist.Typeahead.WithJs().Focus();
                rowOne.NamePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowOne.NamePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowOne.NamePicklist.Typeahead.SendKeys(Keys.Enter);
                Assert.AreNotEqual(string.Empty, rowOne.NamePicklist.GetText());
                name = rowOne.NamePicklist.GetText();

                actions.EventsGrid.OpenTaskMenuFor(1);
                actions.ContextMenu.Edit();
                var rowTwo = new EditRow(driver, actions.EventsGrid.Rows[1]);
                rowTwo.NamePicklist.Typeahead.WithJs().Focus();
                rowTwo.NamePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowTwo.NamePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowTwo.NamePicklist.Typeahead.SendKeys(Keys.Enter);
                Assert.AreNotEqual(string.Empty, rowOne.NamePicklist.GetText());
                rowTwo.NameTypePicklist.Typeahead.WithJs().Focus();
                rowTwo.NameTypePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowTwo.NameTypePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                rowTwo.NameTypePicklist.Typeahead.SendKeys(Keys.Enter);
                Assert.AreEqual(string.Empty, rowTwo.NamePicklist.GetText());
                nameTypeValue = rowTwo.NameTypePicklist.GetText();
                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", false));
            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.AreEqual(name, actions.EventsGrid.Cell(0, 12).Text);
                Assert.AreEqual(nameTypeValue, actions.EventsGrid.Cell(1, 13).Text);
            });
        }
    }
}