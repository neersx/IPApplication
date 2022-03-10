using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting
{
    public class WipWarningsModal : ModalBase
    {
        readonly NgWebDriver _driver;

        public WipWarningsModal(NgWebDriver driver) : base(driver)
        {
            _driver = driver;
        }

        public void Proceed()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Proceed')]")).ClickWithTimeout();
        }

        public void Cancel()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]")).ClickWithTimeout();
        }

        public BudgetWarning BudgetWarningSection => new BudgetWarning(_driver);

        public class BudgetWarning : PageObject
        {
            readonly NgWebElement _container;

            public BudgetWarning(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
            {
                _container = driver.FindElements(By.Id("budgetWarnings")).FirstOrDefault() ?? new NgWebElement(driver, null);
            }

            public string Budget => _container.FindElements(By.Id("budget"))?.FirstOrDefault()?.Text;

            public string BilledTotal => _container.FindElements(By.Id("billedTotal"))?.FirstOrDefault()?.Text;

            public string UsedTotal => _container.FindElements(By.Id("usedTotal"))?.FirstOrDefault()?.Text;

            public string UnbilledTotal => _container.FindElements(By.Id("unbilledTotal"))?.FirstOrDefault()?.Text;

            public string BudgetUsedPerc => _container.FindElements(By.Id("budgetUsedPerc"))?.FirstOrDefault()?.Text;   
        }

        public PrepaymentWarning PrepaymentWarningSection => new PrepaymentWarning(_driver);
        public class PrepaymentWarning : PageObject
        {
            readonly NgWebElement _container;

            public PrepaymentWarning(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
            { 
                _container = driver.FindElements(By.Id("prepaymentWarning")).FirstOrDefault() ?? new NgWebElement(driver, null);
            }

            public string CasePrepayments => _container.FindElement(By.Id("casePrepayment")).Text;
            public string DebtorPrepayments => _container.FindElement(By.Id("debtorPrepayment")).Text;
            public string TotalWip => _container.FindElement(By.Id("totalWipAndTime")).Text;
        }

        public BillingCapWarning BillingCapWarningSection => new BillingCapWarning(_driver);
        public class BillingCapWarning : PageObject
        {
            readonly NgWebElement _container;

            public BillingCapWarning(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
            {
                _container = driver.FindElements(By.Id("billingCapWarning")).FirstOrDefault() ?? new NgWebElement(driver, null);
            }

            public string Value => _container.FindElement(By.Id("billingCapValue")).Text;
            public string StartDate => _container.FindElement(By.Id("billingCapStartDate")).Text;
            public string Billed => _container.FindElement(By.Id("totalBilled")).Text;
            public string Period => _container.FindElement(By.Id("billingCapPeriod")).Text;
            public string Message => _container.FindElement(By.CssSelector("div.widget-body > div > label")).Text;
        }

        public CreditLimitWarning CreditLimitWarningSection => new CreditLimitWarning(_driver);
        public class CreditLimitWarning : PageObject
        {
            readonly NgWebElement _container;
            public CreditLimitWarning(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
            {
                _container = driver.FindElements(By.Id("creditLimitWarning")).FirstOrDefault() ?? new NgWebElement(driver, null);
            }

            public string Message => _container.FindElement(By.CssSelector("div:first-child > label > i")).Text;
            public string CaseBalance(int debtorNameKey) => _container.FindElement(By.CssSelector($"div#creditLimit_{debtorNameKey} div:nth-child(2) > span")).Text;
            public string CaseValue(int debtorNameKey) => _container.FindElement(By.CssSelector($"div#creditLimit_{debtorNameKey} div:nth-child(3) > span")).Text;
            public string DebtorName(int debtorNameKey) => _container.FindElement(By.CssSelector($"div#creditLimit_{debtorNameKey} div:nth-child(1) > span")).Text;
            public string NameBalance => _container.FindElement(By.CssSelector("div:nth-child(2) > div:nth-child(1) > span")).Text;
            public string NameValue => _container.FindElement(By.CssSelector("div:nth-child(2) > div:nth-child(2) > span")).Text;
        }

    }
}
