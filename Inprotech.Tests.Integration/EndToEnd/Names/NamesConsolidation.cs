using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NUnit.Framework;
using OpenQA.Selenium;
using GIndex = Inprotech.Tests.Integration.EndToEnd.Names.NamesConsolidationPageObjects.NamesToConsolidateGridIndexes;

namespace Inprotech.Tests.Integration.EndToEnd.Names
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NamesConsolidation : IntegrationTest
    {
        Action<DbSetup> _cleanupAction;

        [TearDown]
        public void CleanupModifiedData()
        {
            if (_cleanupAction != null)
                DbSetup.Do(_cleanupAction);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewNamesConsolidation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/names/consolidation");

            var ceasedName = DbSetup.Do(x =>
            {
                var n1 = new NameBuilder(x.DbContext).CreateClientIndividual("ceased");
                n1.DateCeased = DateTime.Today.AddYears(-1);
                x.DbContext.SaveChanges();
                return n1;
            });
            
            var page = new NamesConsolidationPageObjects(driver);
            page.OpenNamePicklistViaAddButton();

            var defaultCount = 3;
            SelectPicklistRows(1, 3, 5);

            page.NamesPicklist.Apply();

            AssertNoItemFromGridSelected();
            Assert.IsEmpty(page.NamesDetailsShown());

            int nameToConsolidateIntoRow = 1;
            page.ClickMergeIcon(nameToConsolidateIntoRow);
            var namesToBeConsolidated = page.RowsWithMergeIconShown().ToArray();
            Assert.AreEqual(2, namesToBeConsolidated.Length);
            Assert.False(namesToBeConsolidated.Contains(nameToConsolidateIntoRow));

            Assert.AreEqual(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.Name), page.NamesPicklist.GetText());

            var nameDetails = page.NamesDetailsShown().ToArray();
            Assert.Contains(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.Name), nameDetails, "Should show name column");
            Assert.Contains(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.NameCode), nameDetails, "Should show name code column");
            Assert.Contains(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.Remarks), nameDetails, "Should show remarks column");
            Assert.Contains(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.NameNo), nameDetails, "Should show name no column");
            Assert.Contains(page.NamesToConsolidateGridText(nameToConsolidateIntoRow, GIndex.DateCeased), nameDetails, "Should show date ceased column");

            page.NamesPicklist.Clear();
            AssertNoItemFromGridSelected();
            Assert.IsEmpty(page.NamesDetailsShown());

            page.NamesPicklist.OpenPickList();
            page.NamesPicklist.SelectFirstGridRow();

            AssertNoItemFromGridSelected();
            Assert.IsNotEmpty(page.NamesDetailsShown());

            ReloadPage(driver);

            AssertCeasedDateShown();
            
            void SelectPicklistRows(params int[] rowIndex)
            {
                foreach (var i in rowIndex)
                {
                    page.NamesPicklist.SearchGrid.SelectIpCheckbox(i);
                }
            }

            void AssertNoItemFromGridSelected()
            {
                Assert.AreEqual(defaultCount, page.NamesToConsolidateGrid.Rows.Count);
                Assert.AreEqual(defaultCount, page.RowsWithMergeIconShown().Count());
            }

            void AssertCeasedDateShown()
            {                
                page.OpenNamePicklistViaAddButton();
                SelectName(page, ceasedName.SearchKey1);
                page.NamesPicklist.Apply();

                var expectedCeasedDate = ceasedName.DateCeased.GetValueOrDefault().ToString("dd-MMM-yyyy").ToUpper();
                var gridCeasedDate = page.NamesToConsolidateGridText(0, GIndex.DateCeased)?.ToUpper();
                Assert.AreEqual(expectedCeasedDate,  gridCeasedDate, "Should ceased date column");

                page.ClickMergeIcon(0);

                Assert.Contains(expectedCeasedDate, page.NamesDetailsShown().Select(_ => _?.ToUpper()).ToArray());
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PerformNamesConsolidation(BrowserType browserType)
        {
            Name clientOrg = null, clientInd = null, staff = null, supOrg = null, supInd = null;

            var namesData = Task.Run(() =>
            {
                clientOrg = new NameBuilder(new SqlDbContext()).CreateClientOrg("cliorg");
                clientInd = new NameBuilder(new SqlDbContext()).CreateClientIndividual("cliind");
                staff = new NameBuilder(new SqlDbContext()).CreateStaff("sta");
                supOrg = new NameBuilder(new SqlDbContext()).CreateSupplierOrg("suporg");
                supInd = new NameBuilder(new SqlDbContext()).CreateSupplierIndividual("supind");
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/names/consolidation");

            var page = new NamesConsolidationPageObjects(driver);
            var popups = new CommonPopups(driver);
            page.OpenNamePicklistViaAddButton();

            namesData.Wait();
            SelectName(page, clientOrg.SearchKey1);
            SelectName(page, clientInd.SearchKey1);
            SelectName(page, staff.SearchKey1);
            SelectName(page, supOrg.SearchKey1);
            SelectName(page, supInd.SearchKey1);

            page.NamesPicklist.Apply();

            Assert.AreEqual(5, page.NamesToConsolidateGrid.Rows.Count);
            Assert.True(page.BtnNamesConsolidation.IsDisabled());

            page.NamesToConsolidateGrid.FindRow((int)GIndex.Name, clientOrg.Formatted(), out var clientOrgIndex);
            page.ClickMergeIcon(clientOrgIndex);

            Assert.False(page.BtnNamesConsolidation.IsDisabled(), "Should enable consolidation button once the Consolidate into field is filled.");

            page.BtnNamesConsolidation.Click();

            Assert.True(popups.ConfirmModal.Modal.Displayed, "Should display confirmaiton dialog");
            popups.ConfirmModal.Proceed();

            Assert.True(popups.AlertModal.Modal.Displayed, "Should display confirmaiton dialog");
            popups.AlertModal.Ok();

            TestWarningIcon(page, 1, "Consolidating an individual into an organisation.");
            TestWarningIcon(page, 3, "Consolidating a non-client into a client.");
            TestWarningIcon(page, 4, "Consolidating a non-client into a client.");

            TestErrorIcon(page, 2, "Cannot consolidate an employee into an organisation.");
            Assert.True(page.BtnNamesConsolidation.IsDisabled(), "Should prevent consolidation as blocking validation found");

            page.NamesToConsolidateGrid.ToggleDelete(2);
            Assert.False(page.BtnNamesConsolidation.IsDisabled(), "Should enable consolidation after removing the offending name causing the blocking error");
            page.BtnNamesConsolidation.Click();

            Assert.True(page.ConfirmModal.Modal.Displayed, "Should seek confirmation again");
            page.ConfirmModal.Proceed();

            Assert.True(page.BtnNamesConsolidation.IsDisabled(), "Should disable consolidation as job submitted");
            Assert.True(page.Add.IsDisabled(), "Should disable adding of new names as consolidation is in progress");
            Assert.False(page.NamesPicklist.Enabled, "Should disable names picklist as consolidation is in progress");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PerformNamesConsolidationWithFinancialDataValidation(BrowserType browserType)
        {
            Name clientOrg = null, clientInd = null, supOrg = null, supInd = null, inActive = null, acctEntry = null, outstandingBalance = null, finData = null;

            _cleanupAction = x =>
            {
                SetSiteControlValue(x, false);
            };

            var namesData = Task.Run(() =>
            {
                var setup = new DbSetup();
                clientOrg = new NameBuilder(setup.DbContext).CreateClientOrg("cliorg");
                clientInd = new NameBuilder(setup.DbContext).CreateClientIndividual("cliind");
                supOrg = new NameBuilder(setup.DbContext).CreateSupplierOrg("suporg");
                supInd = new NameBuilder(setup.DbContext).CreateSupplierIndividual("supind");

                inActive = new NameBuilder(setup.DbContext).CreateSupplierIndividual("inActive");
                acctEntry = new NameBuilder(setup.DbContext).CreateSupplierIndividual("acctEntry");
                outstandingBalance = new NameBuilder(setup.DbContext).CreateSupplierIndividual("outstBal");
                finData = new NameBuilder(setup.DbContext).CreateSupplierIndividual("finData");

                SetSiteControlValue(setup, false);

                setup.Insert(new SpecialName
                {
                    Id = acctEntry.Id,
                    IsEntity = 1
                });

                setup.Insert(new SpecialName
                {
                    Id = outstandingBalance.Id
                });

                setup.Insert(new Account()
                {
                    EntityId = outstandingBalance.Id,
                    NameId = outstandingBalance.Id,
                    Balance = 1
                });

                setup.Insert(new Diary()
                {
                    EmployeeNo = finData.Id,
                    EntryNo = 1,
                    CreatedOn = Fixture.Today()
                });
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/names/consolidation");

            var page = new NamesConsolidationPageObjects(driver);
            var popups = new CommonPopups(driver);
            page.OpenNamePicklistViaAddButton();

            namesData.Wait();
            SelectName(page, clientOrg.SearchKey1);
            SelectName(page, clientInd.SearchKey1);
            SelectName(page, supOrg.SearchKey1);
            SelectName(page, supInd.SearchKey1);
            SelectName(page, inActive.SearchKey1);
            SelectName(page, acctEntry.SearchKey1);
            SelectName(page, outstandingBalance.SearchKey1);
            SelectName(page, finData.SearchKey1);

            page.NamesPicklist.Apply();

            Assert.AreEqual(8, page.NamesToConsolidateGrid.Rows.Count);
            Assert.True(page.BtnNamesConsolidation.IsDisabled());

            page.NamesToConsolidateGrid.FindRow((int)GIndex.Name, clientOrg.Formatted(), out var clientOrgIndex);
            page.ClickMergeIcon(clientOrgIndex);

            page.BtnNamesConsolidation.Click();
            popups.ConfirmModal.Proceed();

            Assert.True(page.ConfirmModal.Modal.Displayed);
            page.ConfirmModal.Proceed();

            Assert.True(popups.AlertModal.Modal.Displayed);
            popups.AlertModal.Ok();

            page.NamesToConsolidateGrid.FindRow((int)GIndex.Name, acctEntry.Formatted(), out var acctEntryRowIndex);
            page.NamesToConsolidateGrid.FindRow((int)GIndex.Name, finData.Formatted(), out var finDataRowIndex);

            TestErrorIcon(page, acctEntryRowIndex, "This name is configured as an Entity for accounting purposes and has its own ledger of accounts. Therefore it cannot be consolidated with other names.");
            TestErrorIcon(page, finDataRowIndex, "There are accounting transactions associated with this name.");
            Assert.True(page.BtnNamesConsolidation.IsDisabled());

            DbSetup.Do(x =>
            {
                SetSiteControlValue(x, true);
            });

            page.Clear(true);
            page.OpenNamePicklistViaAddButton();
            SelectName(page, clientOrg.SearchKey1);
            SelectName(page, clientInd.SearchKey1);
            SelectName(page, supOrg.SearchKey1);
            SelectName(page, supInd.SearchKey1);
            SelectName(page, inActive.SearchKey1);
            SelectName(page, outstandingBalance.SearchKey1);
            SelectName(page, finData.SearchKey1);

            page.NamesPicklist.Apply();

            page.NamesToConsolidateGrid.FindRow((int)GIndex.Name, clientOrg.Formatted(), out clientOrgIndex);
            page.ClickMergeIcon(clientOrgIndex);

            page.BtnNamesConsolidation.Click();
            popups.ConfirmModal.Proceed();

            Assert.True(page.ConfirmModal.Modal.Displayed);
            Assert.True(page.ConfirmModal.Modal.Text.Contains("At least one of the selected names is a different entity type to the name you are consolidating into. You can ignore this and press Proceed to continue with the consolidation, or press Cancel and resolve the issue(s)."));
            page.ConfirmModal.Proceed();

            Assert.True(page.ConfirmModal.Modal.Displayed);
            Assert.True(page.ConfirmModal.Modal.Text.Contains("At least one of the selected names has associated financial data for which a warning was generated. You can ignore this and press Proceed to continue with the consolidation, or press Cancel and resolve the issue(s)."));
            page.ConfirmModal.Proceed();

            Assert.True(page.BtnNamesConsolidation.IsDisabled());
            Assert.True(page.Add.IsDisabled());
            Assert.False(page.NamesPicklist.Enabled);

        }

        void TestWarningIcon(NamesConsolidationPageObjects page, int rowIndex, string expectedErrorMessage)
        {
            var warningSpan = page.NamesToConsolidateGrid.Cell(rowIndex, (int)GIndex.ErrorInfo).FindElements(By.ClassName("text-orange"));
            Assert.IsNotEmpty(warningSpan);
            var warning = warningSpan.First().FindElement(By.ClassName("cpa-icon-exclamation-triangle"));
            Assert.AreEqual(expectedErrorMessage, warning.GetAttribute("uib-popover"));
        }

        void TestErrorIcon(NamesConsolidationPageObjects page, int rowIndex, string expectedErrorMessage)
        {
            var warningSpan = page.NamesToConsolidateGrid.Cell(rowIndex, (int)GIndex.ErrorInfo).FindElements(By.ClassName("text-red"));
            Assert.IsNotEmpty(warningSpan);
            var warning = warningSpan.First().FindElement(By.ClassName("cpa-icon-exclamation-triangle"));
            Assert.AreEqual(expectedErrorMessage, warning.GetAttribute("uib-popover"));
        }

        void SelectName(NamesConsolidationPageObjects page, string name)
        {
            page.NamesPicklist.SearchFor(name);
            page.NamesPicklist.SelectFirstGridRow();
        }

        void SetSiteControlValue(DbSetup setup, bool value)
        {
            var nameConsolidate = setup.DbContext.Set<SiteControl>()
                                   .Single(_ => _.ControlId == SiteControls.NameConsolidateFinancials);
            nameConsolidate.BooleanValue = value;
            setup.DbContext.SaveChanges();
        }
    }
}