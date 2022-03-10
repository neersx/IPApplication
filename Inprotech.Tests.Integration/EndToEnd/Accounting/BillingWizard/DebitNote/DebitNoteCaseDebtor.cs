using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.BillingWizard.DebitNote
{
    [Category(Categories.E2E)]
    [TestFixture]
    class DebitNoteCaseDebtor : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseDebtorData = new DebitNoteDbSetUp().ForCaseDebtorDataSetup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        dynamic _caseDebtorData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void NewDebitCaseDebtors(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainDebitNote, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/billing/debit-note", user.Username, user.Password);
            var page = new DebitNotePageObjects(driver);
            var popup = new CommonPopups(driver);
            Assert.AreEqual(page.CaseGrid.Rows.Count, 0);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 0);
            page.CaseGrid.AddButton.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalApply.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.CasePickList.SendKeys("1234/A");
            page.CaseListPickList.WithJs().Focus();
            driver.WaitForAngular();
            Assert.AreEqual(false, page.CaseListPickList.Enabled);
            Assert.AreEqual(true, page.ModalApply.Enabled);
            page.ModalApply.ClickWithTimeout();
            Assert.AreEqual(page.CaseGrid.Rows.Count, 1);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            Assert.IsNotNull(page.MainCaseIcon.Displayed);
            page.CaseGrid.AddButton.ClickWithTimeout();
            page.CasePickList.SendKeys("1234/B");
            page.CaseListPickList.WithJs().Focus();
            driver.WaitForAngular();
            page.ModalApply.ClickWithTimeout();
            Assert.AreEqual(page.CaseGrid.Rows.Count, 2);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            //popup.ConfirmModal.Ok().WithJs().Click();
            page.ContextMenu._removeCase(0);
            driver.WaitForAngular();
            Assert.AreEqual(page.CaseGrid.Rows.Count, 1);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            Assert.IsNotNull(page.MainCaseIcon.Displayed);
            page.GetStepButton("1").ClickWithTimeout();
            driver.WaitForAngularWithTimeout(1000);
            //Step 2
            page.CopyCaseTitleButton.ClickWithTimeout();
            Assert.NotNull(page.ReferenceText.Text);
            Assert.IsEmpty(page.RegardingText.Text.Trim());
            page.NarrativePickList.SendKeys(Keys.ArrowDown);
            page.NarrativePickList.SendKeys(Keys.ArrowDown);
            page.NarrativePickList.SendKeys(Keys.Enter);
            Assert.IsNotEmpty(page.RegardingText.Text);
        }

        [TestCase(BrowserType.Chrome, Ignore = "To be reinstated with step 3 e2e, Issue: blank screen is displayed with draft bill load")]
        [TestCase(BrowserType.FireFox, Ignore = "To be reinstated with step 3 e2e, Issue: blank screen is displayed with draft bill load")]
        public void DraftDebitCaseDebtors(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainDebitNote, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var openItemNo = _caseDebtorData.OpenItems[0].OpenItemNo;
            var entityId = _caseDebtorData.EntityId;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/billing/debit-note", user.Username, user.Password);
            var url = Env.RootUrl +"/#/accounting/billing?entityId=" + entityId + "&openItemNo=" + openItemNo;
            driver.Navigate().GoToUrl(url);
            var page = new DebitNotePageObjects(driver);
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            var popup = new CommonPopups(driver);
            Assert.AreEqual(page.CaseGrid.Rows.Count, 1);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            Assert.True(page.MainCaseIcon.Displayed);
            page.CaseGrid.AddButton.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalApply.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.CasePickList.SendKeys("1234/A");
            page.CaseListPickList.WithJs().Focus();
            driver.WaitForAngular();
            Assert.AreEqual(false, page.CaseListPickList.Enabled);
            Assert.AreEqual(true, page.ModalApply.Enabled);
            page.ModalApply.ClickWithTimeout();
            Assert.IsNotNull(popup.ConfirmModal);
            popup.ConfirmModal.Ok().WithJs().Click();
            Assert.AreEqual(page.CaseGrid.Rows.Count, 2);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            Assert.True(page.MainCaseIcon.Displayed);
            page.ContextMenu._removeCase(1);
            driver.WaitForAngular();
            Assert.AreEqual(page.CaseGrid.Rows.Count, 1);
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 6);
            Assert.True(page.MainCaseIcon.Displayed);
            page.DebtorGrid.AddButton.ClickWithTimeout();
            Assert.NotNull(popup.ConfirmModal);
            popup.ConfirmModal.Yes().WithJs().Click();
            page.DebtorPickList.SendKeys("ABCD");
            page.ModalApply.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(page.DebtorGrid.Rows.Count, 1);
            page.GetStepButton("1").ClickWithTimeout();
            driver.WaitForAngularWithTimeout(1000);
            //Step 2
            page.CopyCaseTitleButton.ClickWithTimeout();
            Assert.IsEmpty(page.RegardingText.Text.Trim());
            page.NarrativePickList.SendKeys(Keys.ArrowDown);
            page.NarrativePickList.SendKeys(Keys.ArrowDown);
            page.NarrativePickList.SendKeys(Keys.Enter);
            Assert.IsNotEmpty(page.RegardingText.Text);
        }
    }
}
