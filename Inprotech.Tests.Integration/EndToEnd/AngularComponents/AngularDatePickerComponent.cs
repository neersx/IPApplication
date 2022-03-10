using System;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.AngularComponents
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AngularDatePickerComponent : IntegrationTest
    {
        const string PageUrl = "/#/deve2e/ngdatepicker";

        [TearDown]
        public void CleanUpModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.DateStyle);
        }

        void SetDateStyleSiteControl(int value)
        {
            DbSetup.Do(x =>
            {
                var dateStyleSiteControl = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.DateStyle);
                dateStyleSiteControl.IntegerValue = value;

                x.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDatesForDateStyle1(BrowserType browserType)
        {
            const string title = "Datepicker Test Page";
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, PageUrl);
            var page = new DatePickerE2EPage(driver);

            Assert.AreEqual(title, page.Title);

            page.DatePicker.ManuallyEnterValue("02-oct-2016");
            Assert.AreEqual("02-Oct-2016", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("02-10-2016", page.Value, "Ensures date evaluated correctly");

            page.DatePicker.ManuallyEnterValue("01/1/17");
            Assert.AreEqual("01-Jan-2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("01-01-2017", page.Value, "Ensure date is evaluated correctly");

            page.DatePicker.ManuallyEnterValue("31.12.2017");
            Assert.AreEqual("31-Dec-2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("31-12-2017", page.Value, "Ensure date is evaluated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDatesForDateStyle2(BrowserType browserType)
        {
            SetDateStyleSiteControl(2);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, PageUrl);
            var page = new DatePickerE2EPage(driver);

            page.DatePicker.ManuallyEnterValue("Oct-2-16");
            Assert.AreEqual("Oct-02-2016", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("02-10-2016", page.Value, "Ensures date evaluated correctly");

            page.DatePicker.ManuallyEnterValue("january 1 2017");
            Assert.AreEqual("Jan-01-2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("01-01-2017", page.Value, "Ensure date is evaluated correctly");

            page.DatePicker.ManuallyEnterValue("12,31,2017");
            Assert.AreEqual("Dec-31-2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("31-12-2017", page.Value, "Ensure date is evaluated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDatesForDateStyle3(BrowserType browserType)
        {
            SetDateStyleSiteControl(3);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, PageUrl);
            var page = new DatePickerE2EPage(driver);

            page.DatePicker.ManuallyEnterValue("16-2-oct");
            //This looks like a bug: When in Date Style = 3
            //Assert.AreEqual("2016-Oct-02", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            //Assert.AreEqual("02-10-2016", page.Value, "Ensures date evaluated correctly");

            page.DatePicker.ManuallyEnterValue("2017 january 1");
            Assert.AreEqual("2017-Jan-01", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("01-01-2017", page.Value, "Ensure date is evaluated correctly");

            page.DatePicker.ManuallyEnterValue("2017,12,31");
            Assert.AreEqual("2017-Dec-31", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("31-12-2017", page.Value, "Ensure date is evaluated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDatesForDateStyle0CultureGb(BrowserType browserType)
        {
            SetDateStyleSiteControl(0);
            var user = new Users().Create();
            DbSetup.Do(x =>
            {
                var preferredCultureSetting = x.Insert(new SettingValues {SettingId = KnownSettingIds.PreferredCulture, CharacterValue = "en-GB"});
                var userIdentity = x.DbContext.Set<User>().Single(_ => _.UserName == user.Username);
                preferredCultureSetting.User = userIdentity;
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, PageUrl);

            var page = new DatePickerE2EPage(driver);
            
            page.DatePicker.ManuallyEnterValue("02-oct-2016");
            Assert.AreEqual("02/10/2016", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("02-10-2016", page.Value, "Ensures date evaluated correctly");

            page.DatePicker.ManuallyEnterValue("01/1/17");
            Assert.AreEqual("01/01/2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("01-01-2017", page.Value, "Ensure date is evaluated correctly");

            page.DatePicker.ManuallyEnterValue("31.12.2017");
            Assert.AreEqual("31/12/2017", page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("31-12-2017", page.Value, "Ensure date is evaluated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectlySelectsDatesForDateStyle0CultureUs(BrowserType browserType)
        {
            var dateFormat = CultureInfo.GetCultureInfo("en-US").DateTimeFormat.ShortDatePattern;
            SetDateStyleSiteControl(0);
            var user = new Users().Create();
            DbSetup.Do(x =>
            {
                var preferredCultureSetting = x.Insert(new SettingValues {SettingId = KnownSettingIds.PreferredCulture, CharacterValue = "en-US"});
                var userIdentity = x.DbContext.Set<User>().Single(_ => _.UserName == user.Username);
                preferredCultureSetting.User = userIdentity;
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, PageUrl);
            var page = new DatePickerE2EPage(driver);

            page.DatePicker.ManuallyEnterValue("Oct-2-16");
            Assert.AreEqual(new DateTime(2016, 10, 2).ToString(dateFormat), page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("02-10-2016", page.Value, "Ensures date evaluated correctly");

            page.DatePicker.ManuallyEnterValue("january 1 2017");
            Assert.AreEqual(new DateTime(2017, 1, 1).ToString(dateFormat), page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("01-01-2017", page.Value, "Ensure date is evaluated correctly");

            page.DatePicker.ManuallyEnterValue("12,31,2017");
            Assert.AreEqual(new DateTime(2017, 12, 31).ToString(dateFormat), page.DatePicker.DateInput.Value, "Date picker displays correct value");
            Assert.AreEqual("31-12-2017", page.Value, "Ensure date is evaluated correctly");
        }
    }

    internal class DatePickerE2EPage : PageObject
    {
        public DatePickerE2EPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularDatePicker DatePicker => new AngularDatePicker(Driver).ByName("testDate");

        public string Title => Driver.FindElement(By.TagName("h2")).Text;

        public string Value => Driver.FindElement(By.Id("valueLabel")).WithJs().GetInnerText();

        public void ClickEvaluate()
        {
            Driver.FindElement(By.Id("evaluateButton")).Click();
        }
    }
}