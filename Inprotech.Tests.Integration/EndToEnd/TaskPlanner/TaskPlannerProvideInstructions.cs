using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerProvideInstructions : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void Process(BrowserType browserType)
        {
            var data = TaskPlannerService.InsertInstruction();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", data.User.Username, data.User.Password);
            var page = new TaskPlannerPageObject(driver);
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            driver.WaitForAngularWithTimeout();
            page.FilterButton.ClickWithTimeout();
            builderPage.IncludeDueDatesCheckbox.Click();
            builderPage.BelongingToDropdown.Input.SelectByText("All Names");
            builderPage.CaseReferenceOperatorDropdown.Input.SelectByText("Starts With");
            builderPage.CaseReferenceTextbox.Input.Clear();
            builderPage.CaseReferenceTextbox.Input.SendKeys(data.Case.Irn);
            builderPage.SearchButton.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            
            Assert.AreEqual(1,page.Grid.Rows.Count);

            page.OpenTaskMenuOption(0, "provideInstructions");
            driver.WaitForAngular();
            
            var instructionPage = new TaskPlannerProvideInstructionsObject(driver);
            Assert.IsFalse(instructionPage.ModalSaveButton.Enabled, "Proceed Button is Disabled when instruction response is not modified");
            
            Assert.AreEqual(data.Definition.InstructionName,instructionPage.InstructionName.Text); 
            Assert.AreEqual("No Action",instructionPage.InstructionDropdown.SelectedOption.Text);
            instructionPage.InstructionDropdown.SelectByText(data.FileResponse.Label);
            Assert.IsTrue(instructionPage.AddEventNoteButton.Enabled, "Button add event note is enabled.");
            instructionPage.AddEventNoteButton.Click();
            Assert.False(instructionPage.AddEventNoteButton.Enabled, "Button add event note is disabled.");
            var note = "e2e text";
            instructionPage.EventNote.SendKeys(note);
            instructionPage.EventNoteSaveButton.Click();
            Assert.IsTrue(instructionPage.ModalSaveButton.Enabled, "Proceed Button is Enabled when instruction response is other then no action");
            instructionPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");

            DbSetup.Do(x =>
            {
                var ce = x.DbContext.Set<CaseEvent>().Single(_ => _.CaseId == data.Case.Id && _.EventNo == data.FileResponse.FireEventNo && _.Cycle == data.Cycle);
                Assert.AreEqual(DateTime.Today, ce.EventDate, "Event Date Should be equal instructed date");
                var cet = x.DbContext.Set<CaseEventText>().Single(_ => _.CaseId == ce.CaseId && _.EventId == ce.EventNo && _.Cycle == ce.Cycle);
                var et = x.DbContext.Set<EventText>().Single(_ => _.Id == cet.EventTextId);
                Assert.True(et.Text.Contains(note), "event note should be inserted");
            });
        }
    }

    public class TaskPlannerProvideInstructionsObject : PageObject
    {
        public TaskPlannerProvideInstructionsObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            
        }

        public NgWebElement ModalSaveButton => Driver.FindElement(By.Name("save"));

        public NgWebElement InstructionName => Driver.FindElement(By.ClassName("piName0"));

        public NgWebElement AddEventNoteButton => Driver.FindElement(By.Id("btnAddEventNote0"));

        public NgWebElement EventNote => Driver.FindElement(By.Name("requiredTextArea")).FindElement(By.XPath(".//textarea")); 

        public NgWebElement EventNoteSaveButton => Driver.FindElement(By.Name("apply")); 

        public SelectElement InstructionDropdown => new SelectElement(Driver.FindElement(By.CssSelector("ipx-dropdown.piAction0 select")));
    }
}
