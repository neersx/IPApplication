using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SQLTextAreaComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectHeading(BrowserType browserType)
        {
            const string title = "SQL Text Area Examples";
            var page = NavigateToPage(browserType);
            Assert.AreEqual(title, page.Title);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void InputtingNormalTextWorks(BrowserType browserType)
        {
            var page = NavigateToPage(browserType);
            var inputValue = "HI";

            page.TextArea.Input.SendKeys(inputValue);
            Assert.AreEqual(inputValue, page.Value);
            Assert.AreEqual(inputValue, page.TextArea.Input.Value());
            page.TextArea.Input.Clear();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void InputtingTextWithNewLinesWorks(BrowserType browserType)
        {
            var page = NavigateToPage(browserType);

            page.TextArea.Input.SendKeys($"SELECT");
            page.TextArea.Input.SendKeys(Keys.Enter);
            page.TextArea.Input.SendKeys("FROM TableOne");
            Assert.AreEqual($"SELECT\r\nFROM TableOne", page.Value);
            Assert.AreEqual($"SELECT\r\nFROM TableOne", page.TextArea.Input.Value());
        }

        private SQLTextAreaPage NavigateToPage(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/sqlTextArea");

            var page = new SQLTextAreaPage(driver);
            return page;
        }
    }

    internal class SQLTextAreaPage : PageObject
    {
        public SQLTextAreaPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public TextArea TextArea => new TextArea(Driver, "nonSQLTextArea");

        public string Title => Driver.FindElement(By.TagName("h2")).Text;

        public string Value => Driver.FindElement(By.Id("valueLabel")).WithJs().GetInnerText();

        public void ClickEvaluate()
        {
            Driver.FindElement(By.Id("evaluateButton")).Click();
        }
    }
}