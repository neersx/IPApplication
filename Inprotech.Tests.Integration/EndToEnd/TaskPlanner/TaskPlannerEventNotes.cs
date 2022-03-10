using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerEventNotes : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddAndEditDefaultEventNotes(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);
                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                setup.Insert(new CaseEvent(@case1.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrn = case1.Irn
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.CaseIrn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.EventNotesExpandButton.Click();
            page.AddNewEventNotesLink.Click();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")),"Ensure Pre-Defined picklist is not displayed.");
            Assert.AreEqual("0", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            page.EventNotesTextArea.SendKeys("test123");
            page.EventNotesSaveButton.Click();
            var text = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.True(text.Contains("test123"));
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            page.AddNewEventNotesLink.Click();
            page.EventNotesTextArea.SendKeys("testing456");
            page.EventNotesSaveButton.Click();
            Assert.AreEqual("2", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            var text3 = driver.FindElement(By.XPath("(//div[@class='display-wrap ng-star-inserted'])[1]/span")).Text;
            var text4 = driver.FindElement(By.XPath("(//div[@class='display-wrap ng-star-inserted'])[2]/span")).Text;
            Assert.True(text4.Contains("test123"));
            Assert.True(text3.Contains("testing456"));
            page.AddNewEventNotesLink.Click();
            driver.FindElement(By.XPath("//span[text()='Replace Notes']")).Click();
            page.EventNotesTextArea.SendKeys("test987");
            page.EventNotesSaveButton.Click();
            var text2 = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.True(text2.Contains("test987"));
            Assert.True(!text2.Contains("test123"));
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            page.EditButtonTaskPlanner.ClickWithTimeout();
            Assert.True(driver.FindElement(By.XPath("//ipx-checkbox[@name='replaceNotes']/div/input")).IsDisabled());
            var select = driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select"));
            Assert.True(select.Text.Equals(String.Empty));
            Assert.True(select.IsDisabled());
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")),"Ensure Pre-Defined picklist is not displayed.");
            page.EventNotesTextArea.SendKeys("newTextTest");
            page.EventNotesSaveButton.Click();
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            var text5 = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.True(text5.Contains("newTextTest"));
            Assert.True(text5.Contains("test987"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddAndEditSpecificEventNoteType(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);
                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                setup.Insert(new CaseEvent(@case1.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });
                setup.Insert(new EventNoteType("Event note type 1", false, sharingAllowed: false));
                setup.Insert(new TableCode(Int32.MaxValue, -508, "Predefined notes 1"));
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrn = case1.Irn
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.CaseIrn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.EventNotesExpandButton.Click();
            page.AddNewEventNotesLink.Click();
            Assert.AreEqual("0", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select/option[text()=' Event note type 1 ']")).Click();
            driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")).SendKeys("Predefined notes 1");
            page.EventNotesTextArea.Click();
            page.EventNotesSaveButton.Click();
            driver.FindElement(By.XPath("//a[@class='k-grid-filter k-state-active']")).Click();
            page.Grid.FilterOption("Event note type 1");
            page.Grid.DoFilter();
            var text = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.True(text.Contains("Predefined notes 1"));
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            page.AddNewEventNotesLink.Click();
            driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select/option[text()=' Event note type 1 ']")).Click();
            driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")).SendKeys("Predefined notes 1");
            page.EventNotesTextArea.Click();
            page.EventNotesTextArea.SendKeys("test987");
            page.EventNotesSaveButton.Click();
            Assert.AreEqual("2", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            var text2 = driver.FindElement(By.XPath("(//div[@class='display-wrap ng-star-inserted'])[1]/span")).Text;
            var text3 = driver.FindElement(By.XPath("(//div[@class='display-wrap ng-star-inserted'])[2]/span")).Text;
            Assert.True(text2.Contains("Predefined notes 1"));
            Assert.True(text2.Contains("test987"));
            Assert.True(text3.Contains("Predefined notes 1"));
            page.AddNewEventNotesLink.Click();
            driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select/option[text()=' Event note type 1 ']")).Click();
            driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")).SendKeys("Predefined notes 1");
            driver.FindElement(By.XPath("//span[text()='Replace Notes']")).Click();
            page.EventNotesTextArea.Click();
            page.EventNotesTextArea.SendKeys("newTextTest");
            page.EventNotesSaveButton.Click();
            var text4 = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            Assert.True(text4.Contains("Predefined notes 1"));
            Assert.True(text4.Contains("newTextTest"));
            page.EditButtonTaskPlanner.ClickWithTimeout();
            Assert.True(driver.FindElement(By.XPath("//ipx-checkbox[@name='replaceNotes']/div/input")).IsDisabled());
            var select = driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select"));
            Assert.True(select.Text.Contains("Event note type 1"));
            Assert.True(select.IsDisabled());
            Assert.True(driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")).IsDisabled());
            page.EventNotesTextArea.SendKeys("testing123");
            page.EventNotesSaveButton.Click();
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            var text5 = driver.FindElement(By.XPath("//div[@class='display-wrap ng-star-inserted']/span")).Text;
            Assert.True(text5.Contains("newTextTest"));
            Assert.True(text5.Contains("Predefined notes 1"));
            Assert.True(text5.Contains("testing123"));
        }
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddEventNoteFromTaskMenu(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);
                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                setup.Insert(new CaseEvent(@case1.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrn = case1.Irn
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.CaseIrn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.OpenTaskMenuOption(0,"maintainEventNotes");
            page.EventNotesTextArea.Click();
            page.EventNotesTextArea.SendKeys("e2e notes");
            page.EventNotesSaveButton.Click();
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            var text2 = driver.FindElement(By.XPath("(//div[@class='display-wrap ng-star-inserted'])[1]/span")).Text;
            Assert.True(text2.Contains("e2e notes"));
        }
    }
}
