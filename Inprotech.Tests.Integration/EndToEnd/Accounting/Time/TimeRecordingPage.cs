using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Accounting.Time;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    public class TimeRecordingWidget : PageObject
    {
        public TimeRecordingWidget(NgWebDriver driver) : base(driver)
        {
            Container = driver.FindElement(By.CssSelector("ipx-time-recording-widget"));
        }

        public NgWebElement TimerIcon => Container.FindElements(By.CssSelector("ipx-inline-dialog span.cpa-icon-clock-o")).FirstOrDefault();

        public NgWebElement StopButton => Container.FindElement(By.CssSelector("button"));

        public bool IsDisplayed => TimerIcon?.Displayed ?? false;

        public void CheckTooltipValues(string startedOn = null, string caseRef = null, string name = null, string activity = null)
        {
            Driver.Hover(TimerIcon);
            Driver.WaitForAngular();

            var tooltip = Driver.FindElement(By.CssSelector("popover-container"));
            if (!string.IsNullOrEmpty(startedOn))
            {
                Assert.True(tooltip.Text.Contains(startedOn));
            }

            if (!string.IsNullOrEmpty(caseRef))
            {
                Assert.True(tooltip.Text.Contains(caseRef), "Case ref is displayed in the tooltip: " + tooltip.Text);
            }

            if (!string.IsNullOrEmpty(name))
            {
                Assert.True(tooltip.Text.Contains(name));
            }

            if (!string.IsNullOrEmpty(activity))
            {
                Assert.True(tooltip.Text.Contains(activity));
            }

            Driver.HoverOff();
        }
    }

    public class TimerWidgetPopup : ModalBase
    {
        public TimerWidgetPopup(NgWebDriver driver, string id = "timerWidget") : base(driver, id)
        {
        }

        public NgWebElement IrnLabel => Modal.FindElement(By.Id("irnLbl"));
        public NgWebElement NameLabel => Modal.FindElement(By.Id("nameLbl"));
        public AngularPicklist Activity => new AngularPicklist(Driver, Modal).ByName("wipTemplates");
        public AngularPicklist Narrative => new AngularPicklist(Driver, Modal).ByName("narrative");
        public IpxTextField NarrativeText => new IpxTextField(Driver, Modal).ByName("narrativeText");
        public IpxTextField Notes => new IpxTextField(Driver, Modal).ByName("notes");
        public NgWebElement ClockTimeSpan => Modal.FindElement(By.Id("clockTimeSpan"));

        public void Apply()
        {
            Modal.FindElement(By.Id("btnProceed")).TryClick();
        }

        public void Delete()
        {
            Modal.FindElement(By.Id("btnCancel")).TryClick();
        }

        public void Cancel()
        {
            Modal.FindElement(By.XPath("//ipx-icon[@name='times']")).TryClick();
        }

        public void Reset()
        {
            Modal.FindElement(By.Name("resetTimer")).TryClick();
        }

        public void Stop()
        {
            Modal.FindElement(By.Name("stopTimer")).TryClick();
        }
    }

    public class CopyTimeModal : ModalBase
    {
        public CopyTimeModal(NgWebDriver driver, string id = "recentTimeEntries") : base(driver, id)
        {
        }

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "recentEntries");
    }

    public class TimeRecordingPage : PageObject
    {
        public ContextMenu ContextMenu;

        public TimeRecordingPage(NgWebDriver driver) : base(driver)
        {
            ContextMenu = new ContextMenu(driver);
        }

        public AngularPicklist StaffName => new AngularPicklist(Driver).ByName("timeForStaff");
        public DatePicker SelectedDate => new DatePicker(Driver, "selectedDate");
        public AngularKendoGrid Timesheet => new AngularKendoGrid(Driver, "timesheet");

        public AngularColumnSelection ColumnSelector => new AngularColumnSelection(Driver).ForGrid("timesheet");

        public NgWebElement TodayButton => Driver.FindElement(By.CssSelector("button.btn[name='today']"));
        public NgWebElement PreviousButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-left"));
        public NgWebElement NextButton => Driver.FindElement(By.CssSelector("button.btn-icon span.cpa-icon-chevron-circle-right"));
        public NgWebElement AddButton => Driver.FindElements(By.CssSelector("ipx-add-button button")).FirstOrDefault();
        public NgWebElement CopyButton => Driver.FindElements(By.Id("btnCopyTimeEntry")).FirstOrDefault();
        public NgWebElement CaseSummarySwitch => Driver.FindElement(By.CssSelector("ipx-page-title action-buttons div.switch label"));

        public NgWebElement TotalHours => Driver.FindElement(By.Id("totalHours"));
        public NgWebElement TotalCharges => Driver.FindElement(By.Id("totalChargeable"));
        public NgWebElement TotalValue => Driver.FindElement(By.Id("totalValue"));
        public ButtonInput PostButton => new ButtonInput(Driver).ById("btnPost");
        public ButtonInput SearchButton => new ButtonInput(Driver).ById("btnSearch");

        public ButtonInput StartTimerButton => new ButtonInput(Driver).ById("btnStartTimer");
        public ButtonInput StartTimerLink => new ButtonInput(Driver).ById("lnkStartTimer");

        public NgWebElement IncompleteIcon(int rowIndex)
        {
            return Timesheet.MasterRows[rowIndex].FindElement(By.CssSelector("span.cpa-icon-exclamation-triangle"));
        }

        public NgWebElement PostedIcon(int rowIndex)
        {
            return Timesheet.MasterRows[rowIndex].FindElement(By.CssSelector("span.cpa-icon-check-circle"));
        }

        public NgWebElement ContinuationIcon(int rowIndex)
        {
            return Timesheet.MasterRows[rowIndex].FindElement(By.CssSelector("ipx-inline-dialog > span.inline-dialog > span.cpa-icon-clock-o"));
        }

        public bool IsRowMarkedAsPosted(int rowIndex)
        {
            return Timesheet.MasterRows[rowIndex].GetAttribute("class").Contains("posted");
        }

        public NgWebElement ApplyButton()
        {
            return Driver.FindElement(By.Id("applyPreferenceChanges"));
        }

        public NgWebElement CancelButton()
        {
            return Driver.FindElement(By.Id("cancelPreferenceChanges"));
        }

        public NgWebElement PreviewDefaultsButton()
        {
            return Driver.FindElement(By.Id("previewDefaultPreferences"));
        }

        public NgWebElement ResetToDefaultButton()
        {
            return Driver.FindElement(By.Id("resetToDefaultPreferences"));
        }

        public NgWebElement DisplayOverlaps()
        {
            return Driver.FindElement(By.CssSelector("#showOverlapsSwitch + label"));
        }

        public bool IsRowMarkedAsOverlap(int rowIndex)
        {
            return Timesheet.Cell(rowIndex, 4).FindElements(By.CssSelector("span.overlap")).Any();
        }

        public void ChangeEntryDate(int entryIndex, string year, int day)
        {
            Timesheet.OpenTaskMenuFor(entryIndex);
            ContextMenu.ChangeEntryDate();
            Driver.WaitForAngularWithTimeout();
            var changeEntryDateDialog = new ChangeEntryDateModal(Driver);
            var datePicker = changeEntryDateDialog.NewDate();
            datePicker.Input.Clear();
            datePicker.Input.SendKeys(year);
            datePicker.Open();
            datePicker.PreviousMonth();
            datePicker.GoToDate(day.ToString());
            changeEntryDateDialog.Save();
            Driver.WaitForAngularWithTimeout();
        }

        public void DeleteEntry(int entryIndex, bool applyCheckbox = false)
        {
            Timesheet.OpenTaskMenuFor(entryIndex);
            ContextMenu.Delete();

            var popups = new CommonPopups(Driver);
            if (applyCheckbox)
            {
                Driver.WaitForAngularWithTimeout();
                popups.ConfirmNgDeleteModal.DeleteOptionCheckbox.Click();
            }

            popups.ConfirmNgDeleteModal.Delete.ClickWithTimeout();
            Driver.WaitForAngularWithTimeout();
        }

        public class TimerRow : PageObject
        {
            public TimerRow(NgWebDriver driver) : base(driver)
            {
                Container = driver.FindElement(By.XPath("//div[@class='timerSpinner']/ancestor::tr"));
            }

            public string StartTime => Container.FindElements(By.CssSelector("td"))[4].WithJs().GetInnerText();
            public string FinishTime => Container.FindElements(By.CssSelector("td"))[5].WithJs().GetInnerText();
            public string ElapsedTime => Container.FindElements(By.CssSelector("td"))[6].WithJs().GetInnerText();
            public NgWebElement StopButton => Container.FindElements(By.CssSelector("td"))[6].FindElement(By.CssSelector("button.btn-icon span.cpa-icon-square"));
            public NgWebElement ResetButton => Container.FindElements(By.CssSelector("td"))[6].FindElement(By.CssSelector("button.btn-icon span.cpa-icon-revert"));

            public AngularPicklist CaseRef => new AngularPicklist(Driver, Container).ByName("caseRef");

            public void OpenTaskMenu()
            {
                Container.FindElement(By.Name("tasksMenu")).Click();
                Driver.WaitForAngular();
            }
        }

        public class EditableRow : PageObject
        {
            public EditableRow(NgWebDriver driver, AngularKendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
            {
                Container = grid.MasterRows[rowIndex];
            }

            public AngularTimePicker StartTime => new AngularTimePicker(Driver, Container).FindElement(By.Id("startTime"));

            public AngularTimePicker FinishTime => new AngularTimePicker(Driver, Container).FindElement(By.Id("finishTime"));

            public AngularTimePicker Duration => new AngularTimePicker(Driver, Container).FindElement(By.Id("elapsedTime"));

            public AngularPicklist CaseRef => new AngularPicklist(Driver, Container).ByName("caseRef");

            public AngularPicklist Name => new AngularPicklist(Driver, Container).ByName("name");

            public AngularPicklist Activity => new AngularPicklist(Driver, Container).ByName("wipTemplates");

            public AngularTextField Units => new AngularTextField(Driver, "totalUnits");
        }

        public class DetailSection : PageObject
        {
            public DetailSection(NgWebDriver driver, AngularKendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
            {
                Container = grid.DetailRows[rowIndex];
            }

            public NgWebElement NarrativeText => Container.FindElement(By.Name("narrativeText")).FindElement(By.XPath(".//textarea"));
            public AngularPicklist Narrative => new AngularPicklist(Driver, Container).ByName("narrative");

            public NgWebElement Notes => Container.FindElements(By.CssSelector("ipx-text-field[name='notes'] textarea")).First();
            public string AccumulatedDuration => Container.FindElement(By.Id("timeValues")).FindElement(By.Id("accumulatedDuration")).Text;
            public string LocalValue => Container.FindElement(By.Id("timeValues")).FindElement(By.Id("localValue")).Text;
            public string LocalDiscount => Container.FindElement(By.Id("timeValues")).FindElement(By.Id("localDiscount")).Text;
            public string ChargeRate => Container.FindElement(By.Id("timeValues")).FindElement(By.Id("chargeOutRate")).Text;
            public NgWebElement MultiDebtorChargeRate => Container.FindElement(By.Id("timeValues")).FindElement(By.CssSelector("#chargeOutRate ipx-inline-dialog"));
            public string ForeignValue => Container.FindElement(By.Id("foreignValues")).FindElement(By.CssSelector("span:nth-of-type(1)")).Text;
            public string ForeignDiscount => Container.FindElement(By.Id("foreignValues")).FindElements(By.CssSelector("span"))[1].Text;

            public string DisabledNotesText => Notes?.GetAttribute("value");

            public NgWebElement SaveButton()
            {
                return Container.FindElement(By.CssSelector("ipx-save-button")).FindElement(By.TagName("button"));
            }

            public NgWebElement ClearButton()
            {
                return Container.FindElement(By.CssSelector("ipx-clear-button"));
            }

            public NgWebElement RevertButton()
            {
                return Container.FindElement(By.CssSelector("ipx-revert-button"));
            }

            public NgWebElement DeleteTimer()
            {
                return Container.FindElement(By.CssSelector("ipx-delete-button"));
            }

            public void ClickDisabledNotes(BrowserType browserType)
            {
                if (browserType == BrowserType.Ie)
                {
                    Notes.WithJs().Click();
                    return;
                }

                Notes.Click();
            }

            public void ViewDebtorValuation()
            {
                Container.FindElement(By.Id("timeValues")).FindElement(By.Id("localValue")).WithJs().Click();
            }
        }
    }

    public class ContextMenu
    {
        readonly NgWebDriver _driver;
        public Action AdjustValue;
        public Action ChangeEntryDate;
        public Action Continue;
        public Action ContinueAsTimer;
        public Action Delete;
        public Action DuplicateEntry;
        public Action Edit;
        public Action Post;
        public Action Revert;
        public Action MaintainEventNote;
        public Action AddAttachment;
        public Action MaintainCaseNarrative;
        public Action ViewCaseAttachments;

        public ContextMenu(NgWebDriver driver)
        {
            _driver = driver;

            Edit = () => ClickContextMenu(EditMenu);
            Revert = () => ClickContextMenu(RevertMenu);
            ChangeEntryDate = () => ClickContextMenu(ChangeEntryDateMenu);
            Continue = () => ClickContextMenu(ContinueMenu);
            Delete = () => ClickContextMenu(DeleteMenu);
            Post = () => ClickContextMenu(PostMenu);
            AdjustValue = () => ClickContextMenu(AdjustMenu);
            ContinueAsTimer = () => ClickContextMenu(ContinueAsTimerMenu);
            DuplicateEntry = () => ClickContextMenu(DuplicateEntryMenu);
            MaintainEventNote = () => ClickContextMenu(MaintainEventNoteMenu);
            AddAttachment = () => ClickContextMenu(AddAttachmentMenu);
            MaintainCaseNarrative = () => ClickContextMenu(MaintainCaseNarrativeMenu);
            ViewCaseAttachments = () => ClickContextMenu(CaseViewAttachmentMenu);
        }

        public NgWebElement EditMenu => new AngularKendoGridContextMenu(_driver).Option("edit");
        public NgWebElement RevertMenu => new AngularKendoGridContextMenu(_driver).Option("revert");
        public NgWebElement ChangeEntryDateMenu => new AngularKendoGridContextMenu(_driver).Option("changeEntryDate");
        public NgWebElement ContinueMenu => new AngularKendoGridContextMenu(_driver).Option("continue");
        public NgWebElement DeleteMenu => new AngularKendoGridContextMenu(_driver).Option("delete");
        public NgWebElement PostMenu => new AngularKendoGridContextMenu(_driver).Option("post");
        public NgWebElement AdjustMenu => new AngularKendoGridContextMenu(_driver).Option("adjust");
        public NgWebElement ContinueAsTimerMenu => new AngularKendoGridContextMenu(_driver).Option("continueTimer");
        public NgWebElement DuplicateEntryMenu => new AngularKendoGridContextMenu(_driver).Option("duplicate");
        public NgWebElement MaintainEventNoteMenu => new AngularKendoGridContextMenu(_driver).Option("maintainEventNote");
        public NgWebElement AddAttachmentMenu => new AngularKendoGridContextMenu(_driver).Option("addAttachment");
        public NgWebElement MaintainCaseNarrativeMenu => new AngularKendoGridContextMenu(_driver).Option("caseNarrative");
        public NgWebElement OpenCaseWebLinksMenu => new AngularKendoGridContextMenu(_driver).Option("caseWebLinks");
        public NgWebElement CaseViewAttachmentMenu => new AngularKendoGridContextMenu(_driver).Option("caseDocuments");

        static void ClickContextMenu(NgWebElement task)
        {
            task.FindElement(By.CssSelector("span:nth-child(2)")).WithJs().Click();
        }
    }

    public static class NgWebElementExtensionForContextMenu
    {
        public static bool Disabled(this NgWebElement element)
        {
            return element.WithJs().HasClass("disabled");
        }
    }

    public class CaseSummaryPageObject : PageObject
    {
        public CaseSummaryPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement CaseSummaryPane => Driver.FindElement(By.Id("caseSummaryPane"));

        public NgWebElement CaseRefLink => CaseSummaryPane.FindElement(By.CssSelector("a#caseReference"));
        public NgWebElement AgedWipExpand => Driver.FindElement(By.CssSelector("div#aged-wip-data label.cpa-icon-chevron-down"));
        public NgWebElement AgedWipCollapse => Driver.FindElement(By.CssSelector("div#aged-wip-data label.cpa-icon-chevron-up"));

        public NgWebElement NoInformationAvailable()
        {
            return CaseSummaryPane.FindElement(By.CssSelector("header ipx-inline-alert"));
        }

        public NgWebElement TotalWorkPerformed()
        {
            return CaseSummaryPane.FindElement(By.CssSelector("span#totalWorkPerformed"));
        }

        public NgWebElement UnpostedTime()
        {
            return CaseSummaryPane.FindElement(By.CssSelector("span#unpostedTime"));
        }

        public NgWebElement LastInvoiceDate()
        {
            return Driver.FindElement(By.CssSelector("span#lastInvoiceDate"));
        }

        public NgWebElement ActiveBudget()
        {
            return CaseSummaryPane.FindElement(By.CssSelector("span#activeBudget"));
        }

        public NgWebElement BudgetUsed()
        {
            return CaseSummaryPane.FindElement(By.CssSelector("span#budgetUsed"));
        }

        public NgWebElement NameLinkFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-{id} ipx-ie-only-url a"));
        }

        public NgWebElement NameRestrictionIconFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-{id} ipx-debtor-restriction-flag span.debtor-restrictions"));
        }

        public NgWebElement BillPercentageFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-{id} div.article-label"));
        }

        public NgWebElement AgedWipDataSection()
        {
            return Driver.FindElement(By.CssSelector("div#aged-wip-data ipx-aged-totals"));
        }

        public NgWebElement AgedBalanceExpandFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-receivable-{id} label.cpa-icon-chevron-down"));
        }

        public NgWebElement AgedBalanceCollapseFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-receivable-{id} label.cpa-icon-chevron-up"));
        }

        public NgWebElement AgedBalanceDataSectionFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-receivable-detail-{id} ipx-aged-totals"));
        }

        public NgWebElement ReceivableBalanceFor(string id)
        {
            return Driver.FindElement(By.CssSelector($"div#debtor-receivable-{id}"));
        }
    }

    public class ChangeEntryDateModal : ModalBase
    {
        public ChangeEntryDateModal(NgWebDriver driver, string id = "changeEntryDate") : base(driver, id)
        {
        }

        public void Save()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Save')]")).ClickWithTimeout();
        }

        public NgWebElement Cancel()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]"));
        }

        public DatePicker NewDate()
        {
            return new DatePicker(Driver, "selectedDate", Modal);
        }
    }

    public class PostTimePopup : MaintenanceModal
    {
        readonly NgWebDriver _driver;

        public PostTimePopup(NgWebDriver driver, string name) : base(driver, name)
        {
            _driver = driver;
        }
        public string TimeFor => _driver.FindElement(By.Id("staffName"))?.Text;
        public NgWebElement TimeForField => _driver.FindElement(By.Id("staffName"));
        public AngularDropdown Entity => new AngularDropdown(_driver, "ipx-dropdown").ByName("entityDropdown");
        public ButtonInput PostButton => new ButtonInput(_driver).ByClassName("btn-primary");
        public AngularKendoGrid DatesWithDetails => new AngularKendoGrid(_driver, "timePostingGrid");
        public NgWebElement PostAllRadio => _driver.FindElement(By.CssSelector("#postAll input[type='radio']"));
        public NgWebElement PostSelectedRadio => _driver.FindElement(By.CssSelector("#postSelected input[type='radio']"));
        public AngularCheckbox PostForAllStaff => new AngularCheckbox(_driver).ByName("postAllStaff");
        public DatePicker FromDatePicker => new(_driver, "fromDate");
        public DatePicker ToDatePicker=> new(_driver, "toDate");
        public void CloseModal()
        {
            _driver.FindElement(By.CssSelector("ipx-close-button button")).ClickWithTimeout();
        }
    }

    public class PostFeedbackDlg : MaintenanceModal
    {
        readonly NgWebDriver _driver;

        public PostFeedbackDlg(NgWebDriver driver, string name) : base(driver, name)
        {
            _driver = driver;
        }

        public NgWebElement TimeEntriesPostedLbl => _driver.FindElement(By.CssSelector("#postTimeResDlg .modal-body div label"));
        public NgWebElement TimeEntriesPostedValue => _driver.FindElement(By.CssSelector("#postTimeResDlg .modal-body div label+span"));

        public NgWebElement IncompleteEntriesRemainingLbl => _driver.FindElement(By.CssSelector("#postTimeResDlg .modal-body div:last-child label"));
        public NgWebElement IncompleteEntriesRemainingSpan => _driver.FindElement(By.CssSelector("#postTimeResDlg .modal-body div:last-child label+span"));

        public NgWebElement OkButton => _driver.FindElement(By.CssSelector("#postTimeResDlg .btn-default"));
    }

    public class DuplicateDlg : MaintenanceModal
    {
        readonly NgWebElement _container;
        readonly NgWebDriver _driver;

        public DuplicateDlg(NgWebDriver driver, string id = null) : base(driver, id)
        {
            _driver = driver;
            _container = _driver.FindElement(By.Id("duplicateEntryModal"));
        }

        public DatePicker StartDatePicker => new DatePicker(_driver, "startDate", _container);

        public DatePicker EndDatePicker => new DatePicker(_driver, "endDate", _container);

        public AngularCheckbox WeekDays => new AngularCheckbox(_driver, _container).ByTagName();
    }

    public class DebtorValuationsModal : ModalBase
    {
        public DebtorValuationsModal(NgWebDriver driver, string id = "debtorValuationSummary") : base(driver, id)
        {
        }

        public void VerifySplits(IEnumerable<DebtorSplit> splits)
        {
            foreach (var split in splits)
            {
                var row = Driver.FindElement(By.Id($"split_{split.DebtorNameNo}"));
                Assert.AreEqual(split.DebtorName, row.FindElement(By.CssSelector("div:nth-of-type(1)")).Text);
                Assert.AreEqual($"{split.ForeignCurrency}{split.ChargeOutRate}.00", row.FindElement(By.CssSelector("div:nth-of-type(2)")).Text);
                Assert.AreEqual($"{split.ForeignCurrency}{split.LocalValue}.00", row.FindElement(By.CssSelector("div:nth-of-type(3)")).Text);
            }
        }

        public string TotalLocalValue => Driver.FindElement(By.Id("split-totals")).FindElement(By.CssSelector("div:nth-of-type(2)")).Text;

        public void CloseModal()
        {
            Driver.FindElement(By.CssSelector("ipx-close-button button")).ClickWithTimeout();
        }
    }
}