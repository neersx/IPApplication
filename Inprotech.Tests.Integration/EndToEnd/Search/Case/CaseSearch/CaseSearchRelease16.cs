using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release16)]
    public class CaseSearchRelease16 : IntegrationTest
    { 

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyCaseSearchColumnOfDataUrlFormatType(BrowserType browserType)
        {
            InprotechKaizen.Model.Cases.Case @case = null;
            var caseId = DbSetup.Do(x =>
            {
                @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", null);
                var dataItemOne = new DataItemBuider(x.DbContext).Create(0, "select 'https://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/' + CONVERT(NVARCHAR(20), CASEID)\r\nfrom CASES C where C.IRN = :gstrEntryPoint", "Display Url", "Display Url");
                var dataItemTwo = new DataItemBuider(x.DbContext).Create(0, "select '[' + 'Case' + ' ' + C.IRN + ' ' + 'Link' + '|' + N'https://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/' + CONVERT(NVARCHAR(20), CASEID) + ']'\r\nfrom CASES C where C.IRN = :gstrEntryPoint", "Display Name", "Display Name");
                
                var userColumnQueryDataItem = x.DbContext.Set<QueryDataItem>().Single(_ => _.ProcedureItemId == "UserColumnUrl" && _.ProcedureName == "csw_ListCase");
                var columnDisplayUrl = new QueryColumn {DataItemId = userColumnQueryDataItem.DataItemId, DocItemId = dataItemOne.Id, ColumnLabel = "Display URL", Description = "Display URL"};
                var columnDisplayName = new QueryColumn {DataItemId = userColumnQueryDataItem.DataItemId, DocItemId = dataItemTwo.Id, ColumnLabel = "Display Name"};
                x.Insert(columnDisplayUrl);
                x.Insert(columnDisplayName);

                var queryContextDisplayUrl = new QueryContextColumn {ColumnId = columnDisplayUrl.ColumnId, ContextId = (int)QueryContext.CaseSearch};
                var queryContextDisplayName = new QueryContextColumn {ColumnId = columnDisplayName.ColumnId, ContextId = (int)QueryContext.CaseSearch};
                x.Insert(queryContextDisplayUrl);
                x.Insert(queryContextDisplayName);

                var searchBuilder = new CaseSearchCaseBuilder(x.DbContext);
                searchBuilder.SetupColumn(columnDisplayUrl.ColumnLabel);
                searchBuilder.SetupColumn(columnDisplayName.ColumnLabel);
                x.DbContext.SaveChanges();
                return @case.Id;
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.References.CaseReference.SendKeys(@case.Irn);
            searchPage.CaseSearchButton.ClickWithTimeout();
            var displayNameValue = driver.FindElement(By.XPath("(//ipx-user-column-url)[2]/a"));
            Assert.AreEqual("https://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/"+ caseId, driver.FindElement(By.XPath("(//ipx-user-column-url)[1]/a")).Text);
            Assert.AreEqual("Case e2e_bu1irn Link", displayNameValue.Text);
            Assert.AreEqual("https://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/"+ caseId, displayNameValue.GetAttribute("href"));
        }
    }
}
