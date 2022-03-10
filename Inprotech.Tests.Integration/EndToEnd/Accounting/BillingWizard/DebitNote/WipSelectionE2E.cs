using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
    class WipSelectionE2E : IntegrationTest
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
        public void WipSelection(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainDebitNote, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/billing/debit-note", user.Username, user.Password);
            var page = new DebitNotePageObjects(driver);
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
            page.GetStepButton("2").ClickWithTimeout();
            driver.WaitForAngularWithTimeout(1000);
            Assert.AreNotEqual(page.WipSelectionGrid.Rows.Count, 0);
            Assert.AreEqual(page.SelectAllBtn.Enabled, true);
            Assert.AreEqual(page.DeSelectAllBtn.Enabled, true);
            page.DeSelectAllBtn.Click();
            Assert.IsTrue(page.TotalBilled.Text.Contains("0.00"));
            Assert.AreEqual(string.Empty, page.WipSelectionGrid.CellText(0, 7));
            page.SelectAllBtn.Click();
            Assert.IsFalse(page.TotalBilled.Text.Contains("0.00"));
            Assert.AreNotEqual(string.Empty, page.WipSelectionGrid.CellText(0, 7));
            page.WipSelectionGrid.Cell(0,7).Click();
            Assert.NotNull(page.Modal);
            Assert.IsTrue(page.LocalBilledInput.Input.Enabled);
            page.LocalBilledInput.SetValue = "220";
            Assert.IsTrue(page.WriteUpRadioBtn.Displayed);
            page.ReasonDropDown.Input.SelectByText("Discount"); 
            Assert.IsTrue(page.ModalApply.Enabled);
            page.ModalApply.ClickWithTimeout();
            Assert.AreNotEqual(string.Empty, page.WipSelectionGrid.CellText(0, 7));
            
        }

    }
}
