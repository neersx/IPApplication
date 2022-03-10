using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Work
{
    [TestFrom(DbCompatLevel.Release16)]
    [Category(Categories.E2E)]
    [TestFixture]
    public class WipDisbursements : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TestWipDisbursements(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.RecordWip)
                                  .WithPermission(ApplicationTask.DisbursementDissection).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/wip-disbursements", user.Username, user.Password);
            var page = new WipDisbursementsPageObject(driver);
            Assert.IsTrue(page.SaveButton.IsDisabled());
            Assert.IsNotEmpty(page.TransactionDate.Value);
            page.DisbursementsGrid.AddButton.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.IsNotEmpty(page.Date.Value);
            Assert.IsFalse(page.Date.Input.Enabled);
            Assert.IsFalse(page.ModalApply.Enabled);
            Assert.IsTrue(page.ModalCancel.Enabled);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.Enter);
            page.Amount.Input.SendKeys("200");
            Assert.IsTrue(page.ModalApply.Enabled);
            page.ModalApply.ClickWithTimeout();
            Assert.IsTrue(page.CasePickList.HasError);
            Assert.IsTrue(page.NamePickList.HasError);
            page.CasePickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.CasePickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.CasePickList.Typeahead.SendKeys(Keys.Enter);
            Assert.IsFalse(page.CasePickList.HasError);
            Assert.IsFalse(page.NamePickList.HasError);
            page.AddAnotherCheckbox.Click();
            page.ModalApply.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.DisbursementPickList.Typeahead.SendKeys(Keys.Enter);
            page.Amount.Input.SendKeys("300");
            page.CasePickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.CasePickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.CasePickList.Typeahead.SendKeys(Keys.ArrowDown);
            page.CasePickList.Typeahead.SendKeys(Keys.Enter);
            page.AddAnotherCheckbox.Click();
            page.ModalApply.ClickWithTimeout();
            Assert.AreEqual(page.DisbursementsGrid.Rows.Count, 2);
            Assert.IsTrue(page.DisbursementsGrid.Cell(0, 8).Text.Contains("200"));
            Assert.IsTrue(page.DisbursementsGrid.Cell(1, 8).Text.Contains("300"));
            page.DisbursementsGrid.ClickEdit(0);
            Assert.NotNull(page.Modal);
            page.ModalCancel.ClickWithTimeout();
            page.DisbursementsGrid.ClickDelete(0);
            Assert.AreEqual(page.DisbursementsGrid.Rows.Count, 1);
            page.TotalAmount.Input.SendKeys("500");
            Assert.IsFalse(page.SaveButton.IsDisabled());
            page.SaveButton.Click();
            driver.WaitForAngular();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.AlertModal, "The total amount of Dissection rows entered does not equal the amount entered for Disbursement. These amounts must match before these details can be added.");
            popups.AlertModal.Ok();

            page.TotalAmount.Input.Clear();
            page.TotalAmount.Input.SendKeys("300");
            page.SaveButton.Click();
            Assert.NotNull(popups.ConfirmModal, "Success message will be displayed");
            popups.ConfirmModal.Ok();
        }
    }
}