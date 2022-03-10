using System.IO;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.TwoFactorPreference;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ResetPassword
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SendEmail : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SendEmailModal(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            driver.WrappedDriver.Url = Env.RootUrl + "/signin";
            var internalUser = new Users().Create();
            string name = null;
            var email = new DocItemHelper().GetDocItemAfterRun(KnownEmailDocItems.PasswordReset, 30, internalUser.Id).ScalarValueOrDefault<string>();
            DbSetup.Do(x =>
            {
                var user = x.DbContext.Set<User>().First(_ => _.Id == internalUser.Id);
                name = user.Name.FirstName;
            });
            var currentFileSet = Directory.GetFiles(Runtime.MailPickupLocation, "*.eml");
            var modal = new SendEmailPageObject(driver);
            modal.ForgotPasswordElement.Click();
            Assert.AreEqual("FORGOTTEN YOUR PASSWORD", modal.Title.Text);

            modal.CancelButton();
            Assert.AreEqual("Forgotten your password?", modal.ForgotPasswordElement.Text);

            modal.ForgotPasswordElement.Click();
            modal.SendEmailButton.Click();
            Assert.IsTrue(modal.ErrorMessageDiv.Displayed);
            Assert.AreEqual("Login ID is required.", modal.ErrorMessageDiv.Text);

            modal.LoginId.SendKeys(internalUser.Username);
            modal.SendEmailButton.Click();
            driver.WaitForAngular();
            Assert.IsTrue(modal.ForgotPasswordElement.Displayed);
            var message = new SimplePlainTextEmlParser()
                .Parse(Directory.EnumerateFiles(Runtime.MailPickupLocation).Except(currentFileSet).FirstOrDefault());

            Assert.IsTrue(message.Body.Contains(name));
            Assert.IsTrue(message.Body.Contains(email));
        }
    }
}