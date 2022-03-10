using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    internal class EventControlPage : DetailPage
    {
        public EventControlPage(NgWebDriver driver) : base(driver)
        {
            Header = new HeaderPageObject(driver);
            //Overview = new OverviewTopic(driver);
            DueDateCalc = new DueDateCalcTopic(driver);
            EventOccurrence = new EventOccurrenceTopic(driver);
            DateLogicRules = new DateLogicRulesTopic(driver);
            SyncEvent = new SyncEventTopic(driver);
            StandingInstruction = new StandingInstructionTopic(driver);
            DateComparison = new DateComparisonTopic(driver);
            ChangeStatus = new ChangeStatusTopic(driver);
            Report = new ReportTopic(driver);
            Charges = new ChargesTopic(driver);
            ChangeAction = new ChangeActionTopic(driver);
            NameChange = new NameChangeTopic(driver);
            SatisfyingEvents = new SatisfyingEventsTopic(driver);
            DesignatedJurisdictions = new DesignatedJurisdictionsTopic(driver);
            EventsToClear = new EventsToClearTopic(driver);
            Reminders = new RemindersTopic(driver);
            Documents = new DocumentsTopic(driver);
            EventsToClear = new EventsToClearTopic(driver);
            EventsToUpdate = new EventsToUpdateTopic(driver);
            DateLogicRules = new DateLogicRulesTopic(driver);
            PtaDelay = new PtaDelayTopic(driver);
            EventInheritanceConfirmation = new EventInheritanceConfirmation(driver);
            ChangeDueDateRespConfirm = new ChangeDueDateRespConfirm(driver);
            ResetEntryInheritanceConfirmation = new ResetEntryInheritanceConfirmation(driver);
        }

        public EventsToUpdateTopic EventsToUpdate { get; set; }

        public EventsToClearTopic EventsToClear { get; set; }

        public DocumentsTopic Documents { get; }

        public RemindersTopic Reminders { get; }

        public SatisfyingEventsTopic SatisfyingEvents { get; }

        public DesignatedJurisdictionsTopic DesignatedJurisdictions { get; }

        public NameChangeTopic NameChange { get; }

        public ChangeActionTopic ChangeAction { get; }

        public ChargesTopic Charges { get; }

        public HeaderPageObject Header { get; }

        public OverviewTopic Overview => new OverviewTopic(Driver);

        public DueDateCalcTopic DueDateCalc { get; }

        public EventOccurrenceTopic EventOccurrence { get; }

        public DateLogicRulesTopic DateLogicRules { get; }

        public SyncEventTopic SyncEvent { get; }

        public StandingInstructionTopic StandingInstruction { get; }

        public DateComparisonTopic DateComparison { get; }

        public ChangeStatusTopic ChangeStatus { get; }

        public ReportTopic Report { get; set; }

        public PtaDelayTopic PtaDelay { get; set; }

        public EventInheritanceConfirmation EventInheritanceConfirmation { get; set; }

        public ChangeDueDateRespConfirm ChangeDueDateRespConfirm { get; set; }

        public ResetEntryInheritanceConfirmation ResetEntryInheritanceConfirmation { get; set; }

        public bool IsPermissionAlertDisplayed => Driver.FindElement(By.CssSelector("ip-inline-alert")).Displayed;

        public new NgWebElement LevelUpButton => Driver.FindElements(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'")).Last();

        public InheritanceDeleteModal InheritanceDeleteModal => new InheritanceDeleteModal(Driver);

        public EventsForCaseModal EventsForCaseModal => new EventsForCaseModal(Driver);

        public NewStatusModal NewStatusModal => new NewStatusModal(Driver);

        public void ActivateActionsTab()
        {
            Driver.FindElements(By.CssSelector("div.topics > .topic-menu ul.nav-tabs a[data-toggle=tab] span[translate='sections.actions']")).Last().ClickWithTimeout();
        }

        public EventControlActions Actions => new EventControlActions(Driver);

        public class HeaderPageObject : PageObject
        {
            public HeaderPageObject(NgWebDriver driver) : base(driver)
            {
            }

            public string CriteriaNumber => Driver.FindElement(By.CssSelector(".event-control-header .criteria-number")).Text;

            public string EventNumber => Driver.FindElement(By.CssSelector(".event-control-header .event-number")).Text;

            public string EventDescription => Driver.FindElement(By.CssSelector(".event-control-header .event-desc")).Text;

            public bool IsInherited => Driver.FindElements(By.CssSelector(".event-control-header .cpa-icon-inheritance, .event-control-header .cpa-icon-inheritance-partial")).Any();
        }

        internal class EventControlActions : PageObject
        {
            public EventControlActions(NgWebDriver driver) : base(driver)
            {
            }

            public void ResetInheritance()
            {
                new PageAction(Driver, "resetInheritance").Click();
            }

            public void BreakInheritance()
            {
                new PageAction(Driver, "breakInheritance").Click();
            }
        }

        public class OverviewTopic : Topic
        {
            const string TopicKey = "overview";

            public OverviewTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public NgWebElement EventNumber => TopicContainer.FindElement(By.CssSelector("[ng-bind='::vm.eventId']"));

            public NgWebElement BaseEvent => TopicContainer.FindElement(By.CssSelector("[ng-bind='vm.baseDescription']"));

            public IpTextField EventDescription => new IpTextField(Driver).ByName("description");

            public IpTextField MaxCycles => new IpTextField(Driver).ByLabel(".maxCycles");

            public NgWebElement UnlimitedCycles => TopicContainer.FindElement(By.CssSelector("ip-checkbox label"));

            public DropDown ImportanceLevel => new DropDown(Driver).ByName("importanceLevel");

            public IpRadioButton NameRadio => new IpRadioButton(Driver).ByLabel(".name");

            public IpRadioButton NameTypeRadio => new IpRadioButton(Driver).ByLabel(".nameType");

            public IpRadioButton NotApplicableRadio => new IpRadioButton(Driver).ByLabel(".notApplicable");

            public PickList Name => new PickList(Driver).ByName($".topic-container[data-topic-key='{TopicKey}']", "name");

            public PickList NameType => new PickList(Driver).ByName($".topic-container[data-topic-key='{TopicKey}']", "nameType");

            public TextField Notes => new TextField(Driver, "notes");

            public NgWebElement EditBaseEvent => TopicContainer.FindElement(By.CssSelector("[ng-click='vm.onEditBaseEvent()']"));
        }

        public class EventOccurrenceTopic : Topic
        {
            public EventOccurrenceTopic(NgWebDriver driver) : base(driver, "eventOccurrence")
            {
            }

            public IpRadioButton OnDueDateCheckBox => new IpRadioButton(Driver, TopicContainer).ByName("onDueDateOption");
            public Checkbox WhenAnotherCaseExists => new Checkbox(Driver, TopicContainer).ByName("whenAnotherCaseExists");
            public PickList Office => new PickList(Driver, TopicContainer).ByName("office");
            public PickList CaseType => new PickList(Driver, TopicContainer).ByName("caseType");
            public PickList Jurisdiction => new PickList(Driver, TopicContainer).ByName("jurisdiction");
            public PickList PropertyType => new PickList(Driver, TopicContainer).ByName("propertyType");
            public PickList CaseCategory => new PickList(Driver, TopicContainer).ByName("caseCategory");
            public PickList SubType => new PickList(Driver, TopicContainer).ByName("subType");
            public PickList Basis => new PickList(Driver, TopicContainer).ByName("basis");

            public Checkbox MatchOffice => new Checkbox(Driver, TopicContainer).ByName("matchOffice");
            public Checkbox MatchCaseType => new Checkbox(Driver, TopicContainer).ByName("matchCaseType");
            public Checkbox MatchJurisdiction => new Checkbox(Driver, TopicContainer).ByName("matchJurisdiction");
            public Checkbox MatchPropertyType => new Checkbox(Driver, TopicContainer).ByName("matchPropertyType");
            public Checkbox MatchCaseCategory => new Checkbox(Driver, TopicContainer).ByName("matchCaseCategory");
            public Checkbox MatchSubType => new Checkbox(Driver, TopicContainer).ByName("matchSubType");
            public Checkbox MatchBasis => new Checkbox(Driver, TopicContainer).ByName("matchBasis");

            public MatchNamesGrid MatchNames => new MatchNamesGrid(Driver, "matchNames");

            public PickList Events => new PickList(Driver, TopicContainer).ByName("eventsExist");
        }

        public class MatchNamesGrid : KendoGrid
        {
            public MatchNamesGrid(NgWebDriver driver, string id) : base(driver, id)
            {
            }

            public MatchNamesGrid(NgWebDriver driver, string id, string bulkMenuContext) : base(driver, id, bulkMenuContext)
            {
            }

            public PickList NameType(int row)
            {
                return new PickList(Driver, MasterRows[row]).ByName("nameType");
            }

            public PickList CurrentCaseNameType(int row)
            {
                return new PickList(Driver, MasterRows[row]).ByName("caseNameType");
            }

            public Checkbox MustExists(int row)
            {
                return new Checkbox(Driver, MasterRows[row]).ByModel("dataItem.mustExist");
            }

            public bool IsInherited(int row)
            {
                return MasterRows[row].FindElement(By.CssSelector("ip-inheritance-icon")).Displayed;
            }
        }

        public class DueDateCalcTopic : Topic
        {
            public DueDateCalcTopic(NgWebDriver driver) : base(driver, "dueDateCalc")
            {
                EarliestDateToUse = new IpRadioButton(driver, TopicContainer).ByLabel(".formElements.earliest");
                LatestDateToUse = new IpRadioButton(driver, TopicContainer).ByLabel(".formElements.latest");
                SaveDueDateYes = new IpRadioButton(driver, TopicContainer).ByModel("vm.settings.isSaveDueDate").ByLabel(".formElements.yes");
                SaveDueDateNo = new IpRadioButton(driver, TopicContainer).ByModel("vm.settings.isSaveDueDate").ByLabel(".formElements.no");
                RecalcEventDate = new Checkbox(driver, TopicContainer).ByModel("vm.settings.recalcEventDate");
                ExtendDueDateYes = new IpRadioButton(driver, TopicContainer).ByModel("vm.settings.extendDueDate").ByLabel(".formElements.yes");
                ExtendDueDateNo = new IpRadioButton(driver, TopicContainer).ByModel("vm.settings.extendDueDate").ByLabel(".formElements.no");
                ExtendDueDate = new TextDropDownGroup(driver, TopicContainer).ByLabel(".formElements.extendDueDateBy");
                SuppressDueDateCalc = new Checkbox(driver, TopicContainer).ByModel("vm.settings.doNotCalculateDueDate");
            }

            public KendoGrid Grid => new KendoGrid(Driver, "dueDateCalcResults");
            public int GridRowsCount => Grid.Rows.Count;

            public string FirstCycle => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "Cycle");

            public string FirstJurisdiction => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "Jurisdiction");

            public string FirstOperator => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "Operator");

            public string FirstPeriod => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "Period");

            public string Event => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "Event");

            public string FirstFromTo => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, "From/To");

            public string FirstRelativeCycle => new KendoGrid(Driver, "dueDateCalcResults").CellText(0, 8);

            public bool FirstMustExist
            {
                get
                {
                    var cell = new KendoGrid(Driver, "dueDateCalcResults").Cell(0, "Must Exist");

                    return new Checkbox(Driver, cell).ByTagName().IsChecked;
                }
            }

            public IpRadioButton EarliestDateToUse { get; set; }
            public IpRadioButton LatestDateToUse { get; set; }

            public IpRadioButton SaveDueDateYes { get; set; }
            public IpRadioButton SaveDueDateNo { get; set; }

            public IpRadioButton ExtendDueDateYes { get; set; }
            public IpRadioButton ExtendDueDateNo { get; set; }
            public TextDropDownGroup ExtendDueDate { get; set; }

            public Checkbox RecalcEventDate { get; set; }
            public Checkbox SuppressDueDateCalc { get; set; }

            public string ExtendDueDateUnit
            {
                get
                {
                    var val = ExtendDueDate.OptionText;

                    return val.Contains(":") ? val.Split(':')[1] : val;
                }
            }
        }

        public class DateLogicRulesTopic : Topic
        {
            const string TopicKey = "dateLogic";
            const string GridId = "dateLogicRules";

            public DateLogicRulesTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public KendoGrid Grid => new KendoGrid(Driver, GridId);

            public string AppliesTo => Grid.CellText(0, "Applies to");
            public string Operator => Grid.CellText(0, "Operator");
            public string CompareEvent => Grid.CellText(0, "Comparison Event");
            public string Relationship => Grid.CellText(0, "Case Relationship");
        }

        public class SyncEventTopic : Topic
        {
            public SyncEventTopic(NgWebDriver driver) : base(driver, "syncEventDate")
            {
                SameCaseOption = new IpRadioButton(driver, TopicContainer).ByLabel(".sameCase");
                RelatedCaseOption = new IpRadioButton(driver, TopicContainer).ByLabel(".relatedCase");
                NotApplicableOption = new IpRadioButton(driver, TopicContainer).ByLabel(".notApplicable");
                SameCaseUseEvent = new PickList(driver).ByName(TopicContainerSelector + " [ng-form=sameCase]", "event");
                SameCaseDateAdjustment = new DropDown(driver, TopicContainer.FindElement(By.CssSelector("[ng-form=sameCase]"))).ByName("adjustment");
                RelatedCaseUseEvent = new PickList(driver).ByName(TopicContainerSelector + " [ng-form=relatedCase]", "event");
                RelatedCaseDateAdjustment = new DropDown(driver, TopicContainer.FindElement(By.CssSelector("[ng-form=relatedCase]"))).ByName("adjustment");
                Relationship = new PickList(driver).ByName(TopicContainerSelector, "relationship");
                CycleUseRelatedCaseEvent = new IpRadioButton(driver, TopicContainer).ByLabel(".useRelatedCaseEvent");
                CycleUseCaseRelationship = new IpRadioButton(driver, TopicContainer).ByLabel(".useCaseRelationship");
                SyncOfficialNumber = new PickList(driver).ByName(TopicContainerSelector, "numberType");
            }

            public IpRadioButton SameCaseOption { get; set; }
            public IpRadioButton RelatedCaseOption { get; set; }
            public IpRadioButton NotApplicableOption { get; set; }

            public PickList SameCaseUseEvent { get; set; }
            public DropDown SameCaseDateAdjustment { get; set; }
            public PickList RelatedCaseUseEvent { get; set; }
            public DropDown RelatedCaseDateAdjustment { get; set; }

            public PickList Relationship { get; set; }
            public IpRadioButton CycleUseRelatedCaseEvent { get; set; }
            public IpRadioButton CycleUseCaseRelationship { get; set; }
            public PickList SyncOfficialNumber { get; set; }
        }

        public class StandingInstructionTopic : Topic
        {
            const string TopicKey = "standingInstruction";

            public StandingInstructionTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public DropDown RequiredCharacteristic => new DropDown(Driver, TopicContainer).ByLabel(".standingInstruction.requiredCharacteristic");
            public PickList InstructionType => new PickList(Driver).ByName($".topic-container[data-topic-key='{TopicKey}']", "instructionType");

            public void SelectInstructionTypeByCode(string code)
            {
                InstructionType.EnterAndSelect(code);
            }

            public void SelectCharacteristicByText(string value)
            {
                RequiredCharacteristic.Input.SelectByText(value);
            }
        }

        public class DateComparisonTopic : Topic
        {
            public DateComparisonTopic(NgWebDriver driver) : base(driver, "dateComparison")
            {
            }

            public bool IsAnySelected => TopicContainer.FindElement(By.CssSelector("ip-radio-button[label='.dateComparison.any'] input")).Selected;

            public bool IsAllSelected => TopicContainer.FindElement(By.CssSelector("ip-radio-button[label='.dateComparison.all'] input")).Selected;

            public IpRadioButton AllDueDateCalcsOption => new IpRadioButton(Driver, TopicContainer).ByLabel(".dateComparison.all");

            public KendoGrid Grid => new KendoGrid(Driver, "dateComparisonResults");
            public int GridRowsCount => Grid.Rows.Count;

            public string FirstInherited => new KendoGrid(Driver, "dateComparisonResults").CellText(0, 1);

            public string EventA => new KendoGrid(Driver, "dateComparisonResults").CellText(0, "Event");
            public string EventAUseDate => new KendoGrid(Driver, "dateComparisonResults").CellText(0, "Use Date");
            public string EventACycle => new KendoGrid(Driver, "dateComparisonResults").CellText(0, "Cycle");

            public string ComparisonOperator => new KendoGrid(Driver, "dateComparisonResults").CellText(0, "Operator");

            public string EventB => new KendoGrid(Driver, "dateComparisonResults").CellText(0, "Compare With");
            public string EventBUseDate => new KendoGrid(Driver, "dateComparisonResults").CellText(0, 7);
            public string EventBCycle => new KendoGrid(Driver, "dateComparisonResults").CellText(0, 8);
        }

        public class SatisfyingEventsTopic : Topic
        {
            public SatisfyingEventsTopic(NgWebDriver driver) : base(driver, "satisfyingEvents")
            {
                Grid = new KendoGrid(Driver, "satisfyingEventsResults");
                EventPicklist = new PickList(Driver).ByName("ip-kendo-grid[data-id='satisfyingEventsResults']", "event");
                RelativeCycleDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='satisfyingEventsResults']", "relativeCycle");
            }

            public KendoGrid Grid { get; set; }

            public int GridRowsCount => Grid.Rows.Count;

            public PickList EventPicklist { get; set; }

            public DropDown RelativeCycleDropDown { get; set; }

            public PickList NewlyAddedEventPicklist()
            {
                //return Driver.FindElements(By.TagName("ip-typeahead[name='event']")).Select(_ => new PickList(Driver, _).ByName("ip-kendo-grid[data-id='satisfyingEventsResults']", "event")).Last();
                return Driver.FindElements(By.CssSelector("ip-workflows-event-control-satisfying-events ip-typeahead")).Select(_ => new PickList(Driver, _).ByName("event")).Last();
            }

            public string GetEventNo(int row)
            {
                return Grid.CellText(row, "Event No.");
            }
        }

        public class DesignatedJurisdictionsTopic : Topic
        {
            public DesignatedJurisdictionsTopic(NgWebDriver driver) : base(driver, "designatedJurisdictions")
            {
                Grid = new KendoGrid(Driver, "selectedJurisdictions");
                StopCalculatingDropDown = new DropDown(driver).ByName("ip-workflows-event-control-designated-jurisdictions", "selectedCountryFlag");
            }

            public KendoGrid Grid { get; set; }

            public int GridRowsCount => Grid.Rows.Count;

            public DropDown StopCalculatingDropDown { get; set; }
        }

        public class ChangeStatusTopic : Topic
        {
            public ChangeStatusTopic(NgWebDriver driver) : base(driver, "changeStatus")
            {
            }

            public PickList Status => new PickList(Driver).ByName(TopicContainerSelector, "changeStatus");

            public PickList CaseStatus => new PickList(Driver).ByName(TopicContainerSelector, "caseStatus");

            public PickList RenewalStatus => new PickList(Driver).ByName(TopicContainerSelector, "renewalStatus");

            public IpTextField UserDefinedStatus => new IpTextField(Driver).ByName("userDefinedStatus");
        }

        public class ReportTopic : Topic
        {
            public ReportTopic(NgWebDriver driver) : base(driver, "report")
            {
                TurnOn = new IpRadioButton(driver, TopicContainer).ByLabel(".turnOn");
                TurnOff = new IpRadioButton(driver, TopicContainer).ByLabel(".turnOff");
                NoChange = new IpRadioButton(driver, TopicContainer).ByLabel(".noChange");
            }

            public IpRadioButton TurnOn { get; set; }

            public IpRadioButton TurnOff { get; set; }

            public IpRadioButton NoChange { get; set; }
        }

        public class RemindersTopic : Topic
        {
            public RemindersTopic(NgWebDriver driver) : base(driver, "reminders")
            {
                Grid = new KendoGrid(Driver, "reminders");
            }

            public KendoGrid Grid { get; }

            public int GridRowsCount => Grid.Rows.Count;

            public string StandardMessage => Grid.CellText(0, 2);
            public bool SendAsEmail => Grid.Cell(0, 3).FindElement(By.TagName("input")).IsChecked();
            public string StartBefore => Grid.CellText(0, 4);
            public string RepeatEvery => Grid.CellText(0, 5);
            public string StopAfter => Grid.CellText(0, 6);
        }

        public class DocumentsTopic : Topic
        {
            public DocumentsTopic(NgWebDriver driver) : base(driver, "documents")
            {
                Grid = new KendoGrid(Driver, "documentsGrid");
            }

            public KendoGrid Grid { get; }

            public int GridRowsCount => new KendoGrid(Driver, "documentsGrid").Rows.Count;

            public string Document => new KendoGrid(Driver, "documentsGrid").CellText(0, 2);

            public string Produce => new KendoGrid(Driver, "documentsGrid").CellText(0, 3);

            public string StartBefore => Grid.CellText(0, 4);

            public string RepeatEvery => Grid.CellText(0, 5);

            public string StopAfter => Grid.CellText(0, 6);

            public string MaxDocuments => Grid.CellText(0, 7);
        }

        public class ChargesTopic : Topic
        {
            const string ChargeOneFormSelector = "[data-form='chargeOne']";
            const string ChargeTwoFormSelector = "[data-form='chargeTwo']";

            public ChargesTopic(NgWebDriver driver) : base(driver, "charges")
            {
                ChargeOne = new ChargeForm(driver, TopicContainer, ChargeOneFormSelector);
                ChargeTwo = new ChargeForm(driver, TopicContainer, ChargeTwoFormSelector);
            }

            public ChargeForm ChargeOne { get; }

            public ChargeForm ChargeTwo { get; }
        }

        public class ChangeActionTopic : Topic
        {
            public ChangeActionTopic(NgWebDriver driver) : base(driver, "changeAction")
            {
                OpenAction = new PickList(driver).ByName(TopicContainerSelector, "openAction");
                CloseAction = new PickList(driver).ByName(TopicContainerSelector, "closeAction");
                RelativeCycle = new DropDown(driver, TopicContainer).ByName("relativeCycle");
            }

            public PickList OpenAction { get; set; }

            public PickList CloseAction { get; set; }
            public DropDown RelativeCycle { get; set; }
        }

        public class EventsToClearTopic : Topic
        {
            public EventsToClearTopic(NgWebDriver driver) : base(driver, "eventsToClear")
            {
                Grid = new KendoGrid(Driver, "eventsToClearResults");
                EventPicklist = new PickList(Driver).ByName("ip-kendo-grid[data-id='eventsToClearResults']", "event");
                RelativeCycleDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='eventsToClearResults']", "relativeCycle");
            }

            public KendoGrid Grid { get; }

            public PickList EventPicklist { get; }

            public DropDown RelativeCycleDropDown { get; }

            public Checkbox ClearEventOnEventChange => new Checkbox(Driver, TopicContainer).ByModel("dataItem.clearEventOnEventChange");

            public Checkbox ClearDueDateOnEventChange => new Checkbox(Driver, TopicContainer).ByModel("dataItem.clearDueDateOnEventChange");

            public Checkbox ClearEventOnDueDateChange => new Checkbox(Driver, TopicContainer).ByModel("dataItem.clearEventOnDueDateChange");

            public Checkbox ClearDueDateOnDueDateChange => new Checkbox(Driver, TopicContainer).ByModel("dataItem.clearDueDateOnDueDateChange");

            public PickList EventPicklistByRow(NgWebElement row)
            {
                return new PickList(Driver, row).ByName("event");
            }

            public DropDown RelativeCycleDropDownByRow(NgWebElement row)
            {
                return new DropDown(Driver, row).ByName("relativeCycle");
            }

            public int GridRowsCount => Grid.Rows.Count;

            public string Event => EventPicklist.InputValue;

            public string EventNo => new KendoGrid(Driver, "eventsToClearResults").CellText(0, "Event No.");
        }

        public class EventsToUpdateTopic : Topic
        {
            public EventsToUpdateTopic(NgWebDriver driver) : base(driver, "eventsToUpdate")
            {
                Grid = new KendoGrid(Driver, "eventsToUpdateGrid");
                EventPicklist = new PickList(Driver).ByName("ip-kendo-grid[data-id='eventsToUpdateGrid']", "event");
                RelativeCycleDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='eventsToUpdateGrid']", "relativeCycle");
                AdjustDateDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='eventsToUpdateGrid']", "adjustDate");
            }

            public KendoGrid Grid { get; }

            public PickList EventPicklist { get; }

            public DropDown RelativeCycleDropDown { get; }

            public int GridRowsCount => Grid.Rows.Count;

            public string Event => EventPicklist.InputValue;

            public string EventNo => Grid.CellText(0, "Event No.");

            public DropDown AdjustDateDropDown { get; }
        }

        public class NameChangeTopic : Topic
        {
            public NameChangeTopic(NgWebDriver driver) : base(driver, "nameChange")
            {
                const string topicSelector = ".topic-container[data-topic-key='nameChange']";
                ChangeCaseNamePl = new PickList(Driver).ByName(topicSelector, "changeNameType");
                CopyFromNamePl = new PickList(Driver).ByName(topicSelector, "copyFromNameType");
                MoveOldNameToNameTypePl = new PickList(Driver).ByName(topicSelector, "moveOldNameToNameType");
                DeleteCopyFromCheckbox = new Checkbox(Driver).ByModel("vm.formData.deleteCopyFromName");
            }

            public PickList ChangeCaseNamePl { get; }

            public PickList CopyFromNamePl { get; }

            public PickList MoveOldNameToNameTypePl { get; }

            public Checkbox DeleteCopyFromCheckbox { get; }

            public string ChangeCaseName => ChangeCaseNamePl.InputValue;

            public string CopyFromName => CopyFromNamePl.InputValue;

            public string MoveToName => MoveOldNameToNameTypePl.InputValue;
        }

        public class PtaDelayTopic : Topic
        {
            public PtaDelayTopic(NgWebDriver driver) : base(driver, "ptaDelaysCalc")
            {
                IpOfficeDelay = new IpRadioButton(driver, TopicContainer).ByLabel(".ipOfficeDelay");
                ApplicantDelay = new IpRadioButton(driver, TopicContainer).ByLabel(".applicantDelay");
                NotApplicable = new IpRadioButton(driver, TopicContainer).ByLabel(".notApplicable");
            }

            public IpRadioButton IpOfficeDelay { get; set; }

            public IpRadioButton ApplicantDelay { get; set; }

            public IpRadioButton NotApplicable { get; set; }
        }
    }

    public class EventInheritanceConfirmation : ModalBase
    {
        const string Id = "eventInheritanceConfirmation";

        public EventInheritanceConfirmation(NgWebDriver driver) : base(driver, Id)
        {
        }

        public bool ApplyToDescendants => Modal.FindElement(By.CssSelector("ip-checkbox input")).Selected;

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout();
        }

        public (string criteriaId, string criteriaName, string link)? GetFirstChildCriteriaLink()
        {
            var childCriteriaLinks = Modal.FindElements(By.TagName("A"));
            if (childCriteriaLinks.Count < 2) 
                return null;

            var criteriaId = childCriteriaLinks.First().Text;
            var criteriaName = childCriteriaLinks.Skip(1).First().Text;
            var link = childCriteriaLinks.Skip(1).First().GetAttribute("href");
            return (criteriaId, criteriaName, link);
        }
    }

    public class ChangeDueDateRespConfirm : ModalBase
    {
        const string Id = "changeDueDateRespConfirm";

        public ChangeDueDateRespConfirm(NgWebDriver driver) : base(driver, Id)
        {
        }

        public bool ChangeDueDateResp => Modal.FindElement(By.CssSelector("ip-checkbox input")).Selected;

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout();
        }
    }

    internal class ResetEntryInheritanceConfirmation : ModalBase
    {
        const string Id = "inheritanceResetConfirmation";

        public ResetEntryInheritanceConfirmation(NgWebDriver driver) : base(driver, Id)
        {
        }

        public NgWebElement ApplyToDescendants => Modal.FindElement(By.CssSelector("ip-checkbox input[type='checkbox']"));

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout();
        }
    }

    internal static class KendoExt
    {
        public static bool AnyInherited(this KendoGrid grid)
        {
            return grid.Rows.Any(t => t.FindElements(By.CssSelector(".cpa-icon-inheritance")).Count == 1);
        }
    }

    public class NewStatusModal : MaintenanceModal
    {
        public NewStatusModal(NgWebDriver driver) : base(driver)
        {
        }

        public TextField InternalDescription => new TextField(Driver, "internalName");
        public NgWebElement SaveButton => Driver.FindElement(By.Name("floppy-o"));
    }
}