using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch.ClientAccess
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(14)]
    public class ExternalCaseSearch : IntegrationTest
    {
        [SetUp]
        public void PrepareData()
        {
            /* Please do not do this.  You should set up specific test data for your specific test */

            _summaryData = DbSetup.Do(setup =>
            {
                var irnPrefix = Fixture.UriSafeString(5);
                var caseBuilder = new CaseSearchCaseBuilder(setup.DbContext);
                var data = caseBuilder.Build(irnPrefix, true);

                var textType = setup.InsertWithNewId(new TextType(Fixture.String(5)));
                var clientTextType = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientTextTypes);

                _currentTextTypeValue = clientTextType.StringValue;

                clientTextType.StringValue = clientTextType.StringValue + "," + textType.Id;

                data.Case.CaseTexts.Add(new CaseText(data.Case.Id, textType.Id, 0, null) {Text = Fixture.String(10), TextType = textType});

                setup.DbContext.SaveChanges();

                return data;
            });
        }

        [TearDown]
        public void CleanupModifiedData()
        {
            DbSetup.Do(x =>
            {
                var clientTextType = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientTextTypes);

                clientTextType.StringValue = _currentTextTypeValue;

                x.DbContext.SaveChanges();
            });
        }

        string _currentTextTypeValue;

        CaseSearchCaseBuilder.SummaryData _summaryData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchResult(BrowserType browserType)
        {
            var shouldExecute = DbSetup.Do(x =>
            {
                var dbReleaseVersion = x.DbContext.Set<SiteControl>()
                                        .Single(_ => _.ControlId == SiteControls.DBReleaseVersion)
                                        .StringValue;
                return dbReleaseVersion.Contains("14") || dbReleaseVersion.Contains("15") || dbReleaseVersion.Contains("16");
            });

            if (!shouldExecute) return;

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#", _summaryData.User.Username, _summaryData.User.Password);

            CaseSearchHelper.TestCaseSearchResults(_summaryData, driver, true);
        }
    }
}