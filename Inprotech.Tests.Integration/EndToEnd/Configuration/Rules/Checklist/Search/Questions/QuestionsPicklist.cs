using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium.Support.UI;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Search.Questions
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class QuestionsPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainQuestion(BrowserType browserType)
        {
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainQuestion)
                       .WithPermission(ApplicationTask.MaintainRules)
                       .WithPermission(ApplicationTask.MaintainCpassRules)
                       .Create();

            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration", user.Username, user.Password);
            var searchOptions = new ChecklistSearchOptions(driver);
            searchOptions.QuestionSearchOption.Click();
            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-question");

            Assert.True(page.Question.Displayed, "Ensure that the question picklist is displayed after clicking question search radio button");
            page.Question.OpenPickList();
            var questionsPicklist = new QuestionPicklistObject(driver);
            questionsPicklist.AddQuestionButton.Click();
            var newCode = Fixture.AlphaNumericString(10);
            var newQuestion = Fixture.AlphaNumericString(100);
            var newInstructions = Fixture.AlphaNumericString(100);
            questionsPicklist.CodeField.Input.SendKeys(newCode);
            questionsPicklist.QuestionField.Input.Clear();
            questionsPicklist.QuestionField.Input.SendKeys(newQuestion);
            questionsPicklist.InstructionsField.Input.SendKeys(newInstructions);
            questionsPicklist.SaveButton.ClickWithTimeout();
            questionsPicklist.CloseButton.ClickWithTimeout();
            page.Question.EnterAndSelect(newCode);
            page.Question.OpenPickList();
            var list = questionsPicklist.ResultGrid;

            Assert.AreEqual(newCode, list.CellText(0, list.FindColByText("Code")), "Expected new code to be saved");
            Assert.AreEqual(newQuestion, list.CellText(0, list.FindColByText("Question")), "Expected new question to be saved");
            Assert.AreEqual(newInstructions, list.CellText(0, list.FindColByText("Instructions")), "Expected new instructions to be saved");
            
            questionsPicklist.SearchField.Clear();
            questionsPicklist.SearchField.SendKeys(data.Question.QuestionString);
            questionsPicklist.SearchButton.ClickWithTimeout();
            list = questionsPicklist.ResultGrid;
            list.EditButton(1).Click();

            Assert.AreEqual(data.Question.QuestionString, questionsPicklist.QuestionField.Text, "Expected correct question to be displayed");
            var modifiedCode = Fixture.AlphaNumericString(10);
            var modifiedQuestion = Fixture.AlphaNumericString(100);
            var modifiedInstructions = Fixture.AlphaNumericString(100);
            questionsPicklist.CodeField.Input.SendKeys(modifiedCode);
            questionsPicklist.QuestionField.Input.Clear();
            questionsPicklist.QuestionField.Input.SendKeys(modifiedQuestion);
            questionsPicklist.InstructionsField.Input.Clear();
            questionsPicklist.InstructionsField.Input.SendKeys(modifiedInstructions);
            questionsPicklist.SaveButton.ClickWithTimeout();
            questionsPicklist.CloseButton.ClickWithTimeout();
            list = questionsPicklist.ResultGrid;
            questionsPicklist.SearchField.Clear();
            questionsPicklist.SearchField.SendKeys(modifiedCode);
            questionsPicklist.SearchButton.ClickWithTimeout();

            Assert.AreEqual(modifiedCode, list.CellText(0, list.FindColByText("Code")), "Expected code to be saved");
            Assert.AreEqual(modifiedQuestion, list.CellText(0, list.FindColByText("Question")), "Expected question to be saved");
            Assert.AreEqual(modifiedInstructions, list.CellText(0, list.FindColByText("Instructions")), "Expected instructions to be saved");

            questionsPicklist.SearchField.Clear();
            questionsPicklist.SearchField.SendKeys(data.DeleteQuestion.QuestionString);
            questionsPicklist.SearchButton.ClickWithTimeout();
            questionsPicklist.ResultGrid.ClickDelete(0);
            var popup = new CommonPopups(driver);
            popup.ConfirmNgDeleteModal.Delete.Click();

            Assert.AreEqual(0, questionsPicklist.ResultGrid.Rows.Count, "Ensure question is deleted");
        }
    }
}
