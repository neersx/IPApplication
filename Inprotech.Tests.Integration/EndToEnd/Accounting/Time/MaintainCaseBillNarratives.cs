using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class MaintainCaseBillNarratives : IntegrationTest
    {
        TimeRecordingData _dbData;
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void MaintainCaseBillNarrativeTask(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCaseBillNarrative).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", user.Username, user.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.MaintainCaseNarrative();

            var dialog = new CaseNarrativeDialog(driver);
            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            Assert.IsTrue(dialog.Save.WithJs().IsDisabled(), "Expected Save button to be disabled initially");
            dialog.Notes.SendKeys("New Notes");
            dialog.Save.WithJs().Click();
            Assert.NotNull(dialog.Step1);
            dialog.Cancel.ClickWithTimeout();
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.MaintainCaseNarrative();
            Assert.AreEqual("New Notes", dialog.Notes.WithJs().GetValue());
            Assert.AreEqual(dialog.Step1.Text, "Not Specified");
            dialog.LanguagePicklist.SendKeys("French");
            driver.WaitForAngular();
            dialog.Notes.ClickWithTimeout();
            driver.WithTimeout(2, () => dialog.Notes.SendKeys("French language notes"));
            dialog.Save.WithJs().Click();
            Assert.AreEqual("French language notes", dialog.Notes.WithJs().GetValue());
            Assert.AreEqual(dialog.Step2.Text, "French");
            dialog.Step1RemoveButton.ClickWithTimeout();
            Assert.NotNull(confirmDeleteDialog);
            driver.FindElement(By.XPath("//button[contains(text(),'Cancel')]")).ClickWithTimeout();
            Assert.AreEqual(dialog.Step1.Text, "Not Specified");
            dialog.Step1RemoveButton.ClickWithTimeout();
            driver.FindElement(By.XPath("//button[contains(text(),'Delete')]")).ClickWithTimeout();
            driver.WithTimeout(2, () => dialog.Notes.ClickWithTimeout());
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("step_1")), "Ensure language step button is not visible");
        }
    }

    public class CaseNarrativeDialog : MaintenanceModal
    {
        public CaseNarrativeDialog(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement Notes => Modal.FindElements(By.CssSelector("div ipx-richtext-field")).First().FindElement(By.TagName("textarea"));
        public NgWebElement LanguagePicklist => Driver.FindElement(By.XPath("//ipx-typeahead[@name='language']/div/div/input"));
        public AngularCheckbox Remove => new AngularCheckbox(Driver).ByName("chkClearCaseText");
        public NgWebElement Save => Modal.FindElement(By.XPath("//*[@id='save']/button"));
        public NgWebElement Cancel => Modal.FindElement(By.XPath("//*[@id='close']/button"));
        public NgWebElement Step1 => Driver.FindElement(By.Id("step_0"));
        public NgWebElement Step1RemoveButton => Driver.FindElement(By.XPath("//a[contains(text(),'X')]"));
        public NgWebElement Step2 => Driver.FindElement(By.Id("step_1"));
    }
}
