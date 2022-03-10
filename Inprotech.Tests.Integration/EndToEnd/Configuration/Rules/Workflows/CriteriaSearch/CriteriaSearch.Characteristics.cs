using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaSearchCharacteristics : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchByCharacteristics(BrowserType browserType)
        {
            CriteriaSearchDbSetup.Result dataFixture;
            using (var setup = new CriteriaSearchDbSetup())
            {
                dataFixture = setup.Setup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);

            var protectedCriteria = driver.FindElement(By.Id("characteristics-include-protected-criteria"));

            Assert.IsTrue(protectedCriteria.Selected, "Protected criteria is ticked by default if a user has MaintainWorkflowRulesProtected permission");

            var page = new WorkflowCharacteristicsPage(driver, "ip-search-by-characteristics");
            
            searchOptions.ResetButton.ClickWithTimeout();
            searchOptions.SearchButton.ClickWithTimeout();
            Assert.IsTrue(searchResults.Rows.Count > 1, "Clicking search button with no criteria should return all results");
            driver.WithJs().ScrollToTop();

            page.CaseTypePl.SendKeys(CriteriaSearchDbSetup.CaseTypeDescription);
            page.JurisdictionPl.SendKeys(CriteriaSearchDbSetup.JurisdictionDescription);
            page.PropertyTypePl.SendKeys(CriteriaSearchDbSetup.ValidPropertyTypeDescription);

            searchOptions.SearchButton.ClickWithTimeout();

            Assert.AreEqual(3, searchResults.Rows.Count, "Enter key executes search");
            Assert.AreEqual(dataFixture.CriteriaNo.ToString(), searchResults.LockedCellText(0, 3), "Correct criteria is returned");
            driver.WithJs().ScrollToTop();
            
            #region select 'best match' and make sure best result is first in the list

            page.CaseTypePl.EnterAndSelect(CriteriaSearchDbSetup.CaseTypeDescription);
            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.JurisdictionDescription);

            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.ValidPropertyTypeDescription);
            page.ActionPl.EnterAndSelect(CriteriaSearchDbSetup.ValidActionDescription);
            page.DateOfLawPl.EnterAndSelect(dataFixture.FormattedDateOfLaw);
            page.CaseCategoryPl.EnterAndSelect(CriteriaSearchDbSetup.ValidCaseCategoryDescription);
            page.SubTypePl.EnterAndSelect(CriteriaSearchDbSetup.ValidSubTypeDescription);
            page.BasisPl.EnterAndSelect(CriteriaSearchDbSetup.ValidBasisDescription);
            page.OfficePl.EnterAndSelect(CriteriaSearchDbSetup.OfficeDescription);

            var searchTypeCombo = new DropDown(driver).ByLabel("workflows.common.localOrForeignDropdown.label");
            searchTypeCombo.Value = "local-clients";

            driver.FindRadio("characteristics-best-match").Click();

            searchOptions.SearchButton.ClickWithTimeout();

            Assert.AreEqual(dataFixture.CriteriaNo.ToString(), searchResults.LockedCellText(0, 3));
            Assert.AreEqual(2, searchResults.Rows.Count);
            driver.WithJs().ScrollToTop();

            #endregion

            #region test 'clear' button - it should clean all inputs and revert checkboxes to defaults            

            // should clear results and fields

            driver.FindCheckbox("characteristics-include-not-in-use").Click(); // select what was not selected by default

            searchOptions.ResetButton.ClickWithTimeout();

            Assert.IsTrue(string.IsNullOrEmpty(page.CaseTypePl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.JurisdictionPl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.PropertyTypePl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.ActionPl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.DateOfLawPl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.CaseCategoryPl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.SubTypePl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.BasisPl.GetText()), "pickList should be cleared");
            Assert.IsTrue(string.IsNullOrEmpty(page.OfficePl.GetText()), "pickList should be cleared");
            Assert.AreEqual(0, searchResults.Rows.Count, "result grid should be cleared");

            Assert.IsTrue(driver.FindRadio("characteristics-exact-match").Input.Selected &&
                          !driver.FindRadio("characteristics-best-match").Input.Selected, "should switch to Exact Match which is default");

            Assert.IsFalse(driver.FindCheckbox("characteristics-include-not-in-use").Input.Selected,
                           "shuold uncheck 'Criteria Not In Use'");
            driver.WithJs().ScrollToTop();

            #endregion

            #region test some well-known search

            searchOptions.ResetButton.ClickWithTimeout();

            // should default sort by office with nulls last

            page.CaseTypePl.EnterAndSelect(CriteriaSearchDbSetup.CaseTypeDescription);
            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.JurisdictionDescription);
            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.ValidPropertyTypeDescription);
            searchOptions.SearchButton.Click();

            Assert.AreEqual(dataFixture.CriteriaNo.ToString(), searchResults.LockedCellText(0, 3));
            Assert.AreEqual(3, searchResults.Rows.Count);

            Assert.AreEqual(CriteriaSearchDbSetup.OfficeDescription, searchResults.CellText(0, 1));
            Assert.AreEqual(CriteriaSearchDbSetup.OfficeDescription1, searchResults.CellText(1, 1));
            Assert.AreEqual(string.Empty, searchResults.CellText(2, 1));

            // shows valid descriptions
            Assert.AreEqual(CriteriaSearchDbSetup.OfficeDescription, searchResults.CellText(0, 1));
            Assert.AreEqual(CriteriaSearchDbSetup.CaseTypeDescription, searchResults.CellText(0, 2));
            Assert.AreEqual(CriteriaSearchDbSetup.JurisdictionDescription, searchResults.CellText(0, 3));
            Assert.AreEqual(CriteriaSearchDbSetup.ValidPropertyTypeDescription, searchResults.CellText(0, 4));
            Assert.AreEqual(CriteriaSearchDbSetup.ValidActionDescription, searchResults.CellText(0, 5));
            Assert.AreEqual(CriteriaSearchDbSetup.ValidCaseCategoryDescription, searchResults.CellText(0, 6));
            searchResults.Cell(0, 11).WithJs().ScrollIntoView();
            Assert.AreEqual(CriteriaSearchDbSetup.ValidSubTypeDescription, searchResults.CellText(0, 7));
            Assert.AreEqual(CriteriaSearchDbSetup.ValidBasisDescription, searchResults.CellText(0, 8));
            Assert.AreEqual(dataFixture.FormattedDateOfLaw, searchResults.CellText(0, 9));
            Assert.IsTrue(searchResults.CellIsSelected(0, 10));
            searchResults.Cell(0, 13).WithJs().ScrollIntoView();
            Assert.IsTrue(searchResults.CellIsSelected(0, 13));

            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CharacteristicsValidCombinations(BrowserType browserType)
        {
            CriteriaSearchDbSetup.Result dataFixture;
            using (var setup = new CriteriaSearchDbSetup())
            {
                dataFixture = setup.Setup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            var page = new WorkflowCharacteristicsPage(driver, "ip-search-by-characteristics");

            var searchOptions = new SearchOptions(driver);

            //should show base lists in type aheads by default

            Assert.IsTrue(page.PropertyTypePl.TypeAheadContains(CriteriaSearchDbSetup.PropertyTypeDescription));
            Assert.IsTrue(page.ActionPl.TypeAheadContains(CriteriaSearchDbSetup.ActionDescription));
            Assert.IsTrue(page.SubTypePl.TypeAheadContains(CriteriaSearchDbSetup.SubTypeDescription));
            Assert.IsTrue(page.BasisPl.TypeAheadContains(CriteriaSearchDbSetup.BasisDescription));
            Assert.IsTrue(page.OfficePl.TypeAheadContains(CriteriaSearchDbSetup.OfficeDescription));

            // should show base lists in pick lists by default

            Assert.IsTrue(page.PropertyTypePl.PickListContains(CriteriaSearchDbSetup.PropertyTypeDescription));
            Assert.IsTrue(page.ActionPl.PickListContains(CriteriaSearchDbSetup.ActionDescription));
            Assert.IsTrue(page.SubTypePl.PickListContains(CriteriaSearchDbSetup.SubTypeDescription));
            Assert.IsTrue(page.BasisPl.PickListContains(CriteriaSearchDbSetup.BasisDescription));
            Assert.IsTrue(page.OfficePl.PickListContains(CriteriaSearchDbSetup.OfficeDescription));

            // should allow valid combination

            page.CaseTypePl.SendKeys(CriteriaSearchDbSetup.CaseTypeDescription);
            page.JurisdictionPl.SendKeys(CriteriaSearchDbSetup.JurisdictionDescription);
            page.PropertyTypePl.SendKeys(CriteriaSearchDbSetup.ValidPropertyTypeDescription);
            page.ActionPl.SendKeys(CriteriaSearchDbSetup.ValidActionDescription);
            page.DateOfLawPl.SendKeys(dataFixture.FormattedDateOfLaw);
            page.CaseCategoryPl.SendKeys(CriteriaSearchDbSetup.ValidCaseCategoryDescription);
            page.SubTypePl.SendKeys(CriteriaSearchDbSetup.ValidSubTypeDescription);
            page.BasisPl.SendKeys(CriteriaSearchDbSetup.ValidBasisDescription);

            Assert.IsFalse(page.CaseTypePl.HasError);
            Assert.IsFalse(page.JurisdictionPl.HasError);
            Assert.IsFalse(page.PropertyTypePl.HasError);
            Assert.IsFalse(page.ActionPl.HasError);
            Assert.IsFalse(page.DateOfLawPl.HasError);
            Assert.IsFalse(page.CaseCategoryPl.HasError);
            Assert.IsFalse(page.SubTypePl.HasError);
            Assert.IsFalse(page.BasisPl.HasError);

            // should show validation error for invalid combination

            searchOptions.ResetButton.Click();

            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.PropertyTypeDescription);
            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.InvalidJurisdictionDescription);
            Assert2.WaitTrue(3, 200, () => page.PropertyTypePl.HasError);

            page.PropertyTypePl.Typeahead.Clear();
            page.CaseTypePl.EnterAndSelect(CriteriaSearchDbSetup.CaseTypeDescription);
            page.ActionPl.EnterAndSelect(CriteriaSearchDbSetup.ActionDescription);
            page.CaseCategoryPl.EnterAndSelect(CriteriaSearchDbSetup.CaseCategoryDescription);
            page.SubTypePl.EnterAndSelect(CriteriaSearchDbSetup.SubTypeDescription);
            page.BasisPl.EnterAndSelect(CriteriaSearchDbSetup.BasisDescription);
            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.InvalidPropertyTypeDescription);

            Assert2.WaitTrue(3, 200, () => page.ActionPl.HasError);
            Assert2.WaitTrue(3, 200, () => page.CaseCategoryPl.HasError);
            Assert2.WaitTrue(3, 200, () => page.SubTypePl.HasError);
            Assert2.WaitTrue(3, 200, () => page.BasisPl.HasError);

            // should not show error if valid item has same code

            searchOptions.ResetButton.Click();

            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.PropertyTypeDescription);
            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.JurisdictionDescription);
            Assert.IsFalse(page.PropertyTypePl.HasError);

            page.PropertyTypePl.Typeahead.Clear();
            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.ValidPropertyTypeDescription);
            Assert.IsFalse(page.PropertyTypePl.HasError);

            // should toggle valid and base descriptions

            searchOptions.ResetButton.Click();

            page.CaseTypePl.EnterAndSelect(CriteriaSearchDbSetup.CaseTypeDescription);
            page.PropertyTypePl.EnterAndSelect(CriteriaSearchDbSetup.PropertyTypeDescription);
            Assert2.WaitEqual(3, 300, () => CriteriaSearchDbSetup.PropertyTypeDescription, () => page.PropertyTypePl.GetText());

            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.JurisdictionDescription);
            Assert2.WaitEqual(3, 300, () => CriteriaSearchDbSetup.ValidPropertyTypeDescription, () => page.PropertyTypePl.GetText());

            page.JurisdictionPl.Typeahead.Clear();
            Assert2.WaitEqual(3, 300, () => CriteriaSearchDbSetup.PropertyTypeDescription, () => page.PropertyTypePl.GetText());

            //shows valid combination descriptions in valid picklists

            searchOptions.ResetButton.Click();

            page.CaseTypePl.EnterAndSelect(CriteriaSearchDbSetup.CaseTypeDescription);
            page.JurisdictionPl.EnterAndSelect(CriteriaSearchDbSetup.JurisdictionDescription);

            var validCombination = GetValidCombinationAndSelect(driver, page.PropertyTypePl, CriteriaSearchDbSetup.ValidPropertyTypeDescription);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.JurisdictionDescription});

            validCombination = GetValidCombinationAndSelect(driver, page.DateOfLawPl, dataFixture.FormattedDateOfLaw);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.JurisdictionDescription, CriteriaSearchDbSetup.ValidPropertyTypeDescription});

            validCombination = GetValidCombinationAndSelect(driver, page.ActionPl, CriteriaSearchDbSetup.ValidActionDescription);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.CaseTypeDescription, CriteriaSearchDbSetup.JurisdictionDescription, CriteriaSearchDbSetup.ValidPropertyTypeDescription});

            validCombination = GetValidCombinationAndSelect(driver, page.CaseCategoryPl, CriteriaSearchDbSetup.ValidCaseCategoryDescription);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.CaseTypeDescription, CriteriaSearchDbSetup.JurisdictionDescription, CriteriaSearchDbSetup.ValidPropertyTypeDescription});

            validCombination = GetValidCombinationAndSelect(driver, page.SubTypePl, CriteriaSearchDbSetup.ValidSubTypeDescription);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.CaseTypeDescription, CriteriaSearchDbSetup.JurisdictionDescription, CriteriaSearchDbSetup.ValidPropertyTypeDescription, CriteriaSearchDbSetup.ValidCaseCategoryDescription});

            validCombination = GetValidCombinationAndSelect(driver, page.BasisPl, CriteriaSearchDbSetup.ValidBasisDescription);
            CollectionAssert.AreEquivalent(validCombination, new List<string> {CriteriaSearchDbSetup.CaseTypeDescription, CriteriaSearchDbSetup.JurisdictionDescription, CriteriaSearchDbSetup.ValidPropertyTypeDescription, CriteriaSearchDbSetup.ValidCaseCategoryDescription});
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShowHideExaminationRenewalTypePickLists(BrowserType browserType)
        {
            CriteriaSearchDbSetup.Result dataFixture;

            var data = DbSetup.Do(setup =>
            {
                var f = new CriteriaSearchDbSetup();
                dataFixture = f.Setup();
                var renewalAction = setup.InsertWithNewId(new Action { ActionType = 1, Name = "e2eRenewalAction" });
                var examAction = setup.InsertWithNewId(new Action { ActionType = 2, Name = "e2eExaminationAction" });

                var newExaminationType = setup.InsertWithNewId(new TableCode { TableTypeId = 8, Name = "e2eExamType" });
                var newRenewalType = setup.InsertWithNewId(new TableCode { TableTypeId = 17, Name = "e2eRenewalType" });

                var examCriteria = setup.DbContext.Set<Criteria>().Single(_ => _.Id == dataFixture.CriteriaNo);
                examCriteria.ActionId = examAction.Code;
                examCriteria.TableCodeId = newExaminationType.Id;

                var renewCriteria = setup.DbContext.Set<Criteria>().Single(_ => _.Id == dataFixture.InheritedCriteriaNo);
                renewCriteria.ActionId = renewalAction.Code;
                renewCriteria.TableCodeId = newRenewalType.Id;

                setup.DbContext.SaveChanges();

                return new
                {
                    ExamCriteria = examCriteria.Id,
                    ExamAction = examAction.Name,
                    ExamType = newExaminationType.Name,
                    RenCriteria = renewCriteria.Id,
                    RenewalAction = renewalAction.Name,
                    RenType = newRenewalType.Name
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            var page = new WorkflowCharacteristicsPage(driver, "ip-search-by-characteristics");
            var searchOptions = new SearchOptions(driver);
            
            page.ActionPl.EnterAndSelect(data.ExamAction);
            Assert.IsTrue(page.ExaminationPl.Displayed, "Examination Pick List appears when examination action seleted");
            page.ExaminationPl.EnterAndSelect(data.ExamType);
            searchOptions.SearchButton.Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(data.ExamCriteria.ToString(), searchResults.LockedCellText(0, 3));
            searchResults.Cell(0, 11).WithJs().ScrollIntoView();
            Assert.AreEqual(data.ExamType, searchResults.CellText(0, 11));

            page.ActionPl.EnterAndSelect(data.RenewalAction);
            Assert.IsTrue(page.RenewalPl.Displayed, "Renewal Type Pick List appears when Renewal action seleted");
            page.RenewalPl.EnterAndSelect(data.RenType);
            searchOptions.SearchButton.Click();
            searchResults.LockedCell(0, 3).WithJs().ScrollIntoView();
            
            Assert.AreEqual(data.RenCriteria.ToString(), searchResults.LockedCellText(0, 3));
            searchResults.Cell(0, 12).WithJs().ScrollIntoView();
            Assert.AreEqual(data.RenType, searchResults.CellText(0, 12));
        }

        List<string> GetValidCombinationAndSelect(NgWebDriver driver, PickList pl, string search)
        {
            pl.OpenPickList(search);

            var validCombination = driver.FindElements(By.CssSelector(".inline-readonly-list span"))
                                         .Select(x => x.Text)
                                         .ToList();
            pl.SelectFirstGridRow();

            return validCombination;
        }
    }
}