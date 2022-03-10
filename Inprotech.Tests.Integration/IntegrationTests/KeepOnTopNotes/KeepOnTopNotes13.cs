using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.IntegrationTests.KeepOnTopNotes
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release13)]
    public class KeepOnTopNotes13 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void KeepOnTopNotesCase(BrowserType browserType)
        {
            if (!VersionMatched()) return;
            var setup = new CaseDetailsDbSetup();
            var casesData = setup.NavigationDataSetup();
            var @case = (Case) casesData.Case1;
            var data = setup.SetupKeepOnTopNotesFor13(@case);
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().Create();

            SignIn(driver, $"/#/caseview/{@case.Id}", user.Username, user.Password);

            var btnNotes = driver.FindElement(By.XPath("//button[@id='btnKot']"));
            var kotItem = driver.FindElement(By.CssSelector(".kot-block"));
            var kotItemHeader = driver.FindElement(By.CssSelector(".text-black-bold"));
            var textType = ((CaseText) data.caseText1).TextType.TextDescription;

            Assert.IsTrue(btnNotes.Enabled);
            Assert.IsTrue(kotItem.Displayed);
            Assert.AreEqual(textType, kotItemHeader.Text);
        }

        public static bool VersionMatched()
        {
            var shouldExecute = DbSetup.Do(x =>
            {
                var dbReleaseVersion = x.DbContext.Set<SiteControl>()
                                        .Single(_ => _.ControlId == SiteControls.DBReleaseVersion)
                                        .StringValue;
                return dbReleaseVersion.Contains("13") || dbReleaseVersion.Contains("14") || dbReleaseVersion.Contains("15");
            });

            return shouldExecute;
        }

    }
}
