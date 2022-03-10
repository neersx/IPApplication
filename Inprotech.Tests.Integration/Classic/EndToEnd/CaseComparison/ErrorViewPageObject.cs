using System.Collections.ObjectModel;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    public class ErrorViewPageObject : Selectors<ErrorViewPageObject>
    {
        readonly NgWebDriver _driver;

        public ErrorViewPageObject(NgWebDriver driver) : base(driver, null)
        {
            _driver = driver;
        }

        public ReadOnlyCollection<NgWebElement> ErrorDetails => Driver.FindElements(NgBy.Repeater("item in details"));

        public ErrorDetailDialog ErrorDetailsDialog => new ErrorDetailDialog(_driver, "stackTraceDialogerrorView");

        public bool IsDisplayed()
        {
            return Element.Displayed;
        }

        public void DisplayErrorDetailsDialog(int index)
        {
            // first error button
            var button = ErrorDetails[index].FindElement(OpenQA.Selenium.By.CssSelector(".btn-info"));

            button.WithJs().ScrollIntoView();

            button.Click();

            var closeButtonVisible = "return $('#stackTraceDialogerrorView .btn-discard').is(':visible') == true";

            Driver.Wait().ForTrue(() => Driver.WrappedDriver.ExecuteJavaScript<bool>(closeButtonVisible));
        }
    }

    public class ErrorDetailDialog : ModalBase
    {
        public ErrorDetailDialog(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }
    }
}