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
    public class DatePickerComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDates(BrowserType browserType)
        {
            const string title = "Datepicker Test Page";
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/datepicker");

            var page = new DatePickerPage(driver);
            Assert.AreEqual(title, page.Title);

            //AEST - DST Start day
            page.DatePicker.Input.SendKeys("02-Oct-2016");
            page.ClickEvaluate();
            Assert.AreEqual($"\"2016-10-02T00:00:00.000Z\"", page.Value, "Ensures DST start date evaluated correctly - 02Oct2016 in AEST");

            //Some other day
            page.DatePicker.Input.Clear();
            page.DatePicker.Input.SendKeys("01-Jan-2017");
            page.ClickEvaluate();
            Assert.AreEqual($"\"2017-01-01T00:00:00.000Z\"", page.Value, "Ensure date is evaluated correctly");

            //Some other day
            page.DatePicker.Input.Clear();
            page.DatePicker.Input.SendKeys("31-Dec-2017");
            page.ClickEvaluate();
            Assert.AreEqual($"\"2017-12-31T00:00:00.000Z\"", page.Value, "Ensure date is evaluated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlyPopulatesAndRepopulates(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/datepicker");

            var page = new DatePickerPage(driver);

            // Simulate populating from date string
            Assert.AreEqual("18-May-2017", page.ExistingDatePicker.Input.WithJs().GetValue(), "Ensure existing data is populated correctly");
            Assert.AreEqual("\"2017-05-18T00:00:00.000Z\"", page.ExistingDateValue);
            Assert.IsEmpty(page.RepopulateDatePicker.Input.WithJs().GetValue());
            Assert.IsEmpty(page.RepopulateDateValue);
            
            // Simulate repopulating from date object
            page.ExistingDatePicker.Enter("2017-12-31", true);
            page.RepopulateDatePicker.Input.Click(); // click to lose focus - tab wasn't working in IE.
            Assert.AreEqual("31-Dec-2017", page.RepopulateDatePicker.Input.WithJs().GetValue(), "Ensure date can be re-loaded correctly from an existing date object");
            Assert.AreEqual("\"2017-12-31T00:00:00.000Z\"", page.RepopulateDateValue, "Ensure date is re-loaded correctly from an existing date object");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MonthsAreAcceptedIgnoringCase(BrowserType browserType)
        {
            var user = new Users().Create();

            using (var setup = new DbSetup())
            {
                var preferredCultureSetting = setup.Insert(new SettingValues {SettingId = KnownSettingIds.PreferredCulture, CharacterValue = "en-US"});

                var userIdentity = setup.DbContext.Set<User>().Single(_ => _.UserName == user.Username);

                preferredCultureSetting.User = userIdentity;
            }

            const string title = "Datepicker Test Page";
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/datepicker");

            var page = new DatePickerPage(driver);
            Assert.AreEqual(title, page.Title);

            //October as okt. in small case
            const string date1 = "2-oct-2016";
            page.DatePicker.Input.SendKeys(date1);
            driver.WaitForAngularWithTimeout();
            page.ClickEvaluate();
            Assert.AreEqual($"\"2016-10-02T00:00:00.000Z\"", page.Value, $"Ensures small case month correctly recognized for en-US - {date1}");

            //Some other day
            page.DatePicker.Input.Clear();
            const string date2 = "29/MAR/2017";
            page.DatePicker.Input.SendKeys(date2);
            driver.WaitForAngularWithTimeout();
            page.ClickEvaluate();
            Assert.AreEqual($"\"2017-03-29T00:00:00.000Z\"", page.Value, $"Ensures date for en-US entered is recognized - {date2}");

            //Some other day
            page.DatePicker.Input.Clear();
            const string date3 = "8.may.98";
            page.DatePicker.Input.SendKeys(date3);
            driver.WaitForAngularWithTimeout();
            page.ClickEvaluate();
            Assert.AreEqual($"\"1998-05-08T00:00:00.000Z\"", page.Value, $"Ensures date for en-US entered is recognized - {date3}");
        }
    }

    internal class DatePickerPage : PageObject
    {
        public DatePickerPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public DatePicker DatePicker => new DatePicker(Driver, "testDate");

        public string Title => Driver.FindElement(By.TagName("h2")).Text;

        public string Value => Driver.FindElement(By.Id("valueLabel")).WithJs().GetInnerText();

        public DatePicker ExistingDatePicker => new DatePicker(Driver, "existingDate");
        public string ExistingDateValue => Driver.FindElement(By.Id("existingDateLabel")).WithJs().GetInnerText();

        public DatePicker RepopulateDatePicker => new DatePicker(Driver, "repopulateDate");
        public string RepopulateDateValue => Driver.FindElement(By.Id("repopulateDateLabel")).WithJs().GetInnerText();

        public void ClickEvaluate()
        {
            Driver.FindElement(By.Id("evaluateButton")).Click();
        }
    }
}