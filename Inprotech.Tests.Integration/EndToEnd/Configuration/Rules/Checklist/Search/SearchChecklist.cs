using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Search
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaChecklistSearch : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        public void SearchByCharacteristics(BrowserType browserType)
        {
            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration");

            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-characteristics");
            page.CaseTypePl.SendKeys(data.CaseType.Name);
            page.CaseTypePl.Typeahead.SendKeys(Keys.Tab);
            
            page.JurisdictionPl.Clear();
            page.SubmitButton.Click();
            Assert.AreEqual(2, page.Grid.Rows.Count, "Expected all records with selected case type returned when exact match chosen");

            page.JurisdictionPl.SendKeys(data.Jurisdiction.Name);
            page.JurisdictionPl.Typeahead.SendKeys(Keys.Tab);
            
            page.ChecklistPl.Clear();
            page.PropertyTypePl.Clear();
            page.SubmitButton.Click();
            Assert.AreEqual(1, page.Grid.Rows.Count, "Expected only one record matching case type and jurisdiction returned when exact match chosen");

            page.PropertyTypePl.SendKeys(data.ValidPropertyType);
            page.PropertyTypePl.Typeahead.SendKeys(Keys.Tab);
            page.ChecklistPl.OpenPickList();
            
            Assert.AreEqual(1, page.ChecklistPl.SearchGrid.Rows.Count, "The valid checklist shows the correct count.");
            Assert.AreEqual(data.ValidChecklist, page.ChecklistPl.SearchGrid.Cell(0, 0).Text, "The valid checklist shows the correct count.");

            page.ChecklistPl.Close();
            page.ChecklistPl.EnterAndSelect(data.ValidChecklist);
            page.BestMatchOption.Click();
            page.SubmitButton.Click();

            Assert.True(page.Grid.Grid.Displayed, "Ensure that the grid is displayed after searching");
            Assert.AreEqual(2, page.Grid.Rows.Count, "Expected the Best Matches option to display all matching criteria");

            page.BestCriteriaOption.Click();
            page.SubmitButton.Click();
            Assert.AreEqual(1, page.Grid.Rows.Count, "Expected the Best Criteria option to display only top matching criteria");

            page.ExactMatchOption.Click();
            page.SubmitButton.Click();
            Assert.AreEqual(0, page.Grid.Rows.Count, "Expected no results when exact match chosen with refined filter");
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchByCase(BrowserType browserType)
        {
            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration");

            var searchOptions = new ChecklistSearchOptions(driver);
            searchOptions.CaseSearchOption.Click();
            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-case");
            
            Assert.True(page.CasePl.Displayed, "Ensure that the case picklist is displayed after clicking case search radio button");
            Assert.False(page.SubmitButton.Enabled, "Ensure you cannot submit search until case is entered");

            page.CasePl.SendKeys(data.Case.Irn);
            page.CasePl.SendKeys(Keys.Tab);

            Assert.True(page.SubmitButton.Enabled, "Ensure you submit button is enable now that case is entered");
            Assert.AreEqual(data.Case.Type.Name, page.CaseTypePl.GetText(), "Ensure that the case type is defaulted");
            Assert.AreEqual(data.Case.Country.Name, page.JurisdictionPl.GetText(), "Ensure that the jurisdiction is defaulted");
            Assert.AreEqual(data.ValidPropertyType, page.PropertyTypePl.GetText(), "Ensure that the property type is defaulted");

            page.SubmitButton.Click();

            Assert.AreEqual(0, page.Grid.Rows.Count, "Ensure search result is correct");
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchByCriteria(BrowserType browserType)
        {
            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration");
            var searchOptions = new ChecklistSearchOptions(driver);
            searchOptions.CriteriaSearchOption.Click();
            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-criteria");
            
            Assert.True(page.Criteria.Displayed, "Ensure that the criteria picklist is displayed after clicking criteria search radio button");
            Assert.True(page.SubmitButton.Enabled, "Ensure you can submit search for blank criteria");

            page.SubmitButton.Click();

            Assert.True(page.Grid.Rows.Count > 0, "Ensure all results are returned");

            page.Criteria.SendKeys(data.Criteria1.Id.ToString());
            page.Criteria.SendKeys(Keys.Tab);
            page.SubmitButton.Click();

            Assert.AreEqual(1, page.Grid.Rows.Count, "Ensure search result count is correct");
            Assert.AreEqual(data.Criteria1.Description, page.Grid.CellText(0, 3), "Ensure search result details are correct");

            page.Criteria.SendKeys(data.Criteria1.Id.ToString());
            page.Criteria.SendKeys(Keys.Tab);
            page.Criteria.SendKeys(data.Criteria2.Id.ToString());
            page.Criteria.SendKeys(Keys.Tab);
            page.SubmitButton.Click();

            Assert.AreEqual(2, page.Grid.Rows.Count, "Ensure search result count is correct");
            Assert.AreEqual(data.Criteria1.Description, page.Grid.CellText(0, 3), "Ensure search result details are correct");
            Assert.AreEqual(data.Criteria2.Description, page.Grid.CellText(1, 3), "Ensure search result details are correct");
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchByQuestion(BrowserType browserType)
        {
            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration");
            var searchOptions = new ChecklistSearchOptions(driver);
            searchOptions.QuestionSearchOption.Click();
            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-question");

            Assert.True(page.Question.Displayed, "Ensure that the question picklist is displayed after clicking question search radio button");
            Assert.False(page.SubmitButton.Enabled, "Ensure you cannot search for blank question");

            page.Question.SendKeys(data.Question.QuestionString);
            page.Question.SendKeys(Keys.Tab);
            page.SubmitButton.Click();

            Assert.AreEqual(1, page.Grid.Rows.Count, "Ensure search result count is correct");
            Assert.AreEqual(data.Criteria1.Description, page.Grid.CellText(0, 3), "Ensure search result details are correct");
        }
    }
}
