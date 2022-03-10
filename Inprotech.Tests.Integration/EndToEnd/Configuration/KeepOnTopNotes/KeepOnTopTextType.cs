using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.KeepOnTopNotes
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(dbReleaseLevel: DbCompatLevel.Release16)]
    class KeepOnTopTextType : IntegrationTest
    {
        KeepOnTopNotesDbSetup _keeOnTopNotesDbSetup;

        [SetUp]
        public void Setup()
        {
            _keeOnTopNotesDbSetup = new KeepOnTopNotesDbSetup();
            _keeOnTopNotesDbSetup.SetupCaseTextType();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void KeepOnTopNotesTextType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new KeepOnTopNotesPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Keep on Top Notes - Case Types");
            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            page.KotNavigationLink.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.IsTrue(page.FilterByCase(driver).Selected);
            Assert.IsFalse(page.FilterByName(driver).Selected);
            Assert.AreEqual(page.KotGrid.Rows.Count, 2);

            var newData = _keeOnTopNotesDbSetup.SetNewValues();
            page.ButtonAddKotTextType.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.TextTypePicklist.SendKeys(((TextType)newData.tt1).TextDescription);
            page.TextTypePicklist.Blur();
            page.CaseTypePicklist.Click();
            page.CaseTypePicklist.Clear();
            page.CaseTypePicklist.SendKeys("Properties");
            page.RolesPicklist.Click();
            page.CaseTypePicklist.Click();
            driver.WaitForAngular();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);

            page.HasProgramCheckbox.Click();
            page.PendingCheckbox.Click();
            page.ModalSave.ClickWithTimeout();
            page.ButtonAddKotTextType.ClickWithTimeout();
            page.ModalCancel.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(page.KotGrid.Rows.Count, 3);

            DuplicateKotTextType(driver, newData);
        }

        void DuplicateKotTextType(NgWebDriver driver, dynamic newData)
        {
            var page = new KeepOnTopNotesPageObject(driver);
            page.KotGrid.ClickDuplicate(0);
            driver.WaitForAngularWithTimeout();
            Assert.IsEmpty(page.TextTypePicklist.InputValue);
            page.TextTypePicklist.SendKeys(((TextType)newData.tt1).TextDescription);
            page.TextTypePicklist.Click();
            page.CaseTypePicklist.SendKeys("Properties");
            page.CaseTypePicklist.Click();
            page.HasProgramCheckbox.Click();
            page.ModalSave.ClickWithTimeout();
            driver.WaitForAngular();
            page.TextTypePicklist.Click();
            Assert.IsTrue(page.TextTypePicklist.HasError, "Text Type Pick list shows error that text type already exist");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void KeepOnTopNotesNameTextType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new KeepOnTopNotesPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Keep on Top Notes - Name Types");
            page.SearchButton.ClickWithTimeout();
            page.KotNavigationLink.ClickWithTimeout();

            Assert.IsFalse(page.FilterByCase(driver).Selected);
            Assert.IsTrue(page.FilterByName(driver).Selected);
            Assert.AreEqual(page.KotGrid.Rows.Count, 1);

            KotTextTypeForNameType(driver);
            DeleteKotTextType(driver);
            FilterKotTextType(driver);
        }

        void KotTextTypeForNameType(NgWebDriver driver)
        {
            var newData = _keeOnTopNotesDbSetup.SetNewValues();
            var page = new KeepOnTopNotesPageObject(driver);
            page.ButtonAddKotTextType.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.TextTypePicklist.SendKeys(((TextType)newData.tt2).TextDescription);
            page.NameTypePicklist.Click();
            page.TextTypePicklist.Click();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.NameTypePicklist.SendKeys("Agent");
            page.TextTypePicklist.Click();
            page.NameTypePicklist.Click();
            page.HasProgramCheckbox.Click();
            page.ModalSave.ClickWithTimeout();
            page.ButtonAddKotTextType.ClickWithTimeout();
            page.ModalCancel.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(page.KotGrid.Rows.Count, 2);
        }

        void DeleteKotTextType(NgWebDriver driver)
        {
            var page = new KeepOnTopNotesPageObject(driver);
            page.KotGrid.ClickDelete(0);
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            popups.ConfirmNgDeleteModal.Cancel.Click();
            Assert.AreEqual(page.KotGrid.Rows.Count, 2);
            page.KotGrid.ClickDelete(0);
            popups.ConfirmNgDeleteModal.Delete.Click();
            Assert.AreEqual(page.KotGrid.Rows.Count, 1);
        }

        void FilterKotTextType(NgWebDriver driver)
        {
            var page = new KeepOnTopNotesPageObject(driver);
            page.FilterByCase(driver).WithJs().Click();
            driver.WaitForAngular();

            page.ModuleSearchPicklist.Typeahead.WithJs().Focus();
            page.ModuleSearchPicklist.Click();
            page.ModuleSearchPicklist.SendKeys("Task Planner");
            page.StatusSearchPicklist.Click();
            page.ModuleSearchPicklist.Click();
            page.SearchButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(page.KotGrid.Rows.Count, 1);

            page.ClearSearchButton.Click();
            driver.WaitForAngular();

            page.ModuleSearchPicklist.Typeahead.WithJs().Focus();
            page.ModuleSearchPicklist.SendKeys("Billing");
            page.StatusSearchPicklist.Typeahead.WithJs().Focus();
            page.ModuleSearchPicklist.Click();
            page.ModuleSearchPicklist.SendKeys("Case");
            page.StatusSearchPicklist.Typeahead.WithJs().Focus();
            page.StatusSearchPicklist.Click();
            page.StatusSearchPicklist.SendKeys("Pending");
            page.SearchButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(page.KotGrid.Rows.Count, 2);

            page.ClearSearchButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(page.ModuleSearchPicklist.Typeahead.Text, string.Empty);
            Assert.AreEqual(page.KotGrid.Rows.Count, 2);
        }
    }
}
