using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EntryDocuments : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EntryDocumentsAll(BrowserType browserType)
        {
            string documentName, documentName2;
            Criteria criteria;
            using (var setup = new EntryControlDbSetup())
            {
                var criteriaDescription = Fixture.Prefix("criteria");
                var entryDescription = Fixture.Prefix("entry");
                documentName = Fixture.Prefix("document");
                documentName2 = Fixture.Prefix("document2");
                criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = criteriaDescription,
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                    UserDefinedRule = 0,
                    RuleInUse = 1,
                    LocalClientFlag = 1
                });

                var entry = setup.Insert(new DataEntryTask
                {
                    CriteriaId = criteria.Id,
                    Description = entryDescription,
                    ShouldPoliceImmediate = false
                });

                var document = setup.InsertWithNewId(new Document
                {
                    Name = documentName,
                    DocumentType = 1
                });

                setup.Insert(new DocumentRequirement(criteria, entry, document) {Inherited = 1});

                var document2 = setup.InsertWithNewId(new Document
                {
                    Name = documentName2,
                    DocumentType = 1
                });

                setup.Insert(new DocumentRequirement(criteria, entry, document2) {Inherited = 1});
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, criteria.Id.ToString());

            var entryControlPage = new EntryControlPage(driver);
            entryControlPage.Documents.NavigateTo();
            ReloadPage(driver);
            entryControlPage.Documents.NavigateTo();

            Assert.AreEqual(2, entryControlPage.Documents.GridRowsCount, "Initially 2 rows inserted");
            entryControlPage.Documents.Add();

            Assert.AreEqual(3, entryControlPage.Documents.GridRowsCount, "New blank row added at the end");
            entryControlPage.Documents.Grid.ToggleDelete(2);
            Assert.AreEqual(2, entryControlPage.Documents.GridRowsCount, "The unsaved row should be removed from the grid");

            entryControlPage.Documents.Grid.ToggleDelete(1);
            Assert.AreEqual(2, entryControlPage.Documents.GridRowsCount, "The delete row should be marked deleted now");

            entryControlPage.SaveButton.ClickWithTimeout();

            entryControlPage.Documents.NavigateTo();
            Assert.AreEqual(1, entryControlPage.Documents.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert.AreEqual(documentName, entryControlPage.Documents.GetDataForRow(0).DocumentName, "the non deleted row should still stay in the grid");

            entryControlPage.Documents.Add();
            entryControlPage.Documents.DocumentPicklist(1).EnterAndSelect(documentName2);

            entryControlPage.Documents.ClickMustProduce(0);

            entryControlPage.SaveButton.ClickWithTimeout();
            Assert.AreEqual(2, entryControlPage.Documents.GridRowsCount, "New row added");
            Assert.AreEqual(2, entryControlPage.Documents.NumberOfRecords(), "Topic displays the count");

            Assert.True(entryControlPage.Documents.GetDataForRow(0).IsMandatory, "Row updated and now has Must Produce selected");
        }

        void GotoEntryControlPage(NgWebDriver driver, string criteriaId)
        {
            SignIn(driver, "/#/configuration/rules/workflows");

            driver.FindRadio("search-by-criteria").Label.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            pl.EnterAndSelect(criteriaId);

            searchOptions.SearchButton.ClickWithTimeout();

            driver.WaitForAngular();

            Assert2.WaitTrue(3, 500, () => searchResults.LockedRows.Count > 0, "Search should return some results");

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var workflowDetailsPage = new CriteriaDetailPage(driver);

            workflowDetailsPage.EntriesTopic.NavigateToDetailByRowIndex(0);
        }
    }
}