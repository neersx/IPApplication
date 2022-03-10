using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release16)]
    public class CaseView16 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void KeepOnTopNotesCaseFor16(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var casesData = setup.NavigationDataSetup();
            var @case = (Case) casesData.Case1;
            var data = setup.SetupKeepOnTopNotesFor16(@case);
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().Create();
            var kot = (KeepOnTopTextType) data.kot1;

            SignIn(driver, $"/#/caseview/{@case.Id}", user.Username, user.Password);

            var btnNotes = driver.FindElement(By.XPath("//button[@id='btnKot']"));
            var kotItem = driver.FindElement(By.CssSelector(".kot-block"));
            var colorBlock = driver.FindElement(By.CssSelector(".kot-block")).GetCssValue("background-color");
            Assert.AreEqual(colorBlock.Contains("rgba") ? data.IeColor : data.OtherBrowserColor, colorBlock);
            var kotCaseRefHeader = driver.FindElement(By.Id("caseRef"));
            var kotTextTypeHeader = driver.FindElement(By.Id("textType"));
            Assert.IsTrue(btnNotes.Enabled);
            Assert.IsTrue(kotItem.Displayed);
            Assert.AreEqual(@case.Irn, kotCaseRefHeader.Text);
            Assert.AreEqual(kot.TextType.TextDescription, kotTextTypeHeader.Text);
        }
    }
}