using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;
using static Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms.DocumentManagementPageObject;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    public class NewCaseViewDetail : DetailPage
    {
        public NewCaseViewDetail(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement PropertyStatusIcon => Driver.FindElement(By.CssSelector("ipx-sticky-header span[name='propertyTypeStatus']"));

        public NgWebElement PropertyTypeIcon => Driver.FindElement(By.CssSelector("ipx-sticky-header span[name='propertyTypeStatus'] i"));

        public string PageTitle()
        {
            return Driver.FindElements(By.CssSelector("ipx-sticky-header ipx-page-title h2 span.ipx-page-subtitle")).Last().Text;
        }

        public string PageDescription()
        {
            return Driver.FindElements(By.CssSelector("ipx-sticky-header ipx-page-title h2 span.ipx-page-description")).Last().Text;
        }

        public void GoToActionsTab()
        {
            var leftMenuTabs = Driver.FindElements(By.CssSelector(".topic-menu ul.nav-tabs li"));

            Driver.Wait().ForTrue(() => leftMenuTabs.Count == 2 && leftMenuTabs[1].Enabled);
            leftMenuTabs[1].WithJs().Click();

            Driver.WaitForAngular();
        }

        public void RecordTime()
        {
            new PageAction(Driver, "recordTime").Click();
        }

        public void RecordWithTimer()
        {
            new PageAction(Driver, "recordTimeWithTimer").Click();
        }
    }

    public class SummaryTopic : Topic
    {
        const string TopicKey = "summary";

        public SummaryTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement Field(string name, bool isExternal = false)
        {
            return isExternal ? Driver.FindElement(By.CssSelector($"[value='::viewData.{name}']")) : Driver.FindElement(By.CssSelector($"[data-screen-control='::vm.screenControl.{name}']"));
        }

        public string FieldLabel(string name)
        {
            return Driver.FindElement(By.CssSelector($"[data-screen-control='::vm.screenControl.{name}']")).FindElement(By.TagName("label")).Text;
        }

        public string FieldValue(string name)
        {
            return Driver.FindElement(By.CssSelector($"[data-screen-control='::vm.screenControl.{name}']")).FindElement(By.TagName("span")).Text;
        }

        public NgWebElement LinkField(string name, bool isExternal = false)
        {
            return isExternal ? Driver.FindElement(By.CssSelector($"[value='::viewData.{name}']")).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault() : Driver.FindElement(By.CssSelector($"[data-screen-control='::vm.screenControl.{name}']")).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault();
        }

        public NgWebElement NoScreenControlAlerts => Driver.FindElements(By.CssSelector("ip-inline-alert#NoScreenControlCriteria")).SingleOrDefault();
    }

    public class ActionTopic : Topic
    {
        const string TopicKey = "actions_";

        public ContextMenu ContextMenu;
        public ActionTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            ContextMenu = new ContextMenu(driver);
        }

        public AngularKendoGrid ActionGrid => new AngularKendoGrid(Driver, "caseViewActions");

        public AngularKendoGrid EventsGrid => new AngularKendoGrid(Driver, "caseViewActionEvents");

        public AngularKendoGrid EventNoteDetailsGrid => new AngularKendoGrid(Driver, "eventNoteDetails");

        public string EventsHeader => Driver.FindElement(By.CssSelector($"#caseViewActionEvents grid-toolbar span[translate='caseview.actions.events.header']")).WithJs().GetInnerText();

        public AngularDropdown ImportanceLevel => new AngularDropdown(Driver).ByName("importanceLevel");

        public AngularCheckbox OpenActions => new AngularCheckbox(Driver, TopicContainer).ById("caseview-actions-openActions");

        public AngularCheckbox ClosedActions => new AngularCheckbox(Driver, TopicContainer).ById("caseview-actions-closedActions");

        public AngularCheckbox PotentialActions => new AngularCheckbox(Driver, TopicContainer).ById("caseview-actions-potentialActions");

        public AngularCheckbox IsAllEvents => new AngularCheckbox(Driver).ByName("isAllEvents");
        public AngularCheckbox IsAllCycles => new AngularCheckbox(Driver).ByName("isAllCycles");
        public AngularCheckbox IsAllEventDetails => new AngularCheckbox(Driver).ByName("isAllEventDetails");
        public AngularColumnSelection EventsColumnSelector => new AngularColumnSelection(Driver).ForGrid("caseViewActionEvents");

        #region EventRuleDetailsModal

        public NgWebElement CaseReference => Driver.FindElement(By.XPath("//label[text()='Case Reference']/following-sibling::span"));
        public NgWebElement Event => Driver.FindElement(By.XPath("//label[text()='Event']/following-sibling::span"));
        public NgWebElement Action => Driver.FindElement(By.XPath("//label[text()='Action']/following-sibling::span"));
        public NgWebElement EventDescription => Driver.FindElement(By.XPath("//label[text()='Event Description']/parent::*/parent::*/div[1]/following-sibling::div/a"));
        public NgWebElement CriteriaNumber => Driver.FindElement(By.XPath("//label[text()='Criteria Number']/parent::*/parent::*/div[1]/following-sibling::div/a"));
        public NgWebElement EventNumber => Driver.FindElement(By.XPath("//label[text()='Event Number']/parent::*/parent::*/div[1]/following-sibling::div/a"));
        public NgWebElement Cycle => Driver.FindElement(By.XPath("//label[text()='Cycle']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement EventNoLink => Driver.FindElement(By.XPath("//table[@role='presentation']/tbody[@role='presentation']/tr[1]/td[10]/a"));
        public NgWebElement ModalCloseButton => Driver.FindElement(By.CssSelector(".modal-header .modal-header-controls ipx-close-button button"));
        public NgWebElement Notes => Driver.FindElement(By.XPath("//label[text()='Event Notes']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement ReminderMessage => Driver.FindElement(By.XPath("//span[text()='Reminder message:']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement CurrentNavigation => Driver.FindElement(By.Name("current"));
        public NgWebElement TotalNavigation => Driver.FindElement(By.Name("total"));
        public NgWebElement PreviousNavigation => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-chevron-circle-left"));
        public NgWebElement NextNavigation => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-chevron-circle-right"));
        public NgWebElement FirstNavigation => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-angle-double-left"));
        public NgWebElement LastNavigation => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-angle-double-right"));

        public bool HasTaskMenu => Driver.FindElements(By.Name("tasksMenu")).Any();

        public NgWebElement HeaderTitle(string title)
        {
            return Driver.FindElement(By.XPath("//h1[contains(text(),'" + title + "')]"));
        }

        public NgWebElement GetHeaderCount(NgWebDriver driver, string id)
        {
            return driver.FindElement(By.Id(id));
        }

        public NgWebElement DueDateCalculatedFromDate => Driver.FindElement(By.XPath("//label[text()='Calculated from date']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public KendoGrid DateComparisonGrid => new KendoGrid(Driver, "dateComparison");
        public KendoGrid SatisfiedEventsGrid => new KendoGrid(Driver, "satisfiedEvents");

        public NgWebElement DueDateCalFormatted => Driver.FindElement(By.CssSelector("label[id='calculatedFromLabel']"));
        public NgWebElement StandingInstructionInfo => Driver.FindElement(By.CssSelector("label[id='standingInstructionInfo']"));
        public NgWebElement SaveDueDate => Driver.FindElement(By.CssSelector("label[id='saveDueDate']"));
        public NgWebElement ReminderFormattedText => Driver.FindElement(By.XPath("//div[@id='documents']//span[contains(text(),'Commencing')]"));

        public NgWebElement DatesLogicMessage => Driver.FindElement(By.Id("datesLogicText"));
        public NgWebElement FailureActionMessage => Driver.FindElement(By.XPath("//*[@id='failureMessage']/span/span[2]"));
        public NgWebElement FailureActionIcon => Driver.FindElement(By.XPath("//*[@id='failureMessage']/span/span[1]"));

        public NgWebElement UpdateImmediately => Driver.FindElement(By.XPath("//label[text()='Event Occurrence']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement EventUpdateStatus => Driver.FindElement(By.XPath("//label[text()='Status set to']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement Charge1 => Driver.FindElement(By.XPath("//label[text()='Charge 1']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement Charge2 => Driver.FindElement(By.XPath("//label[text()='Charge 2']/parent::*/parent::*/div[3]/following-sibling::div/span"));
        public NgWebElement CreateAction => Driver.FindElement(By.XPath("//label[text()='Create Action']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public NgWebElement CloseAction => Driver.FindElement(By.XPath("//label[text()='Close Action']/parent::*/parent::*/div[3]/following-sibling::div/span"));
        public NgWebElement ReportToCpa => Driver.FindElement(By.XPath("//label[text()='Report to CPA']/parent::*/parent::*/div[1]/following-sibling::div/span"));
        public IEnumerable<NgWebElement> DatesToUpdateText => Driver.FindElements(By.Id("datesToUpdateText")).ToArray();
        public IEnumerable<NgWebElement> DatesToClearText => Driver.FindElements(By.Id("datesToClearText")).ToArray();
        public NgWebElement UpdateEventAdjustedTo => Driver.FindElement(By.XPath("//label[text()='Adjusted to']/parent::*/parent::*/div[1]/following-sibling::div/span"));

        #endregion EventRuleDetailsModal

        public void SelectImportanceLevel(string text)
        {
            ImportanceLevel.Input.SelectByText(text);
        }

        public IEnumerable<NgWebElement> AttachmentIcons => EventsGrid.FindElements(By.Name("paperclip"));

        public NgWebElement AttachmentPopup => Driver.FindElements(By.ClassName("popover-content")).FirstOrDefault();
    }

    public class AttachmentDevPage : PageObject
    {
        public AttachmentDevPage(NgWebDriver driver) : base(driver)
        {
        }

        public AngularPicklist Case => new AngularPicklist(Driver).ByName("case");
        public KendoGrid CaseViewAttachmentsGrid => new KendoGrid(Driver, "caseViewAttachments");
    }

    public class EditRow : PageObject
    {
        public EditRow(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public ButtonInput EditButton => new ButtonInput(Driver, Container).ByCssSelector("ipx-icon-button[buttonIcon='pencil-square-o']");
        public ButtonInput RevertButton => new ButtonInput(Driver, Container).ByCssSelector("ipx-icon-button[buttonIcon='revert']");
        public DatePicker EventDatepickers => new DatePicker(Driver, "eventDate", Container);
        public DatePicker EventDueDatepickers => new DatePicker(Driver, "eventDueDate", Container);
        public AngularPicklist NamePicklist => new AngularPicklist(Driver, Container).ByName("name");
        public AngularPicklist NameTypePicklist => new AngularPicklist(Driver, Container).ByName("nameTypeValue");
    }

    public class CaseNameTopic : Topic
    {
        const string TopicKey = "namesDefaultGrid";
        const string CloneableTopicKey = "names_";

        public enum ExternalUser
        {
            NameType = 1,
            Name = 2,
            AttentionName = 4
        }

        public enum InternalUser
        {
            NameType = 1,
            DebtorRestrictionIndicator = 2,
            Name = 3,
            AttentionName = 5,
            BillPercentage = 7
        }

        public string CaseNameTopicGridKey { get; set; } = "caseViewNames";

        public CaseNameTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            CaseNameTopicGridKey = CaseNameTopicGridKey + "DefaultGrid";
        }

        public CaseNameTopic(NgWebDriver driver, string topicContextKey) : base(driver, CloneableTopicKey)
        {
            TopicContainerSelector = TopicContainerSelector + "[data-topic-context-key=" + topicContextKey + "]";
            CaseNameTopicGridKey = CaseNameTopicGridKey + topicContextKey;
        }

        public KendoGrid CaseViewNameGrid => new KendoGrid(Driver, CaseNameTopicGridKey);

        public NgWebElement GetInheritanceIcon(int rowIndex, int colIndex)
        {
            return ByCssSelector("ip-inheritance-icon", rowIndex, colIndex);
        }

        public NgWebElement GetDebtorRestrictionFlag(int rowIndex, int colIndex)
        {
            return ByCssSelector("ip-debtor-restriction-flag", rowIndex, colIndex);
        }

        NgWebElement ByCssSelector(string cssSelector, int rowIndex, int columnIndex)
        {
            var elements = CaseViewNameGrid.MasterCell(rowIndex, columnIndex).FindElements(By.CssSelector(cssSelector));
            if (elements == null || !elements.Any())
                return null;
            return elements[0];
        }

        public class DetailSection : PageObject
        {
            public DetailSection(NgWebDriver driver, KendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
            {
                Container = grid.DetailRows[rowIndex];
            }

            public string BillPercentage => Container.FindElements(By.CssSelector(".cn-bill-percentage")).SingleOrDefault()?.Text;

            public string AssignmentDate => Container.FindElements(By.CssSelector(".cn-assignment-date")).SingleOrDefault()?.Text;

            public string CommenceDate => Container.FindElements(By.CssSelector(".cn-commence-date")).SingleOrDefault()?.Text;

            public string CeaseDate => Container.FindElements(By.CssSelector(".cn-cease-date")).SingleOrDefault()?.Text;

            public string Nationality => Container.FindElements(By.CssSelector(".cn-nationality")).SingleOrDefault()?.Text;

            public string Phone => Container.FindElements(By.CssSelector(".cn-phone")).SingleOrDefault()?.Text;

            public string Email => Container.FindElements(By.CssSelector(".cn-email")).SingleOrDefault()?.Text;

            public string Website => Container.FindElements(By.CssSelector(".cn-website")).SingleOrDefault()?.Text;

            public string EmailMailtoHref => Container.FindElements(By.CssSelector(".cn-email a")).SingleOrDefault()?.WithJs()?.GetAttributeValue<string>("href") ?? string.Empty;

            public string Comments => Container.FindElements(By.CssSelector("ip-text-area.cn-remarks")).SingleOrDefault()?.Text;
        }
    }

    public class CaseCriticalDatesTopic : Topic
    {
        const string TopicKey = "criticalDates";

        public CaseCriticalDatesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid CriticalDatesGrid => new AngularKendoGrid(Driver, "caseViewCriticalDates");
    }

    public class CaseAffectedCasesTopic : Topic
    {
        const string TopicKey = "assignedCases";
        public CaseAffectedCasesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid AffectedCasesGrid => new AngularKendoGrid(Driver, "affectedCases");
        public ButtonInput RecordalSteps => new ButtonInput(Driver).ById("recordalSteps");
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalTitle => Driver.Wait().ForVisible(By.CssSelector(".modal-title"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public AngularKendoGrid RecordalStepsGrid => new AngularKendoGrid(Driver, "recordalStepsGrid");
        public AngularKendoGrid RecordalStepElementsGrid => new AngularKendoGrid(Driver, "recordalStepElements");
        public NgWebElement ToggleRecordalStepStatus => Driver.FindElement(By.CssSelector("label[for='recordalStepStatus']"));
        public ButtonInput BtnAffectedCasesFilter => new ButtonInput(Driver).ById("affectedCasesFilter");
        public ButtonInput BtnAddAffectedCases => new ButtonInput(Driver).ById("btnAdd");
        public NgWebElement BtnSaveAffectedCases => Driver.FindElement(By.Id("btSave"));
        public NgWebElement AffectedCasesFilterPanel => Driver.FindElement(By.Id("filterPanel"));
        public NgWebElement BtnApplyFilter => Driver.FindElement(By.XPath("//button[@id='btnFilter']"));
        public NgWebElement BtnOk => Driver.FindElement(By.XPath("//button[contains(text(),'Ok')]"));
        public NgWebElement BtnClearFilter => Driver.FindElement(By.XPath("//button[@id='btnClear']"));
        public NgWebElement ChkBoxRecordalStatusRecorded => Driver.FindElement(By.Id("recorded"));
        public NgWebElement ChkBoxCaseStatusPending => Driver.FindElement(By.Id("pending"));
        public NgWebElement SaveButton => Driver.FindElement(By.XPath("//button[@class='btn btn-icon btn-save']"));
        public NgWebElement CheckBox1 => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/span[1]/ipx-checkbox[1]/div[1]"));
        public NgWebElement CheckBox2 => Driver.FindElement(By.XPath("//tbody/tr[2]/td[2]/span[1]/ipx-checkbox[1]/div[1]"));
        public AngularTextField TxtCaseRef => new AngularTextField(Driver, "caseRef");
        public AngularPicklist PicklistJurisdiction => new AngularPicklist(Driver).ById("jurisdiction");
        public AngularTextField TxtOfficialNo => new AngularTextField(Driver, "officialNo");
        public NgWebElement ChkBoxStep1 => Driver.FindElement(By.Id("1"));
        public AngularTextField TxtStepNo => new AngularTextField(Driver, "stepNumber");
        public AngularPicklist PicklistPropertyType => new AngularPicklist(Driver).ById("propertyType");
        public AngularPicklist PicklistCurrentOwner => new AngularPicklist(Driver).ById("currentOwner");
        public AngularKendoGrid SetAgentsGrid => new AngularKendoGrid(Driver, "setAgentGrid");
        public AngularKendoGrid RequestRecordalGrid => new AngularKendoGrid(Driver, "requestRecordalGrid");
        public AngularKendoGrid RejectRecordalGrid => new AngularKendoGrid(Driver, "rejectRecordalGrid");
        public AngularPicklist AgentPicklist => new AngularPicklist(Driver).ByName("agent");
        public AngularCheckbox IsCaseNameCheckbox => new AngularCheckbox(Driver).ByName("isCaseName");
        public DatePicker TxtRequestDate => new DatePicker(Driver, "requestDate", Container);
        public NgWebElement Error => Driver.FindElement(By.ClassName("cpa-icon-exclamation-triangle"));
        public NgWebElement Warning => Driver.FindElement(By.ClassName("cpa-icon-exclamation-circle"));
        public NgWebElement SetAgentMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_set-agent']"));
        public NgWebElement RequestRecordalMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_request-recordal']"));
        public NgWebElement RejectRecordalMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_reject-recordal']"));
        public NgWebElement ApplyRecordalMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_apply-recordal']"));
        public NgWebElement ShowNextStepsToggle => Driver.FindElement(By.Id("showNextSteps"));
        public NgWebElement DeleteAffectedCasesMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_delete-affectedCases']"));

        public NgWebElement ClearAgentMenu => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_clear-affectedCaseAgent']"));
    }

    public class CaseDesignElementsTopic : Topic
    {
        const string TopicKey = "designElement";

        public CaseDesignElementsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid DesignElementsGrid => new AngularKendoGrid(Driver, "designElements");
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalApply => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);
        public AngularCheckbox AddAnotherCheckbox => new AngularCheckbox(Driver).ByName("addAnother");
        public AngularTextField FirmElementCaseRef => new AngularTextField(Driver, "firmElementCaseRef");
        public AngularTextField ClientElementCaseRef => new AngularTextField(Driver, "clientElementCaseRef");
        public AngularTextField ElementOfficialNo => new AngularTextField(Driver, "elementOfficialNo");
        public AngularTextField RegistrationNo => new AngularTextField(Driver, "registrationNo");
        public AngularTextField NoOfViews => new AngularTextField(Driver, "noOfViews");
        public AngularTextField ElementDescription => new AngularTextField(Driver, "elementDescription");
        public NgWebElement RenewCheckBox => Driver.FindElement(By.Name("renew")).FindElement(By.TagName("input"));
        public DatePicker StopRenewDate => new DatePicker(Driver, "stopRenewDate", Container);
        public AngularPicklist ImagePicklist => new AngularPicklist(Driver).ByName("images");
        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".cpa-icon-revert")).GetParent();
        public NgWebElement ExpandCollapseIcon => Driver.FindElement(By.Id("expandCollapseAll"));

        public void Revert()
        {
            RevertButton.ClickWithTimeout();
        }
    }

    public class CaseFileLocationsTopic : Topic
    {
        const string TopicKey = "fileLocations";

        public CaseFileLocationsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid FileLocationsGrid => new AngularKendoGrid(Driver, "fileLocations");
        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".cpa-icon-revert")).GetParent();
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalTitle => Driver.Wait().ForVisible(By.CssSelector(".modal-title"));
        public NgWebElement ModalApply => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ValidationTitle => Driver.FindElement(By.XPath("//h2[@id='modalErrorLabel']"));
        public NgWebElement ValidationOkButton => Driver.FindElement(By.XPath("//button[@name='cancel']"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);
        public AngularCheckbox AddAnotherCheckbox => new AngularCheckbox(Driver).ByName("addAnother");
        public AngularTextField BarCode => new AngularTextField(Driver, "barCode");
        public DatePicker WhenMovedDate => new DatePicker(Driver, "whenMoved", Container);
        public AngularTimePicker WhenMovedTime => new AngularTimePicker(Driver, Container);
        public AngularPicklist FileLocationPicklist => new AngularPicklist(Driver).ByName("fileLocation");
        public AngularPicklist FilePartPicklist => new AngularPicklist(Driver).ByName("filePart");
        public AngularPicklist IssuedByPicklist => new AngularPicklist(Driver).ByName("issuedBy");

        public NgWebElement AddPicklistButton => Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle"));
        public NgWebElement ClosePicklist => Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();

        public void Revert()
        {
            RevertButton.ClickWithTimeout();
        }
    }

    public class CaseFileLocationsHistory : PageObject
    {
        const string TopicKey = "fileLocations";

        public CaseFileLocationsHistory(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid FileLocationsGrid => new AngularKendoGrid(Driver, "fileLocations");
        public AngularKendoGrid LastLocationGrid => new AngularKendoGrid(Driver, "lastLocation");
        public NgWebElement HistoryButton => Driver.FindElement(By.CssSelector(".cpa-icon-history"));
        public NgWebElement HistoryIconButton => Driver.FindElement(By.XPath("//a[@class='cpa-icon text-grey-highlight cpa-icon-history']"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement HistoryModal => Driver.Wait().ForVisible(By.XPath("//ipx-close-button[@id='lastLocationModal']"));
        public NgWebElement HistoryModalTitle => Driver.Wait().ForVisible(By.XPath("//h2[contains(text(),'Last Location')]"));
        public NgWebElement ModalTitle => Driver.Wait().ForVisible(By.CssSelector(".modal-title"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));

        public void ShowHistory()
        {
            HistoryButton.ClickWithTimeout();
        }

        public void CloseHistoryModal()
        {
            ModalCancel.ClickWithTimeout();
        }
    }

    public class DesignElementsImageDetail : PageObject
    {
        readonly NgWebElement _detail;

        public DesignElementsImageDetail(NgWebDriver driver, NgWebElement detailRow) : base(driver, detailRow)
        {
            _detail = detailRow;
        }

        public NgWebElement Image => _detail.FindElement(By.XPath("//img[@class='case-image-thumbnail']"));
    }

    public class CaseDmsTopic : Topic
    {
        const string TopicKey = "dms";

        public CaseDmsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public TreeView DirectoryTreeView => new TreeView(Driver);
        public DocumentGrid Documents => new DocumentGrid(Driver);
    }

    public class CaseClassTopic : Topic
    {
        const string TopicKey = "classes";

        public CaseClassTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            TopicContainerSelector = $"[data-topic-key^='{TopicKey}']";
        }

        public KendoGrid CaseViewClassesGrid => new KendoGrid(Driver, "caseViewClasses");

        public string ClassDetailsCellValue(NgWebDriver driver, int row, int column)
        {
            return driver.FindElement(By.XPath("//div[@id='caseview-class-texts']//table//tbody//tr[" + row + "]//td[" + column + "]//span")).Text;
        }

        public NgWebElement CaseClassesExpandIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.XPath("//div[@id='caseViewClasses']//a[contains(@class,'k-icon no-underline ng-scope k-i-collapse')]"));
        }
    }

    public class CaseTextTopic : Topic
    {
        const string TopicKey = "caseText";

        const string CloneableTopicKey = "caseText_";

        public string CaseTextTopicGridKey { get; set; } = "caseViewCaseTexts";

        public CaseTextTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public CaseTextTopic(NgWebDriver driver, string topicContextKey) : base(driver, CloneableTopicKey)
        {
            TopicContainerSelector = TopicContainerSelector + "[data-topic-context-key=" + topicContextKey + "]";
            CaseTextTopicGridKey = CaseTextTopicGridKey + topicContextKey;
        }

        public KendoGrid CaseTextGrid => new KendoGrid(Driver, CaseTextTopicGridKey);
    }

    public class CaseTextHistoryModal : ModalBase
    {
        const string Id = "CaseTextHistory";

        public CaseTextHistoryModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public KendoGrid GoodsServicesGrid => new KendoGrid(Driver, "caseViewCaseTextHistory");

        public string IrnLabelText => Modal.FindElement(By.Id("irn")).Text;

        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }
    }

    public class DesignatedJurisdictionTopic : Topic
    {
        public enum ExternalUser
        {
            Expander,
            NoteIcon,
            Jurisdication,
            DesignatedStatus,
            OfficialNumber,
            CaseStatus,
            ClientReference,
            InternalReference,
            Classes,
            PriorityDate,
            IsExtensionState,
        }

        public enum InternalUser
        {
            Expander,
            FileIcon,
            NoteIcon,
            Jurisdication,
            DesignatedStatus,
            OfficialNumber,
            CaseStatus,
            InternalReference,
            Classes,
            PriorityDate,
            IsExtensionState,
            InstructorReference,
            AgentReference
        }

        public enum ClassesColumns
        {
            Classes,
            Language,
            GoodsAndServices
        }

        const string TopicKey = "designatedCountries_";

        public DesignatedJurisdictionTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public KendoGrid DesignatedJurisdictionGrid => new KendoGrid(Driver, "caseview-designations");
        public KendoGrid DesignatedJurisdictionClassesGrid => new KendoGrid(Driver, "caseview-designations-classes");

        public ColumnSelection ColumnSelector => new ColumnSelection(Driver).ById("caseViewDesignationsColumnSelection");
        internal MultiSelectGridFilter JurisdictionFilter => new MultiSelectGridFilter(Driver, "caseview-designations", "jurisdiction");
        internal MultiSelectGridFilter DesignatedStatusFilter => new MultiSelectGridFilter(Driver, "caseview-designations", "designatedStatus");
        internal MultiSelectGridFilter CaseStatusFilter => new MultiSelectGridFilter(Driver, "caseview-designations", "caseStatus");
    }

    public class CaseRelatedCasesTopic : Topic
    {
        public enum ExternalUser
        {
            Expansion,
            Direction,
            Relationship,
            ClientRef,
            InternalRef,
            OfficialNumber,
            Jurisdiction,
            EventDate,
            Status,
            Classes
        }

        public enum InternalUser
        {
            Expansion,
            FileIcon,
            Direction,
            Relationship,
            InternalRef,
            OfficialNumber,
            Jurisdiction,
            EventDate,
            Status,
            Classes
        }

        const string TopicKey = "relatedCases_";

        public CaseRelatedCasesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid RelatedCasesGrid => new AngularKendoGrid(Driver, "caseViewRelatedCases");
    }

    public class RelatedCaseOtherDetail : PageObject
    {
        readonly NgWebElement _detail;

        public RelatedCaseOtherDetail(NgWebDriver driver, NgWebElement detailRow) : base(driver, detailRow)
        {
            _detail = detailRow;
        }

        public string Title => _detail.FindElement(By.CssSelector(".rc-title")).Text;
        public string EventDescription => _detail.FindElement(By.CssSelector(".rc-event-description")).Text;
        public string Cycle => _detail.FindElement(By.CssSelector(".rc-event-cycle")).Text;
    }

    public class CaseEventsTopic : Topic
    {
        const string TopicKey = "events";

        public CaseEventsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid OccurredDatesGrid => new AngularKendoGrid(Driver, "caseViewEventsoccurred");

        public AngularKendoGrid DueDatesGrid => new AngularKendoGrid(Driver, "caseViewEventsdue");

        public AngularDropdown OccurredImportanceLevel => new AngularDropdown(Driver).ById("importanceLeveloccurred");
        public AngularDropdown DueImportanceLevel => new AngularDropdown(Driver).ById("importanceLeveldue");

        public void SelectOccurredImportanceLevel(string text)
        {
            OccurredImportanceLevel.Input.SelectByText(text);
        }

        public void SelectDueImportanceLevel(string text)
        {
            DueImportanceLevel.Input.SelectByText(text);
        }
    }

    public class OfficialNumbersTopic : Topic
    {
        const string TopicKey = "officialNumbers_0";

        public OfficialNumbersTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularKendoGrid IpOfficeNumbers => new AngularKendoGrid(Driver, "caseViewOfficialNumbers-ipOffice");

        public AngularKendoGrid OtherNumbers => new AngularKendoGrid(Driver, "caseViewOfficialNumbers-other");
    }

    public class CaseWebLinks : PageObject
    {
        public CaseWebLinks(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public IEnumerable<string> Groups()
        {
            return Container.FindElements(By.TagName("h3")).Select(_ => _.Text);
        }

        public IEnumerable<string> Links(string groupText)
        {
            return Container.FindElements(By.TagName("h3")).First(_ => _.Text == groupText).GetParent().FindElements(By.TagName("a")).Select(_ => _.GetAttribute("href"));
        }

        public IEnumerable<string> Links()
        {
            return Container.FindElements(By.TagName("a")).Select(_ => _.GetAttribute("href"));
        }
    }

    public class EfilingTopic : Topic
    {
        const string TopicKey = "eFiling";

        public EfilingTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            TopicContainerSelector = $"[data-topic-key^='{TopicKey}']";
        }

        public KendoGrid EfilingGrid => new KendoGrid(Driver, "caseview-efiling");
        public KendoGrid EfilingFilesGrid => new KendoGrid(Driver, "eFilingPackageFiles");
        public ColumnSelection ColumnSelector => new ColumnSelection(Driver).ById("caseViewEFilingColumnSelection");
    }

    public class EfilingHistoryDialog : ModalBase
    {
        public EfilingHistoryDialog(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public KendoGrid EfilingHistoryGrid => new KendoGrid(Driver, "eFilingHistory");

        public bool IsVisible()
        {
            return Modal.WithJs().IsVisible();
        }
    }

    public class RenewalTopic : Topic
    {
        const string TopicKey = "caseRenewals_";

        public RenewalTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement CaseStatus => Driver.FindElement(By.Name("caseStatus"));

        public NgWebElement RenewalStatus => Driver.FindElement(By.Name("renewalStatus"));

        public NgWebElement NextRenewalDate => Driver.FindElement(By.Name("nextRenewalDate"));

        public NgWebElement RenewalType => Driver.FindElement(By.Name("renewalType"));

        public NgWebElement RenewalYear => Driver.FindElement(By.Name("renewalYear"));

        public NgWebElement ExtendedRenewalYears => Driver.FindElement(By.Name("extendedRenewalYears"));

        public AngularCheckbox ReportToCpaCheckbox => new AngularCheckbox(Driver).ByName("chkReportToCpa");

        public NgWebElement StartPayingDivElement => Driver.FindElement(By.Id("dvStartPaying"));

        public NgWebElement Notes => Driver.FindElements(By.CssSelector("ipx-text-field[name='renewalNotes'] textarea")).First();

        public TableElement ReleventDates => new TableElement(Driver, "relevantDates");

        public TableElement Instructions => new TableElement(Driver, "standingInstructions");

        public KendoGrid RenewalNames => new KendoGrid(Driver, "renewalNames");

        public class DetailSection : PageObject
        {
            public DetailSection(NgWebDriver driver, KendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
            {
                Container = grid.DetailRows[rowIndex];
            }

            public string Address => Container.FindElements(By.CssSelector("ipx-text-area.cn-address")).SingleOrDefault()?.Text;
        }

        public string IpPlatformRenewLink => Driver.FindElements(By.Name("renewLink")).FirstOrDefault()?.GetAttribute("href");

        public class TableElement
        {
            readonly NgWebElement _table;

            public TableElement(NgWebDriver driver, string name)
            {
                _table = driver.FindElement(By.Name(name));
            }

            public (string firstColumn, string secondColumn) GetValueForRow(int no)
            {
                var row = _table.FindElements(By.TagName("tr")).ElementAt(no);
                var columns = row.FindElements(By.TagName("td"));

                var value1 = GetText(columns[0]);
                var value2 = GetText(columns[1]);

                return (value1, value2);
            }

            string GetText(NgWebElement element)
            {
                var spans = element.FindElements(By.TagName("span"));
                return spans.Count != 0 ? spans[0].Text : element.Text;
            }
        }
    }

    public class StandingInstructionsTopic : Topic
    {
        const string TopicKey = "caseStandingInstructions_";

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "standingInstructions");

        public StandingInstructionsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            TopicContainerSelector = $"[data-topic-key^='{TopicKey}']";
        }

        public new void NavigateTo()
        {
            Driver.FindElement(By.CssSelector("[data-topic-ref^=" + TopicKey + "]")).TryClick();
            Thread.Sleep(500);
        }

        public InstructionDetails GetDetailsFor(int rowIndex)
        {
            var detailsRow = Grid.DetailRows[rowIndex];
            var result = new InstructionDetails
            {
                Adjustment = detailsRow.FindElements(By.Id("adjustment")).SingleOrDefault()?.Text,
                StandingInstructionText = detailsRow.FindElements(By.Id("standingInstructionText")).SingleOrDefault()?.Text,
                AdjustDay = detailsRow.FindElements(By.Id("adjustDay")).SingleOrDefault()?.Text,
                AdjustStartMonth = detailsRow.FindElements(By.Id("adjustStartMonth")).SingleOrDefault()?.Text
            };
            return result;
        }
    }

    public class CustomContentTopic : Topic
    {
        const string TopicKey = "caseCustomContent_";

        public CustomContentTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public new void NavigateTo(int index)
        {
            Driver.FindElements(By.CssSelector("[data-topic-ref^=" + TopicKey + "]"))[index].TryClick();
            Thread.Sleep(500);
        }

        public NgWebElement CustomContentTitle(string title)
        {
            return Driver.FindElement(By.XPath("//h1[contains(text(),'" + title + "')]"));
        }
    }

    public class CaseChecklistTopic : Topic
    {
        const string TopicKey = "checklist_";

        public CaseChecklistTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public new void NavigateTo(int index)
        {
            Driver.FindElements(By.CssSelector("[data-topic-ref^=" + TopicKey + "]"))[index].TryClick();
            Thread.Sleep(500);
        }

        public NgWebElement CaseChecklists => Driver.FindElement(By.Name("caseChecklists"));
        public AngularDropdown ChecklistType => new AngularDropdown(Driver).ByName("ChecklistType");

        public AngularKendoGrid CaseChecklistGrid => new AngularKendoGrid(Driver, "checklist");

        // public ButtonInput RevertButton => new ButtonInput(Driver, Container).ByTagName("ipx-revert-button");
        public ButtonInput RevertButton => new ButtonInput(Driver).ByCssSelector("ipx-revert-button button");

        // public ButtonInput SaveButton => new ButtonInput(Driver, Container).ByTagName("ipx-save-button");
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
        public ChecklistRegenerationModal RegenerationModal => new ChecklistRegenerationModal(Driver);
    }

    public class EditChecklistRow : PageObject
    {
        public EditChecklistRow(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public AngularCheckbox YesAnswer => new AngularCheckbox(Driver, Container).ByName("yesAnswer");
        public AngularCheckbox NoAnswer => new AngularCheckbox(Driver, Container).ByName("noAnswer");
        public IpxTextField Text => new IpxTextField(Driver, Container).ByName("textValue");
        public IpxNumericField CountValue => new IpxNumericField(Driver, Container).ByName("countValue");
        public DatePicker Date => new DatePicker(Driver, "dateValue", Container);
        public IpxNumericField AmountValue => new IpxNumericField(Driver, Container).ByName("amountValue");
        public AngularPicklist StaffName => new AngularPicklist(Driver, Container).ByName("staffName");
    }

    public class ChecklistRegenerationModal : ModalBase
    {
        const string Id = "checklistRegenerationModal";

        public ChecklistRegenerationModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Proceed()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Proceed')]")).ClickWithTimeout();
        }

        public void Cancel()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]")).ClickWithTimeout();
        }
    }

    public class ContextMenuAttachment
    {
        readonly NgWebDriver _driver;
        public Action Edit;
        public Action Delete;

        public ContextMenuAttachment(NgWebDriver driver)
        {
            _driver = driver;

            Edit = () => ClickContextMenu(EditMenu);
            Delete = () => ClickContextMenu(DeleteMenu);
        }

        public NgWebElement EditMenu => new AngularKendoGridContextMenu(_driver).Option("edit");

        public NgWebElement DeleteMenu => new AngularKendoGridContextMenu(_driver).Option("delete");

        static void ClickContextMenu(NgWebElement task)
        {
            task.FindElement(By.CssSelector("span:nth-child(2)")).WithJs().Click();
        }
    }
}

public class InstructionDetails
{
    public string Adjustment { get; set; }

    public string StandingInstructionText { get; set; }

    public string AdjustDay { get; set; }

    public string AdjustStartMonth { get; set; }
}

public class ImagesTopic : Topic
{
    const string TopicKey = "images_";

    public ImagesTopic(NgWebDriver driver) : base(driver, TopicKey)
    {
    }

    public IEnumerable<ImageObject> Images => Driver.FindElements(By.ClassName("space-images")).Select(_ => new ImageObject(Driver, _));
    public NgWebElement ShowAllButton => Driver.FindElement(By.Id("btnLoadMoreImages"));
    public NgWebElement ImageDesc(NgWebElement image) => image.FindElement(By.Id("imageDesc"));
}

public class ImageObject : PageObject
{
    public string Description => FindElement(By.ClassName("imageDesc")).Text;
    public string Header => FindElement(By.TagName("h5")).Text;
    public NgWebElement DisplayedImage => FindElement(By.TagName("img"));
    public NgWebElement FirmElement => FindElement(By.TagName("span"));

    public ImageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
    {
    }
}