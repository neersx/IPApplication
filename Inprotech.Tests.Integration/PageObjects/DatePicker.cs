using System;
using System.Globalization;
using System.Linq;
using System.Web;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class DatePicker : PageObject
    {
        readonly NgWebDriver _driver;
        readonly string _id;
        readonly NgWebElement _container;

        public DatePicker(NgWebDriver driver, string id, NgWebElement container = null) : base(driver)
        {
            _id = id;
            _container = container;
            _driver = driver;
        }

        public NgWebElement Input =>
            _container != null
                ? _container.FindElement(By.Id(_id))
                            .FindElement(By.CssSelector("input.datepicker-input"))
                : _driver.FindElement(By.Id(_id))
                         .FindElement(By.CssSelector("input.datepicker-input"));

        public string Value => Input.Value();

        public NgWebElement WarningIcon => _container.FindElement(By.ClassName("cpa-icon-exclamation-circle"));
        public NgWebElement ErrorIcon => _container.FindElement(By.ClassName("cpa-icon-exclamation-triangle"));

        public void Enter(string dateString, bool clearBeforeEntry = false)
        {
            DateTime dt;
            if (!DateTime.TryParseExact(dateString, "yyyy-MM-dd", CultureInfo.CurrentCulture, DateTimeStyles.None, out dt))
                throw new ArgumentException("dateString must be in yyyy-MM-dd format");

            Enter(dt, clearBeforeEntry);
        }

        public void Enter(DateTime date, bool clearBeforeEntry = false)
        {
            if (clearBeforeEntry)
                Input.Clear();

            Input.SendKeys(date.ToString("yyyy-MM-dd"));
        }

        public void Open()
        {
            var icon = _container != null
                ? _container.FindElement(By.Id(_id))
                            .FindElement(By.CssSelector("button .cpa-icon-calendar"))
                : _driver.FindElement(By.Id(_id))
                         .FindElement(By.CssSelector("button .cpa-icon-calendar"));

            icon.WithJs().Click();
        }

        public void PreviousMonth()
        {
            var previous = _driver.FindElement(By.CssSelector("div.bs-datepicker-container div.bs-datepicker-head button.previous"));
            previous.WithJs().Click();
        }

        public void NextMonth()
        {
            var next = _driver.FindElement(By.CssSelector("div.bs-datepicker-container div.bs-datepicker-head button.next"));
            next.WithJs().Click();
        }

        public void SelectDate(int month, int date)
        {
            var monthName = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(month);
            Open();
            var monthHeader = _driver.FindElement(By.CssSelector("div.bs-datepicker-head button.current"));
            monthHeader.WithJs().Click();

            var monthToSelect = _driver.FindElement(By.XPath($"//table[@class=\"months\"]/tbody/tr/td/span[text()=\"{monthName}\"]"));
            monthToSelect.WithJs().Click();

            var dateToSelect = _driver.FindElement(By.XPath($"//table[@class=\"days weeks\"]/tbody/tr/td/span[text()=\"{date}\"]"));
            dateToSelect.WithJs().Click();
        }

        public void GoToDate(string date = null)
        {
            var dates = _driver.FindElements(By.CssSelector("div.bs-datepicker-container div.bs-datepicker-body td[role='gridcell']>span:not(.is-other-month)"));
            if (!dates.Any()) return;
            if (!string.IsNullOrWhiteSpace(date))
            {
                dates.FirstOrDefault(_ => _.Text == date)?.Click();
                return;
            }

            dates.FirstOrDefault()?.Click();
        }

        public void GoToDate(int days, DateTime? selectedDate = null)
        {
            var dateToGo = DateTime.Today.AddDays(days);
            Open();

            if (dateToGo.Month != DateTime.Today.Month || (selectedDate.HasValue && dateToGo.Month != selectedDate.Value.Month))
            {
                if (days < 0)
                    PreviousMonth();
                else if (days > 0)
                    NextMonth();
            }

            GoToDate(dateToGo.Day.ToString());
            Driver.WaitForAngular();
        }
    }
}