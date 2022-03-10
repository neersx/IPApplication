using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Payment;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Names
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class NameView16 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NameViewDetails(BrowserType browserType)
        {
            var setup = new NamesDataSetup();
            var data = setup.CreateNamesScreenDataSetup();
            var bankAccount1 = (BankAccount)data.BankAccount1;
            DbSetup.Do(db =>
            {
                var updatedBankAccount1 = db.DbContext.Set<BankAccount>().Single(v => v.AccountOwner == bankAccount1.AccountOwner && v.BankNameNo == bankAccount1.BankNameNo && v.SequenceNo == bankAccount1.SequenceNo);
                updatedBankAccount1.AccountName = RandomString.Next(25);
                updatedBankAccount1.AccountNo = RandomString.Next(25);
                new DocumentManagementDbSetup().Setup(IntegrationType.Work10V1);
                db.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            NameViewSupplierDetailsAfter16(driver, data.Supplier, data.SendPayToName, data.Creditor, browserType);
            NameViewDmsTopic(driver, data.Supplier, browserType);
        }

        public void NameViewSupplierDetailsAfter16(NgWebDriver driver, Name supplier, AssociatedName sendPayToName, Creditor creditor, BrowserType browserType)
        {
            SignIn(driver, $"/#/nameview/{supplier.Id}?programId={KnownNamePrograms.NameEntry}");
            var nameViewPage = new NameViewDetailPageObjects(driver);

            var supplierDetails = new SupplierDetailsTopic(driver);

            Assert.True(nameViewPage.PageTitle().Contains(supplier.LastName), "Page title should contain last name");
            Assert.True(supplierDetails.SupplierType.IsDisplayed, "Supplier Type dropdown should be displayed in topic");
            Assert.AreEqual(creditor.PurchaseDescription, supplierDetails.PurchaseDescriptionTextbox.Value());
            Assert.True(supplierDetails.SendTo.InputValue.Contains(sendPayToName.RelatedName.FirstName), "Send To name is correct.");

            var purchaseCurrency = new AngularPicklist(driver).ByName("PurchaseCurrency");

            var currency = DbSetup.Do(x =>
            {
                var firstCurrency = x.DbContext.Set<Currency>().First();
                var lastCurrency = x.DbContext.Set<Currency>().OrderByDescending(_ => _.Id).First();
                return new
                {
                    firstCurrency,
                    lastCurrency
                };
            });

            purchaseCurrency.Typeahead.SendKeys(currency.firstCurrency.Id);
            purchaseCurrency.Typeahead.SendKeys(Keys.ArrowDown);
            purchaseCurrency.Typeahead.SendKeys(Keys.Enter);
            Assert.AreEqual($"({currency.firstCurrency.Id}) {currency.firstCurrency.Description}", purchaseCurrency.GetText(), "Purchase Currency should be (code) + desc");
            Assert.AreNotEqual(string.Empty, purchaseCurrency.GetText(), "Purchase Currency should have value");

            purchaseCurrency.Typeahead.Clear();
            Assert.AreEqual(string.Empty, purchaseCurrency.GetText(), "Purchase Currency should have value");
            purchaseCurrency.OpenPickList();
            purchaseCurrency.SearchFor(currency.lastCurrency.Description);
            purchaseCurrency.SearchGrid.ClickRow(0);
            Assert.AreEqual($"({currency.lastCurrency.Id}) {currency.lastCurrency.Description}", purchaseCurrency.GetText(), "Purchase Currency should be changed with Code + desc format");

            var profitCenterPicklist = new AngularPicklist(driver).ByName("ProfitCentre");
            profitCenterPicklist.OpenPickList();
            Assert.AreEqual(1, profitCenterPicklist.SearchGrid.Rows.Count, "Should filter the grid with selected value");
            profitCenterPicklist.Close();
            driver.WaitForAngularWithTimeout(browserType == BrowserType.Ie ? 1000 : 500);

            Assert.AreNotEqual(string.Empty, profitCenterPicklist.GetText(), "Purchase Currency should have value");

            var exchangeRateSchedule = new AngularPicklist(driver).ByName("ExchangeRateSchedule");
            Assert.True(exchangeRateSchedule.Enabled, "Purchase Currency should have value");

            var ledgerAccount = new AngularPicklist(driver).ByName("LedgerAccount");
            ledgerAccount.Typeahead.SendKeys("Cur");
            ledgerAccount.Typeahead.SendKeys(Keys.ArrowDown);
            ledgerAccount.Typeahead.SendKeys(Keys.Enter);
            Assert.AreNotEqual(string.Empty, ledgerAccount.GetText(), "Ledger Account should get set.");

            var wipTemplate = new AngularPicklist(driver).ByName("wipTemplate");
            wipTemplate.OpenPickList();
            Assert.IsTrue(wipTemplate.ModalDisplayed);

            wipTemplate.SearchGrid.ClickRow(1);
            Assert.AreNotEqual(string.Empty, wipTemplate.GetText(), "Wip template picklist should have value");

            supplierDetails.SendTo.OpenPickList();
            Assert.IsTrue(supplierDetails.SendTo.ModalDisplayed, "Can open send to picklist");
            Assert.IsTrue(supplierDetails.SendTo.SearchGrid.CellText(0, 0).Contains(sendPayToName.RelatedName.FirstName), "Should show the right send to name in pick list");
            supplierDetails.SendTo.Close();

            supplierDetails.SendToAttentionName.OpenPickList();
            Assert.IsTrue(supplierDetails.SendToAttentionName.ModalDisplayed, "Can open send to attention picklist");
            supplierDetails.SendToAttentionName.Close();

            supplierDetails.SendToAddress.OpenPickList();
            Assert.IsTrue(supplierDetails.SendToAddress.ModalDisplayed, "Can open address picklist");
            Assert.AreEqual(2, supplierDetails.SendTo.SearchGrid.Rows.Count, "Shows the correct number of addresses");
            supplierDetails.SendToAddress.Close();

            Assert.AreEqual(creditor.Instructions, supplierDetails.InstructionTextbox.Value(), "Instructions should be pre filled");
            Assert.AreEqual(creditor.ChequePayee, supplierDetails.Payee.Value(), "Payee should have value entered earlier");
            Assert.AreEqual(creditor.PaymentMethod.ToString(), supplierDetails.PaymentMethodDropDown.Value, "Payment method should be selected");

            Assert.IsTrue(supplierDetails.ReasonDropDown.IsDisabled, "Reason dropdown should be disable when Payment restrictions are not entered");

            var crRestriction = DbSetup.Do(x =>
            {
                var restriction = x.DbContext.Set<CrRestriction>().First();
                return new
                {
                    restriction
                };
            });

            var reasonDb = DbSetup.Do(x =>
            {
                var reason = x.DbContext.Set<Reason>()
                              .Select(_ => new
                              {
                                  _.Code,
                                  UsedBy = (short)_.UsedBy,
                                  _.Description
                              }).First(_ => (_.UsedBy & (int)KnownApplicationUsage.AccountsPayable) == (int)KnownApplicationUsage.AccountsPayable ||
                                                                  (_.UsedBy & (int)KnownApplicationUsage.AccountsReceivable) == (int)KnownApplicationUsage.AccountsReceivable);
                return new
                {
                    reason
                };
            });

            supplierDetails.PaymentRestrictionDropDown.Input.SelectByText(crRestriction.restriction.Description);
            Assert.IsFalse(supplierDetails.ReasonDropDown.IsDisabled, "Reason dropdown should be enable after Payment restrictions entered");
            Assert.IsTrue(nameViewPage.IsSaveDisplayed, "Save button should be displayed");

            Assert.IsTrue(supplierDetails.ReasonDropDown.HasError, "Reason dropdown should be have error when restriction selected");
            Assert.IsTrue(nameViewPage.IsSaveDisabled(), "For errors in page Save button should be disabled");

            supplierDetails.ReasonDropDown.Input.SelectByText(reasonDb.reason.Description);
            nameViewPage.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            Assert.IsNotNull(popups.ConfirmModal, "confirm modal is present");
            popups.ConfirmModal.PrimaryButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", nameViewPage.MessageDiv.Text);

            Assert.IsTrue(nameViewPage.IsSaveDisabled(), "Should be disabled after saving data");
            ReloadPage(driver);
            Assert.AreEqual(reasonDb.reason.Description, supplierDetails.ReasonDropDown.Text, "Reason should have value entered earlier");
            Assert.AreNotEqual(string.Empty, ledgerAccount.GetText(), "Ledger Account should be set.");
            Assert.AreEqual($"({currency.lastCurrency.Id}) {currency.lastCurrency.Description}", purchaseCurrency.GetText(), "Purchase Currency should be changed to selected value");
        }

        public void NameViewDmsTopic(NgWebDriver driver, Name name, BrowserType browserType)
        {
            SignIn(driver, $"/#/nameview/{name.Id}?programId={KnownNamePrograms.NameEntry}");
            var nameViewPage = new NameViewDetailPageObjects(driver);
            var nameDMSTopic = new NameDmsTopic(driver);

            Assert.IsNotEmpty(nameDMSTopic.DirectoryTreeView.Folders);
            Assert.True(nameDMSTopic.DirectoryTreeView.Folders.First().FolderIcon.IndexOf("cpa-icon-workspace", StringComparison.Ordinal) > -1);

            Assert.True(nameDMSTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Email").FolderIcon.IndexOf("cpa-icon-envelope", StringComparison.Ordinal) > -1);
            Assert.AreEqual(true, nameDMSTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Correspondence").IsParent);
            Assert.True(nameDMSTopic.DirectoryTreeView.Folders.First().Children.First().FolderIcon.IndexOf("cpa-icon-folder", StringComparison.Ordinal) > -1);

            nameDMSTopic.DirectoryTreeView.Folders[0].Children[0].Click();
            Assert.IsNotEmpty(nameDMSTopic.Documents.Rows);
            Assert.AreEqual(1, nameDMSTopic.Documents.Cell(0, 1).FindElements(By.ClassName("cpa-icon-envelope")).Count);
            Assert.AreEqual(1, nameDMSTopic.Documents.Cell(0, 2).FindElements(By.ClassName("cpa-icon-paperclip")).Count);

            Assert.True(nameViewPage.PageTitle().Contains(name.LastName), "Page title should contain last name");
            Assert.True(nameDMSTopic.IsActive(), "Supplier Type dropdown should be displayed in topic");
        }

    }
}
