using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RecordTime : TimeRecordingFromOtherApps
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void RecordTimeFromCaseView(BrowserType browserType)
        {
            
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{DbData.Case.Id}", DbData.User.Username, DbData.User.Password);

            var page = new NewCaseViewDetail(driver);
            page.GoToActionsTab();
            
            page.RecordTime();

            CheckRecordTime(driver, browserType, DbData.Case.Irn, true);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void RecordAsTimerFromCaseView(BrowserType browserType)
        {
             
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{DbData.Case.Id}", DbData.User.Username, DbData.User.Password);

            var page = new NewCaseViewDetail(driver);
            page.GoToActionsTab();
            
            page.RecordWithTimer();

            CheckRecordTimeWithTimer(driver, browserType, DbData.Case.Irn, true);
        }
    }
}