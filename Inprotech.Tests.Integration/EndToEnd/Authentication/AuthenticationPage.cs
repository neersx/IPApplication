using System;
using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Authentication
{
    public class AuthenticationPage : PageObject
    {
        readonly NgWebDriver _driver;

        public readonly FormsAuthentication FormsAuthentication;

        public AuthenticationPage(NgWebDriver driver) : base(driver)
        {
            _driver = driver;

            FormsAuthentication = new FormsAuthentication(driver);
        }

        public void SignInWithWindows()
        {
            var button = new ButtonInput(_driver).ByName("windowsSignIn");
            button?.Element.WithJs().Click();
        }

        public void SignInWithTheIpPlatform()
        {
            ClickButtonwithJs(By.Name("ssoSignIn"));
        }

        public void SignInWithTheAdfs()
        {
            ClickButtonwithJs(By.Name("adfsSignIn"));
        }

        public void ClickButtonwithJs(By button)
        {
            var element = _driver.FindElements(button).SingleOrDefault();
            if (element == null)
            {
                return;
            }

            _driver.WrappedDriver.ExecuteJavaScript<object>("arguments[0].click();", element);
        }

        public void Logout()
        {
            Try.Retry(3, 1000, () =>
            {
                var logoutButton = _driver.FindElement(By.CssSelector("#rightBar #logout .cpa-icon-sign-out"));
                logoutButton.Click();
            });
        }
    }

    public class FormsAuthentication : PageObject
    {
        readonly NgWebDriver _driver;

        public FormsAuthentication(NgWebDriver driver) : base(driver)
        {
            _driver = driver;
        }

        public TextInput UserName => _driver.FindElements(By.Name("username")).Count == 1 ? new TextInput(_driver).ByName("username") :
            _driver.FindElements(By.Name("username1")).Count == 1 ? new TextInput(_driver).ByName("username1") : null;

        public TextInput Password => _driver.FindElements(By.Name("password")).Count == 1 ? new TextInput(_driver).ByName("password") :
            _driver.FindElements(By.Name("password1")).Count == 1 ? new TextInput(_driver).ByName("password1") : null;

        public TextInput Code => new TextInput(_driver).ByName("userCode");

        public void VerifyCode()
        {
            new ButtonInput(_driver).ByName("verifyCode").Element.WithJs().Click();
        }

        public void SignIn()
        {
            var button = _driver.FindElements(By.Name("signIn")).Count == 1 ? new ButtonInput(_driver).ByName("signIn") :
                _driver.FindElements(By.Name("signIn1")).Count == 1 ? new ButtonInput(_driver).ByName("signIn1") : null;

            button?.Element.WithJs().Click();
        }
    }

    public class SsoAuthentication
    {
        readonly IWebDriver _driver;

        public SsoAuthentication(IWebDriver driver)
        {
            _driver = driver;
        }

        By EmailButtonSelector => By.Id("btnLoginCurrent");
        By SigninButtonSelector => By.Id("btnSubmit");
        By EmailSelector => By.Id("inputEmailAddress");
        By PasswordSelector => By.Id("password");
        IWebElement EmailAddress => _driver.FindElement(EmailSelector);
        IWebElement Password => _driver.FindElement(PasswordSelector);

        void WaitForTrue(Func<bool> condition, int msTimeout = 60000, int waitTime = 1000)
        {
            new WebDriverWait(new SystemClock(), _driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(waitTime))
                .Until(d => condition().Equals(true));
        }

        void WaitForReadyState()
        {
            WaitForTrue(() => _driver.ExecuteJavaScript<string>(@"return document.readyState") == "complete");
        }

        void WaitForVisible(By locatorKey, int msTimeout = 60000, int waitTime = 1000)
        {
            new WebDriverWait(new SystemClock(), _driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(waitTime))
                .Until(ExpectedConditions.ElementIsVisible(locatorKey));
        }

        void EnterPasswordAndSignIn(string password)
        {
            WaitForVisible(PasswordSelector);
            Password.SendKeys(password);
            Click(SigninButtonSelector);
        }

        void Click(By buttonSelector)
        {
            var button = _driver.FindElement(buttonSelector);
            _driver.ExecuteJavaScript<object>("arguments[0].click();", button);
        }

        bool SendKeysIfVisible(By selector, string content)
        {
            var field = _driver.FindElements(selector).FirstOrDefault();
            if (field == null) return false;
            if (!field.Displayed) return false;

            field.Clear();
            field.SendKeys(content);
            return true;
        }

        public void SignIn(string emailAddress, string password)
        {
            WaitForReadyState();

            if (SendKeysIfVisible(EmailSelector, emailAddress))
            {
                Click(SigninButtonSelector);
            }
            else
            {
                Click(EmailButtonSelector);
            }

            WaitForReadyState();
            SendKeysIfVisible(By.Id("username"), emailAddress);
            EnterPasswordAndSignIn(password);
        }
    }

    public class AdfsAuthentication
    {
        readonly IWebDriver _driver;

        public AdfsAuthentication(IWebDriver driver)
        {
            _driver = driver;
        }

        By SigninButtonSelector => By.Id("submitButton");
        By EmailSelector => By.Id("userNameInput");
        By PasswordSelector => By.Id("passwordInput");
        IWebElement EmailAddress => _driver.FindElement(EmailSelector);
        IWebElement Password => _driver.FindElement(PasswordSelector);

        void WaitForTrue(Func<bool> condition, int msTimeout = 5000, int waitTime = 1000)
        {
            new WebDriverWait(new SystemClock(), _driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(waitTime))
                .Until(d => condition().Equals(true));
        }

        void WaitForReadyState()
        {
            WaitForTrue(() => _driver.ExecuteJavaScript<string>(@"return document.readyState") == "complete");
        }

        public void SignIn(string emailAddress, string password)
        {
            WaitForReadyState();
            EmailAddress.SendKeys(emailAddress);
            Password.SendKeys(password);
            var button = _driver.FindElement(SigninButtonSelector);
            _driver.ExecuteJavaScript<object>("arguments[0].click();", button);
        }
    }
}