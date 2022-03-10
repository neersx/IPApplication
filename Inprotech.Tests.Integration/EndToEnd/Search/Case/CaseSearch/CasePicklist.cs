using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    public class CasePicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CheckCasePickList(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            InprotechKaizen.Model.Cases.Case case1 = null, case2 = null, case3 = null;
            TableCode officeTableCode = null;
            DbSetup.Do(x =>
            {
                case1 = new CaseBuilder(x.DbContext).Create("e2e");
                case2 = new CaseBuilder(x.DbContext).Create("e2e1");
                case3 = new CaseBuilder(x.DbContext).Create("e2e3");

                officeTableCode = x.InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.Office, Name = Fixture.String(5) });
                var office = x.InsertWithNewId(new Office(officeTableCode.Id, officeTableCode.Name));
                case1.Office = office;
                case3.Office = office;
                x.DbContext.SaveChanges();
            });
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.Names.IncludeThisCase.OpenPickList();

            var pickListModel = new CasePicklistModelObject(driver);
            driver.WaitForAngular();
            var grid = pickListModel.ResultGrid;
            driver.WaitForAngular();
            
            Assert.AreEqual(0,grid.Rows.Count);
            Assert.NotNull(pickListModel.InlineAlert);
            Assert.AreEqual("Perform a search to return results.", pickListModel.InlineAlert.Text);

            pickListModel.SearchElement.SendKeys(case3.Irn);
            pickListModel.SearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            pickListModel.SearchButton.ClickWithTimeout();
            grid = pickListModel.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count);

            pickListModel.ClearButton.ClickWithTimeout();
            driver.WaitForAngular();
            pickListModel.NameTypeahead.EnterAndSelect("Asterisk");
            pickListModel.CaseTypeahead.Typeahead.WithJs().Focus();
            pickListModel.CaseTypeahead.Typeahead.SendKeys("A");
            pickListModel.JurisdictionTypeahead.Typeahead.WithJs().Focus();
            pickListModel.JurisdictionTypeahead.Typeahead.SendKeys("AU");
            pickListModel.ClearSearchButton.ClickWithTimeout();
            pickListModel.ClearSearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.True(string.IsNullOrWhiteSpace(pickListModel.NameTypeahead.GetText()));
            Assert.True(string.IsNullOrWhiteSpace(pickListModel.CaseTypeahead.GetText()));
            Assert.True(string.IsNullOrWhiteSpace(pickListModel.JurisdictionTypeahead.GetText()));

            pickListModel.CaseOfficeTypeahead.EnterAndSelect(officeTableCode.Name);
            pickListModel.SavedSearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(2, grid.Rows.Count);
        }
    }
}
