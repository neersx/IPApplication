using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Payment;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Names
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release13)]
    class NameView13 : IntegrationTest
    {
        [TearDown]
        public void TearDown()
        {
            DbSetup.Do(db =>
            {
                foreach (var dataValidation in DataValidations)
                {
                    db.DbContext.Set<DataValidation>().Single(_ => _.Id == dataValidation.Id).InUseFlag = true;
                }
                db.DbContext.SaveChanges();
            });
        }

        List<DataValidation> DataValidations { get; set; }

        public void TurnOffDataValidations()
        {
            DbSetup.Do(db =>
            {
                DataValidations = db.DbContext.Set<DataValidation>().Where(_ => _.InUseFlag && _.FunctionalArea == "N").ToList();
                foreach (var dataValidation in DataValidations)
                {
                    dataValidation.InUseFlag = false;
                }
                db.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NameViewDetails(BrowserType browserType)
        {
            var setup = new NamesDataSetup();
            var data = setup.CreateNamesScreenDataSetup();
            var driver = BrowserProvider.Get(browserType);

            NameViewSupplierDetailsBefore16(driver, data.Supplier, data.SendPayToName, data.Creditor, browserType);
            
            TestQuickLinks(driver, data.Individual);

            TestTrustAccounting(driver, data.Supplier, data.TrustItemList, data.LocalCurrency);
        }

        public void NameViewSupplierDetailsBefore16(NgWebDriver driver,  Name supplier, AssociatedName sendPayToName, Creditor creditor, BrowserType browserType)
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
                                  _.Code, UsedBy = (short)_.UsedBy, _.Description
                              }).First(_ => (_.UsedBy & (int) KnownApplicationUsage.AccountsPayable) == (int) KnownApplicationUsage.AccountsPayable ||
                                                                  (_.UsedBy & (int) KnownApplicationUsage.AccountsReceivable) == (int) KnownApplicationUsage.AccountsReceivable);
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
            Assert.AreEqual("Your changes have been successfully saved.",nameViewPage.MessageDiv.Text);

            Assert.IsTrue(nameViewPage.IsSaveDisabled(), "Should be disabled after saving data");
            ReloadPage(driver);
            Assert.AreEqual(reasonDb.reason.Description, supplierDetails.ReasonDropDown.Text, "Reason should have value entered earlier");
            Assert.AreNotEqual(string.Empty, ledgerAccount.GetText(), "Ledger Account should be set.");
            Assert.AreEqual($"({currency.lastCurrency.Id}) {currency.lastCurrency.Description}", purchaseCurrency.GetText(), "Purchase Currency should be changed to selected value");

            //Test Sanity Check
            TurnOffDataValidations();
            var dv = new DataValidation();
            DbSetup.Do(db =>
            {
                dv.InUseFlag = true;
                dv.FunctionalArea = "N";
                dv.DisplayMessage = "there is a sanity problem";
                dv.RuleDescription = "sanity problem";
                dv.Notes = "a sanity problem has been found";
                dv.IsWarning = false;
                db.DbContext.Set<DataValidation>().Add(dv);
                db.DbContext.SaveChanges();
            });

            var testPurchaseDescString = "test e2e";
            supplierDetails.PurchaseDescriptionTextbox.Clear();
            supplierDetails.PurchaseDescriptionTextbox.SendKeys(testPurchaseDescString);
            Assert.False(supplierDetails.SaveButton.IsDisabled());
            supplierDetails.SaveButton.Click();

            Assert.IsNotNull(popups.SanityCheckModal, "sanity check modal is present");
            popups.SanityCheckModal.Close();
            ReloadPage(driver);
            Assert.AreNotEqual(testPurchaseDescString, supplierDetails.PurchaseDescriptionTextbox.Text, "Details should not save if sanity error present");
        }

        void TestQuickLinks(NgWebDriver driver, Name name)
        {
            SignIn(driver, $"/#/nameview/{name.Id}?programId={KnownNamePrograms.NameEntry}");
            var q = new QuickLinks(driver);
            q.Open("contextNameDetails");
            Assert.AreEqual(name.Id.ToString(), q.SlideContainer.FindElement(By.Name("internalNameId")).Text, "Name Id matches the displayed name");
            Assert.AreEqual(name.Soundex, q.SlideContainer.FindElement(By.Name("soundexCode")).Text, "Name soundex matches the displayed name");
            Assert.AreEqual(name.DateEntered?.ToString("dd-MMM-yyyy hh:mm tt"), q.SlideContainer.FindElement(By.Name("dateEntered")).Text, "Name date entered matches the displayed name");
            q.Close();
        }

        void TestTrustAccounting(NgWebDriver driver, Name name, dynamic trustItems, string localCurrency)
        {
            SignIn(driver, $"/#/nameview/{name.Id}?programId={KnownNamePrograms.NameEntry}");
            
            var topic = new TrustAccountingTopic(driver);
            topic.NavigateTo();
            Assert.AreEqual(2, topic.Grid.Rows.Count, "TrustAccounting grid contains 2 records");

            var localBalance = localCurrency + string.Format("{0:#,##0.00}", Math.Round(trustItems[0].LocalBalance + trustItems[1].LocalBalance, 2));

            Assert.NotNull(topic.LocalBalanceTotal.Text, "Trust Accounting Topic - Local Balance Total is displayed correctly as " + topic.LocalBalanceTotal.Text);
            Assert.AreEqual(localBalance, topic.LocalBalanceTotal.Text, "Local Balance Total is displayed correctly as " + localBalance);

            CheckDataForRow(0, 1);
            CheckDataForRow(1, 2);
            
            void CheckDataForRow(int rowIndex, int noOfRows)
            {
                Assert.AreEqual(trustItems[rowIndex].EntityName, topic.Grid.CellText(rowIndex, 0), $"Trust Accounting - Entity Name text for row {rowIndex} should be displayed as {trustItems[rowIndex].EntityName}");
                Assert.AreEqual(trustItems[rowIndex].BankAccount, topic.Grid.CellText(rowIndex, 1), $"Trust Accounting - Bank account name text for row {rowIndex} should be displayed as {trustItems[rowIndex].BankAccount}");
                Assert.AreEqual(localCurrency + string.Format("{0:#,##0.00}", Math.Round(trustItems[rowIndex].LocalBalance, 2)), topic.Grid.CellText(rowIndex, 2), $"Trust Accounting - Local balance From row {rowIndex} should be displayed as {topic.Grid.CellText(rowIndex, 2)}");
                
                Assert.AreEqual(localBalance, topic.LocalBalanceTotal.Text, "Local Balance Total is displayed correctly as " + localBalance);

                topic.ClickLocalBalance(rowIndex);
                driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
                Assert.AreEqual(noOfRows, topic.DetailGrid.Rows.Count, $"detail TrustAccounting grid contains {noOfRows} records for row {rowIndex}");

                Assert.NotNull(topic.LocalValueTotal.Text, "Trust Accounting Topic - Local Value Total is displayed correctly as " + topic.LocalValueTotal.Text);
                Assert.NotNull(topic.DetailLocalBalanceTotal.Text, "Trust Accounting Topic - Local Balance Total is displayed correctly as " + topic.DetailLocalBalanceTotal.Text);

                Assert.AreEqual(localCurrency + string.Format("{0:#,##0.00}", Math.Round(trustItems[rowIndex].LocalBalance, 2)), topic.DetailLocalBalanceTotal.Text, "Trust Accounting detail popup - Local Balance Total is displayed correctly as " + topic.DetailLocalBalanceTotal.Text);
                topic.ClosePopup();
            }
        }
    }
}