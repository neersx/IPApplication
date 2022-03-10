using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class UserInfo : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void UserInformation(BrowserType browserType)
        {
            var internalUser = new Users().Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var slider = new PageObjects.QuickLinks(driver);

            slider.Open("userinfo");

            var userInfoSlideOut = new UserInfoPageObject(driver);

            Assert.IsTrue(userInfoSlideOut.UserInformation.Displayed);
            slider.Close();
        }
    }

    public class UserInfoPageObject : PageObject
    {
        public UserInfoPageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("help"));
        }

        public NgWebElement UserInformation => FindElement(By.Id("user-info-and-two-factor"));

        public NgWebElement ChangePasswordButton => FindElement(By.Id("changePassword"));
    }
}