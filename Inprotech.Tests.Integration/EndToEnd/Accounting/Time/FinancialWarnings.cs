using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class FinancialWarnings : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(isDebtorNameTypeRestricted: false);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        public void Prepayments(BrowserType browserType)
        {
            _dbData = TimeRecordingDbHelper.SetupPrepayments(_dbData);
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.AddButton.ClickWithTimeout();

            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            casePicker.Typeahead.SendKeys(_dbData.Case.Irn);
            casePicker.Typeahead.SendKeys(Keys.ArrowDown);
            casePicker.Typeahead.SendKeys(Keys.ArrowDown);
            casePicker.Typeahead.SendKeys(Keys.Enter);

            var wipWarningDialog = new WipWarningsModal(driver);
            var casePrepayment = wipWarningDialog.PrepaymentWarningSection.CasePrepayments;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Prepayments.casePrepayment}.00", casePrepayment, $"Expected Case Prepayment value to be: {casePrepayment}");
            var debtorPrepayment = wipWarningDialog.PrepaymentWarningSection.DebtorPrepayments;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Prepayments.debtorPrepayment}.00", debtorPrepayment, $"Expected Debtor Prepayment value to be: {debtorPrepayment}");
            var totalWip = wipWarningDialog.PrepaymentWarningSection.TotalWip;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}1,110.00", totalWip, $"Expected Total WIP to be: {totalWip}");

            wipWarningDialog.Cancel();

            var namePicker = new AngularPicklist(driver).ByName("name");
            namePicker.Typeahead.SendKeys(_dbData.Debtor.NameCode);
            namePicker.Typeahead.SendKeys(Keys.ArrowDown);
            namePicker.Typeahead.SendKeys(Keys.ArrowDown);
            namePicker.Typeahead.SendKeys(Keys.Enter);

            wipWarningDialog = new WipWarningsModal(driver);
            debtorPrepayment = wipWarningDialog.PrepaymentWarningSection.DebtorPrepayments;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.Prepayments.debtorPrepayment}.00", debtorPrepayment, $"Expected Debtor Prepayment value to be: {debtorPrepayment}");
            totalWip = wipWarningDialog.PrepaymentWarningSection.TotalWip;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}900.00", totalWip, $"Expected Total WIP to be: {totalWip}");

            wipWarningDialog.Proceed();
        }

        [TestCase(BrowserType.Chrome)]
        public void BillingCap(BrowserType browserType)
        {
            _dbData = TimeRecordingDbHelper.SetupBillingCap(_dbData);
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.AddButton.ClickWithTimeout();

            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            casePicker.Typeahead.SendKeys(_dbData.Case.Irn);
            casePicker.Typeahead.SendKeys(Keys.ArrowDown);
            casePicker.Typeahead.SendKeys(Keys.ArrowDown);
            casePicker.Typeahead.SendKeys(Keys.Enter);

            var wipWarningDialog = new WipWarningsModal(driver);
            Assert.IsTrue(wipWarningDialog.BillingCapWarningSection.Message.Contains(_dbData.Debtor.LastName), $"Expected title to contain debtor name: {_dbData.Debtor.LastName}");
            var billingCapValue = wipWarningDialog.BillingCapWarningSection.Value;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.BillingCap.value}.00", billingCapValue.Replace(",", string.Empty), $"Expected Billing Cap value to be: {_dbData.BillingCap.value}.00");
            var billedValue = wipWarningDialog.BillingCapWarningSection.Billed;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.BillingCap.totalBilled}.00", billedValue.Replace(",", string.Empty), $"Expected Total Billed value to be: {_dbData.BillingCap.totalBilled}.00");
            var period = wipWarningDialog.BillingCapWarningSection.Period;
            Assert.IsTrue(period.ToLower().StartsWith(_dbData.BillingCap.period), $"Expected Period to start with: {_dbData.BillingCap.period}");
            var startDate = wipWarningDialog.BillingCapWarningSection.StartDate;
            Assert.AreEqual(_dbData.BillingCap.startDate, DateTime.Parse(startDate), $"Expected Start Date to be: {_dbData.BillingCap.startDate}");

            wipWarningDialog.Cancel();

            var namePicker = new AngularPicklist(driver).ByName("name");
            namePicker.Typeahead.SendKeys(_dbData.Debtor.NameCode);
            namePicker.Typeahead.SendKeys(Keys.ArrowDown);
            namePicker.Typeahead.SendKeys(Keys.ArrowDown);
            namePicker.Typeahead.SendKeys(Keys.Enter);

            wipWarningDialog = new WipWarningsModal(driver);
            billingCapValue = wipWarningDialog.BillingCapWarningSection.Value;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.BillingCap.value}.00", billingCapValue.Replace(",", string.Empty), $"Expected Billing Cap value to be: {_dbData.BillingCap.value}.00");
            billedValue = wipWarningDialog.BillingCapWarningSection.Billed;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.BillingCap.totalBilled}.00", billedValue.Replace(",", string.Empty), $"Expected Total Billed value to be: {_dbData.BillingCap.totalBilled}.00");
            period = wipWarningDialog.BillingCapWarningSection.Period;
            Assert.IsTrue(period.ToLower().StartsWith(_dbData.BillingCap.period), $"Expected Period to start with: {_dbData.BillingCap.period}");
            startDate = wipWarningDialog.BillingCapWarningSection.StartDate;
            Assert.AreEqual(_dbData.BillingCap.startDate, DateTime.Parse(startDate), $"Expected Start Date to be: {_dbData.BillingCap.startDate}");
            wipWarningDialog.Proceed();
        }

        [TestCase(BrowserType.Chrome)]
        public void CreditLimits(BrowserType browserType)
        {
            _dbData = TimeRecordingDbHelper.SetupCreditLimit(_dbData);
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.AddButton.ClickWithTimeout();

            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            casePicker.EnterExactSelectAndBlur(_dbData.Case.Irn);

            var wipWarningDialog = new WipWarningsModal(driver);
            var message = wipWarningDialog.CreditLimitWarningSection.Message;
            Assert.True(message.Contains($"{_dbData.CreditLimit.limitPercentage}%"), "Expected credit limit message to display percentage");
            var balance = wipWarningDialog.CreditLimitWarningSection.CaseBalance(_dbData.Debtor.Id);
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.balance}.00", balance.Replace(",", string.Empty), $"Expected Receivable Balance to be: {_dbData.CreditLimit.balance}.00");
            var value = wipWarningDialog.CreditLimitWarningSection.CaseValue(_dbData.Debtor.Id);
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.value}.00", value.Replace(",", string.Empty), $"Expected Credit Limit value to be: {_dbData.CreditLimit.value}.00");
            var name = wipWarningDialog.CreditLimitWarningSection.DebtorName(_dbData.Debtor.Id);
            Assert.AreEqual(_dbData.Debtor.LastName, name, $"Expected debtor name to be {_dbData.Debtor.LastName} but was {name}");

            balance = wipWarningDialog.CreditLimitWarningSection.CaseBalance(_dbData.Debtor2.Id);
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.balance}.00", balance.Replace(",", string.Empty), $"Expected Receivable Balance to be: {_dbData.CreditLimit.balance}.00");
            value = wipWarningDialog.CreditLimitWarningSection.CaseValue(_dbData.Debtor2.Id);
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.value}.00", value.Replace(",", string.Empty), $"Expected Credit Limit value to be: {_dbData.CreditLimit.value}.00");
            name = wipWarningDialog.CreditLimitWarningSection.DebtorName(_dbData.Debtor2.Id);
            Assert.AreEqual(_dbData.Debtor2.LastName, name, $"Expected debtor name to be {_dbData.Debtor2.LastName} but was {name}");
            wipWarningDialog.Cancel();

            var namePicker = new AngularPicklist(driver).ByName("name");
            namePicker.EnterExactSelectAndBlur(_dbData.Debtor.NameCode);

            wipWarningDialog = new WipWarningsModal(driver);
            message = wipWarningDialog.CreditLimitWarningSection.Message;
            Assert.True(message.Contains($"{_dbData.CreditLimit.limitPercentage}%"), "Expected credit limit message to display percentage");
            balance = wipWarningDialog.CreditLimitWarningSection.NameBalance;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.balance}.00", balance.Replace(",", string.Empty), $"Expected Receivable Balance to be: {_dbData.CreditLimit.balance}.00");
            value = wipWarningDialog.CreditLimitWarningSection.NameValue;
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}{_dbData.CreditLimit.value}.00", value.Replace(",", string.Empty), $"Expected Credit Limit value to be: {_dbData.CreditLimit.value}.00");
            wipWarningDialog.Proceed();
        }
    }
}
