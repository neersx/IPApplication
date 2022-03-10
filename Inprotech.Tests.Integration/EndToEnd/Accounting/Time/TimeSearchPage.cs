using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    public class TimeSearchPage : PageObject
    {
        public TimeSearchPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement CloseSearch => Driver.FindElement(By.Id("closeSearch"));
        public AngularKendoGrid SearchResults => new AngularKendoGrid(Driver, "timeSearchResults");
        public AngularPicklist StaffName => new AngularPicklist(Driver).ByName("staff");
        public AngularDropdown Period => new AngularDropdown(Driver).ByName("timePeriod");
        public DatePicker FromDate => new DatePicker(Driver, "fromDate");
        public DatePicker ToDate => new DatePicker(Driver, "toDate");
        public AngularCheckbox IsPosted => new AngularCheckbox(Driver).ByName("isPosted");
        public AngularCheckbox IsUnposted => new AngularCheckbox(Driver).ByName("isUnposted");
        public AngularDropdown Entity => new AngularDropdown(Driver).ByName("entity");
        public AngularPicklist Cases => new AngularPicklist(Driver).ByName("case");
        public AngularPicklist Name => new AngularPicklist(Driver).ByName("name");

        public AngularCheckbox AsDebtor => new AngularCheckbox(Driver).ByName("asDebtor");
        public AngularCheckbox AsInstructor => new AngularCheckbox(Driver).ByName("asInstructor");
        public AngularPicklist Activity => new AngularPicklist(Driver).ByName("wipTemplates");
        public NgWebElement Narrative => Driver.FindElement(By.Name("narrativeText")).FindElement(By.TagName("input"));

        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector("div.search-options div.controls > button > span.cpa-icon-eraser"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("div.search-options div.controls > button > span.cpa-icon-search"))?.GetParent();

        public NgWebElement TotalTime() => Driver.FindElement(By.Id("totalTime"));
        public NgWebElement TotalValue() => Driver.FindElement(By.Id("totalValue"));
        public NgWebElement TotalDiscount() => Driver.FindElement(By.Id("totalDiscount"));

        public NgWebElement IncompleteIcon(int rowIndex)
        {
            return SearchResults.Rows[rowIndex].FindElement(By.CssSelector("span.cpa-icon-exclamation-triangle"));
        }

        public NgWebElement PostedIcon(int rowIndex)
        {
            return SearchResults.Rows[rowIndex].FindElement(By.CssSelector("span.cpa-icon-check-circle"));
        }

        public NgWebElement CaseLink(int rowIndex)
        {
            return SearchResults.Cell(rowIndex, "Case Ref.").FindElement(By.TagName("a"));
        }

        public NgWebElement NameLink(int rowIndex)
        {
            return SearchResults.Cell(rowIndex, "Name").FindElement(By.TagName("a"));
        }

        public AngularColumnSelection ColumnSelector => new AngularColumnSelection(Driver).ForGrid("timeSearchResults");

        public NgWebElement ExportToPdf => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_export-pdf']"));
        public NgWebElement ExportToExcel => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_export-excel']"));
        public NgWebElement ExportToWord => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_export-word']"));
        public NgWebElement Post => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_bulk-post']"));
        public NgWebElement Delete => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_bulk-delete']"));
        public NgWebElement UpdateNarrative => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_bulk-edit-narrative']"));
        public NgWebElement Copy => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_copy']"));

        public bool IsRowMarkedAsPosted(int rowIndex)
        {
            return SearchResults.Rows[rowIndex].GetAttribute("class").Contains("posted");
        }

        public void SetSearchDates()
        {
            var yesterday = DateTime.Today.AddDays(-1);
            FromDate.Open();
            if (yesterday.Month != DateTime.Today.Month)
                FromDate.PreviousMonth();

            FromDate.GoToDate(yesterday.Day.ToString());

            var tomorrow = DateTime.Today.AddDays(1);
            ToDate.Open();
            if (tomorrow.Month != DateTime.Today.Month)
                ToDate.NextMonth();

            ToDate.GoToDate(tomorrow.Day.ToString());
        }

        public void CheckTimeValues(bool asHidden)
        {
            if (asHidden)
            {
                Assert.Throws<NoSuchElementException>(() => TotalTime(), "Expected Total Time to be hidden");
                Assert.Throws<NoSuchElementException>(() => TotalValue(), "Expected Total Value to be hidden");
                Assert.Throws<NoSuchElementException>(() => TotalDiscount(), "Expected Total Discount to be hidden");
            }
            else
            {
                Assert.True(TotalTime().Displayed, "Expected Total Time to be displayed");
                Assert.True(TotalValue().Displayed, "Expected Total Value to be displayed");
                Assert.True(TotalDiscount().Displayed, "Expected Total Discount to be displayed");
            }
        }

        public void PerformSearch(Boolean isPosted = true, int fromDaysFromToday = -1, int toDaysFromToday = 0)
        {
            if (isPosted)
            {
                IsPosted.Click();
            }

            FromDate.GoToDate(fromDaysFromToday);
            ToDate.GoToDate(toDaysFromToday);

            SearchButton.Click();
            Driver.WaitForAngular();
        }

        public void VerifyInSearchResults(int expectedRows)
        {
            FromDate.Input.Clear();
            FromDate.GoToDate(0);
            ToDate.GoToDate(0);
            SearchButton.ClickWithTimeout();
            Assert.AreEqual(expectedRows, SearchResults.Rows.Count, "Expected only non-continued or last-child rows to be displayed");
        }
    }

    public class UpdateNarrativeModal : ModalBase
    {
        public AngularPicklist Narrative => new AngularPicklist(Driver, Modal).ByName("narrative");

        public NgWebElement NarrativeText => Modal.FindElement(By.Name("narrativeText")).FindElement(By.XPath(".//textarea"));

        public NgWebElement ApplyButton => Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Apply')]"));

        public UpdateNarrativeModal(NgWebDriver driver, string id = "updateNarrative") : base(driver, id)
        {
        }

        public void Apply(bool confirm = true)
        {
            ApplyButton.ClickWithTimeout();
            var confirmUpdateDialog = new CommonPopups(Driver).ConfirmModal;
            if (confirm)
            {
                confirmUpdateDialog.Proceed();
            }
            else
            {
                confirmUpdateDialog.Cancel();
            }
        }

        public NgWebElement Cancel()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]"));
        }
    }
}