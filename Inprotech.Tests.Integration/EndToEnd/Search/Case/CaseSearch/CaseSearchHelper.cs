using System.Linq;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    internal static class CaseSearchHelper
    {
        public static void TestCaseSearchResults(CaseSearchCaseBuilder.SummaryData summaryData, NgWebDriver driver, bool isExternal = false)
        {
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);
            searchPage.CaseSearchBuilder().WithJs().Click();
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            searchPage.References.NavigateTo();
            searchPage.References.CaseReference.SendKeys(summaryData.Case.Irn);

            searchPage.Details.NavigateTo();
            if (!isExternal)
            {
                searchPage.Details.CaseOffice.EnterAndSelect(summaryData.Case.Office.Name);
            }

            searchPage.Details.CaseType.EnterAndSelect(summaryData.Case.Type.Name);
            searchPage.Details.CaseCategory.EnterAndSelect(summaryData.Case.Category.Name);
            searchPage.Details.PropertyType.EnterAndSelect(summaryData.Case.PropertyType.Name);

            searchPage.Text.NavigateTo();
            var caseText = summaryData.Case.CaseTexts.First();
            searchPage.Text.TextType.Input.SelectByText(caseText.TextType.TextDescription);
            searchPage.Text.TextTypeValue.Input.SendKeys(caseText.Text.Substring(0, 6));
            searchPage.Text.TitleMark.Input.SendKeys(summaryData.Case.Title.Substring(0, 3));

            var instructor = summaryData.Case.CaseNames.First(_ => _.NameTypeId == "I");
            var owner = summaryData.Case.CaseNames.First(_ => _.NameTypeId == "O");
            var debtor = summaryData.Case.CaseNames.First(_ => _.NameTypeId == "D");
            searchPage.Names.NavigateTo();
            searchPage.Names.Instructor.EnterAndSelect(instructor.Name.NameCode);
            searchPage.Names.Owner.EnterAndSelect(owner.Name.NameCode);
            searchPage.Names.NameType.Input.SelectByText(debtor.NameType.Name);
            searchPage.Names.OtherName.EnterAndSelect(debtor.Name.NameCode);

            searchPage.Status.NavigateTo();
            searchPage.Status.Dead.Click();
            searchPage.Status.CaseStatus.EnterAndSelect(isExternal ? summaryData.Case.CaseStatus.ExternalName : summaryData.Case.CaseStatus.Name);
            searchPage.Status.RenewalStatus.EnterAndSelect(isExternal ? summaryData.Case.CaseStatus.ExternalName : summaryData.Case.CaseStatus.Name);
            //Assert.True(searchPage.Status.RenewalStatus.HasError, "Renewal status filtered by renewal statuses");
            searchPage.Status.RenewalStatus.EnterAndSelect(isExternal ? summaryData.Case.Property.RenewalStatus.ExternalName : summaryData.Case.Property.RenewalStatus.Name);
            //Assert.False(searchPage.Status.RenewalStatus.HasError, "Renewal status filtered by renewal statuses");
            searchPage.Status.RenewlStatusOperator.Input.SelectByText("Exists");

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=" + (isExternal ? 1 : 2), driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");

            Assert.AreEqual(summaryData.Case.Irn, grid.Cell(0, isExternal ? 3 : 2).Text, "Correct record is returned");

            searchResultPageObject.CloseButton().WithJs().Click();
            Assert.AreEqual("/case/search", driver.Location, "Should navigate back to case search page");

            //var caseReferenceInputText = searchPage.References.CaseReference.WithJs().GetValue();
            //Assert.AreEqual(summaryData.Case.Irn, caseReferenceInputText, "View state of case search page should still retained");
        }
    }
}