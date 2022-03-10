using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class ChargeForm : PageObject
    {
        readonly NgWebDriver _driver;
        readonly NgWebElement _container;
        readonly string _selector;
        PickList _chargeType;
        Checkbox _payFee;
        Checkbox _raiseCharge;
        Checkbox _directPay;

        public ChargeForm(NgWebDriver driver, NgWebElement container = null, string selector = "") : base(driver, container)
        {
            _driver = driver;
            _selector = selector;
            _container = _selector == string.Empty ? container : FindElement(By.CssSelector(_selector));
        }

        public PickList ChargeType => _chargeType ?? (_chargeType = new PickList(_driver).ByName(_selector, "chargeType"));
        public Checkbox PayFee => _payFee ?? (_payFee = new Checkbox(_driver, _container).ByLabel(".isPayFee"));
        public Checkbox RaiseCharge => _raiseCharge ?? (_raiseCharge = new Checkbox(_driver, _container).ByLabel(".isRaiseCharge"));
        public Checkbox UseEstimate
        {
            get
            {
                var label = _raiseCharge?.IsChecked == true ? ".isUseEstimate" : ".isCreateEstimate";
                return new Checkbox(_driver, _container).ByLabel(label);
            }
        }
        public Checkbox DirectPay => _directPay ?? (_directPay = new Checkbox(_driver, _container).ByLabel(".isDirectPay"));

        public bool AreAllCheckboxesDisabled => PayFee.IsDisabled && RaiseCharge.IsDisabled && UseEstimate.IsDisabled && DirectPay.IsDisabled;
    }
}