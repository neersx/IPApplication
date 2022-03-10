using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Help : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void HelpInfo(BrowserType browserType)
        {
            var internalUser = new Users().Create();
                
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var slider = new PageObjects.QuickLinks(driver);

            slider.Open("help");

            var helpSlideOut = new HelpPageObject(driver);
            helpSlideOut.ThirdPartySoftwareLicensesLink.WithJs().Click();

            var thirdPartySoftwareLicensePage = new ThirdPartySoftwareLicensesModal(driver);
            
            Assert.True(thirdPartySoftwareLicensePage.OssCollection.Count > 0, "Should have a large number of oss.");

            thirdPartySoftwareLicensePage.Close();
            Assert.IsTrue(helpSlideOut.InprotechHelpLink.Displayed);
            Assert.IsTrue(helpSlideOut.InprotechForumLink.Displayed);
            Assert.IsTrue(helpSlideOut.ContactSupport.Displayed);
            Assert.IsTrue(helpSlideOut.SystemInfo.Displayed);
            Assert.IsTrue(helpSlideOut.ThirdPartySoftwareLicensesLink.Displayed);

            slider.Close();
        }

    }

    public class HelpPageObject : PageObject
    {
        public HelpPageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("help"));
        }
        public NgWebElement ThirdPartySoftwareLicensesLink => FindElement(By.CssSelector("a.third-party-software-licenses"));
        public NgWebElement InprotechHelpLink => FindElement(By.CssSelector("a[translate='help.inprotechHelp']"));

        public NgWebElement InprotechForumLink => FindElement(By.CssSelector("a[translate='help.wiki']"));
        public NgWebElement ContactSupport => FindElement(By.CssSelector("h3[translate='help.contactUs']"));
        public NgWebElement SystemInfo => FindElement(By.CssSelector("h3[translate='help.systemInfo']"));
        
    }

    public class ThirdPartySoftwareLicensesModal : ModalBase
    {
        public ThirdPartySoftwareLicensesModal(NgWebDriver driver) : base(driver, "ThirdPartySoftwareLicenses")
        {
        }
        
        public ReadOnlyCollection<NgWebElement> OssCollection => Driver.FindElements(By.XPath("//app-thirdpartysoftwarelicenses/div[3]/div"));
        
        public void Close()
        {
           Driver.FindElement(By.Name("times")).ClickWithTimeout();
        }
    }
}