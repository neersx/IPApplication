using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public class CaseView14 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewReadOnlyTopics(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadyOnlyDataSetupAfter14();
            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.MaintainCase, Allow.Select)
                                  .Create();

            SignIn(driver, $"/#/caseview/{data.Trademark.Case.Id}", user.Username, user.Password);

            TestPendingTrademarkCaseClasses(driver);
        }

        static void TestPendingTrademarkCaseClasses(NgWebDriver driver)
        {
            var caseClassTopic = new CaseClassTopic(driver);
            Assert.True(caseClassTopic.CaseViewClassesGrid.Grid.Displayed, "Classes Section is showing");
            Assert.AreEqual(5, caseClassTopic.CaseViewClassesGrid.Rows.Count, "Classes Section: should show 1 row");
            Assert.AreEqual(caseClassTopic.CaseViewClassesGrid.CellText(0, 1), "L1", "Class Name for which G&S text is displayed");
            Assert.True(caseClassTopic.CaseClassesExpandIcon(driver).Displayed, "Icon should be expanded by default");
            Assert.AreEqual(caseClassTopic.ClassDetailsCellValue(driver, 1, 2), "English", "The value of the first G&S text should be english");
            Assert.AreEqual(caseClassTopic.ClassDetailsCellValue(driver, 2, 2), "German", "The value of the first G&S text should be German");
        }
    }
}
