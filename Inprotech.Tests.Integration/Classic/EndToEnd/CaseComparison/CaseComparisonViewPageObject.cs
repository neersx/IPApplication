using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    public class CaseComparisonViewPageObject : Selectors<CaseComparisonViewPageObject>
    {
        public CaseComparisonViewPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement CaseRefLink(string caseRef) => Driver.FindElement(OpenQA.Selenium.By.PartialLinkText(caseRef));

        public bool HasSelectableDiffs => Driver.WrappedDriver.ExecuteJavaScript<bool>("return $('.diff input[type=checkbox]:visible').length > 0");

        public NgWebElement RejectedMatchNotice => Driver.FindElement(OpenQA.Selenium.By.Name("matchRejectedIndicator"));

        public NgWebElement DuplicateMatchNotice => Driver.FindElement(OpenQA.Selenium.By.Name("duplicateIndicator"));

        public NgWebElement NavigateToDuplicateLink => DuplicateMatchNotice.FindElement(OpenQA.Selenium.By.CssSelector("a"));

        public ReadOnlyCollection<NgWebElement> CaseNames => Driver.FindElements(NgBy.Repeater("cn in viewData.caseNames"));

        public ReadOnlyCollection<NgWebElement> Events => Driver.FindElements(NgBy.Repeater("e in viewData.events"));

        public ReadOnlyCollection<NgWebElement> GoodsServices => Driver.FindElements(NgBy.Repeater("n in viewData.goodsServices"));

        public ReadOnlyCollection<NgWebElement> ParentRelatedCases => Driver.FindElements(NgBy.Repeater("n in viewData.parentRelatedCases"));

        public NgWebElement OfficialNumbers => Driver.FindElement(OpenQA.Selenium.By.Id("officialNumberComparisonTable"));

        public ReadOnlyCollection<NgWebElement> Documents => Driver.FindElements(NgBy.Repeater("d in documentsViewData"));

        public Checkbox Title => new Checkbox(Driver).ByModel("viewData.case.title.updated");

        public Checkbox TypeOfMark => new Checkbox(Driver).ByModel("viewData.case.typeOfMark.updated");

        public ButtonInput UpdateCase => new ButtonInput(Driver).ById("btnUpdateCase");

        public ButtonInput RejectCaseMatch => new ButtonInput(Driver).ById("btnRejectCaseMatch");

        public ButtonInput UndoRejectCaseMatch => new ButtonInput(Driver).ById("btnUndoRejectCaseMatch");

        public ButtonInput MarkReviewed => new ButtonInput(Driver).ById("btnMarkReviewed");

        public ButtonInput MoveAllToDms => new ButtonInput(Driver).ById("sendAllButton");

        public StackTraceDialog ErrorDetailsDialog => new StackTraceDialog(Driver,"stackTraceDialogcaseCompareErrorView");

        public void SelectChangeIn(NgWebElement element)
        {
            var checkbox = element.FindElement(OpenQA.Selenium.By.CssSelector("input[type='checkbox'"));
            checkbox?.ClickWithTimeout();
        }

        public bool IsDisplayed()
        {
            return Element.Displayed;
        }

        public void Update()
        {
            UpdateCase.Click();

            Driver.WaitForAngular();
        }

        public void RejectMatch()
        {
            RejectCaseMatch.Click();

            Driver.WaitForAngular();
        }

        public void UndoMatchRejection()
        {
            UndoRejectCaseMatch.Click();

            Driver.WaitForAngular();
        }

        public void WaitUntilLoaded()
        {
            var script = $"return $('#caseComparisonLoadSpinner').is(':visible') == false;";

            Driver.Wait().ForTrue(() => Driver.WrappedDriver.ExecuteJavaScript<bool>(script));
        }

        public IEnumerable<T> AllDocumentSummary<T>() where T : DocumentSummary, new()
        {
            return from d in Documents.AsEnumerable()
                   select new T
                          {
                              Row = d
                          };
        }

        public void DisplayErrorDetailsDialog()
        {
            // first error button
            var button = Driver.FindElement(OpenQA.Selenium.By.CssSelector("span.btn-danger"));

            button.WithJs().ScrollIntoView();

            button.Click();

            Driver.Wait().ForTrue(() => ErrorDetailsDialog.IsVisible());
        }

        public void DismissErrorDetailsDialog()
        {
            ErrorDetailsDialog.Close();
        }
    }

    public abstract class DocumentSummary
    {
        public NgWebElement Row
        {
            set => Build(value);
        }

        public string DocumentDescription { get; set; }

        public string Status { get; set; }

        public bool HasDownloadLink { get; set; }

        protected virtual void Build(NgWebElement tr)
        {
        }
    }

    public class StackTraceDialog : ModalBase
    {
        public StackTraceDialog(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public bool IsVisible()
        {
            return Modal.WithJs().IsVisible();
        }

        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }
    }
}