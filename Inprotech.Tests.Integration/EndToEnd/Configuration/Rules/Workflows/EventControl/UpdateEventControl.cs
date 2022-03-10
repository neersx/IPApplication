using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class UpdateEventControls : EventControl
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEventControl(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var @event = setup.InsertWithNewId(new Event());
                var parent = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("parent"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert(new ValidEvent(parent, @event) {Inherited = 0});

                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert(new ValidEvent(criteria, @event) {Inherited = 1});

                var child = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("grandChild"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert(new ValidEvent(child, @event) {Inherited = 1});

                setup.Insert(new Inherits {Criteria = criteria, FromCriteria = parent});
                setup.Insert(new Inherits {Criteria = child, FromCriteria = criteria});

                var importance = setup.Insert(new Importance {Level = "E2", Description = "E2E"});

                var @case = new CaseBuilder(setup.DbContext).Create();
                var action = new ActionBuilder(setup.DbContext).Create();
                setup.Insert(new CaseEvent(@case.Id, @event.Id, 1) {CreatedByCriteriaKey = criteria.Id, IsOccurredFlag = 0});

                // Setup duedate on case
                setup.Insert(new OpenAction
                {
                    CriteriaId = criteria.Id,
                    CaseId = @case.Id,
                    ActionId = action.Code,
                    Cycle = 1,
                    PoliceEvents = 1
                });

                var name = new NameBuilder(setup.DbContext).CreateStaff(null, Fixture.UriSafeString(5));
                var nameType = new NameTypeBuilder(setup.DbContext).Create();

                // set up load event
                var useEvent = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("Event to Use")});
                var adjustDate = setup.InsertWithNewId(new DateAdjustment {Description = Fixture.Prefix("Date Adjustment")});
                var withRelationship = setup.InsertWithNewId(new CaseRelation {Description = Fixture.Prefix("Relationship")});
                var officialNumber = setup.InsertWithNewId(new NumberType {Name = Fixture.Prefix("Official Number")}, v => v.NumberTypeCode);

                // set up name change types
                var changeNameType = setup.InsertWithNewId(new NameType {Name = Fixture.Prefix("ChangeNameType")});
                var copyFromNameType = setup.InsertWithNewId(new NameType {Name = Fixture.Prefix("CopyFromNameType")});
                var moveOldNameToNameType = setup.InsertWithNewId(new NameType {Name = Fixture.Prefix("MoveOldNameToNameType")});

                // set up change action
                var closeAction = setup.InsertWithNewId(new Action
                {
                    Name = Fixture.Prefix("closing action"),
                    NumberOfCyclesAllowed = 2
                });

                // set up charges
                var chargeBuilder = new ChargeTypeBuilder(setup.DbContext);
                var charge1 = chargeBuilder.Create();
                var charge2 = chargeBuilder.Create();

                // set up change status
                var caseStatus = setup.InsertWithNewId(new Status {Name = Fixture.Prefix("CaseStatus"), RenewalFlag = 0});
                var renewalStatus = setup.InsertWithNewId(new Status {Name = Fixture.Prefix("RenewalStatus"), RenewalFlag = 1});

                return new
                {
                    EventId = @event.Id,
                    CriteriaId = criteria.Id,
                    ChildId = child.Id,
                    Child = child,
                    Importance = importance.Description,
                    Name = name,
                    NameType = nameType,
                    UseEventId = useEvent.Id,
                    AdjustDate = adjustDate,
                    WithRelationship = withRelationship.Relationship,
                    OfficialNumber = officialNumber.NumberTypeCode,
                    ChangeNameType = changeNameType.NameTypeCode,
                    CopyFromNameType = copyFromNameType.NameTypeCode,
                    MoveOldNameToNameType = moveOldNameToNameType.NameTypeCode,
                    ActionId = action.Code,
                    CloseActionId = closeAction.Code,
                    Charge1 = charge1,
                    Charge2 = charge2,
                    CaseStatus = caseStatus,
                    RenewalStatus = renewalStatus,
                    UserDefinedStatus = Fixture.Prefix("UserDefinedStatus")
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);

            var eventControlPage = new EventControlPage(driver);
            var commonPopups = new CommonPopups(driver);

            #region Overview

            Assert.True(eventControlPage.Overview.EventDescription.HasError, "Mandatory field is blank");
            Assert.True(eventControlPage.Overview.MaxCycles.HasError, "Mandatory field is blank");
            Assert.True(eventControlPage.Overview.ImportanceLevel.HasError, "Mandatory field is blank");

            eventControlPage.Overview.EventDescription.Text = "E2E Event";

            eventControlPage.Overview.UnlimitedCycles.ClickWithTimeout();
            Assert.AreEqual("9999", eventControlPage.Overview.MaxCycles.Text, "Checking unlimited sets value to 9999");
            Assert2.WaitTrue(10, 500, () => eventControlPage.Overview.MaxCycles.Input.WithJs().IsDisabled(), "Checking unlimited disables field");

            eventControlPage.Overview.UnlimitedCycles.ClickWithTimeout();
            Assert2.WaitFalse(10, 500, () => eventControlPage.Overview.MaxCycles.Input.WithJs().IsDisabled(), "Unchecking unlimited enables field");

            eventControlPage.Overview.Notes.Text = "E2E Notes";

            #endregion

            #region Select due date responsiblity

            eventControlPage.Overview.NavigateTo();
            eventControlPage.Overview.NameTypeRadio.Click();
            eventControlPage.Overview.NameType.EnterAndSelect(data.NameType.NameTypeCode);

            eventControlPage.Overview.NameRadio.Click();
            eventControlPage.Overview.Name.EnterAndSelect(data.Name.NameCode);

            eventControlPage.Overview.ImportanceLevel.Text = data.Importance; // Scrolls Page

            #endregion

            #region Due Date Calc Settings

            eventControlPage.DueDateCalc.NavigateTo();
            Assert.True(eventControlPage.DueDateCalc.EarliestDateToUse.IsChecked, "Default value");
            Assert.True(eventControlPage.DueDateCalc.SaveDueDateNo.IsChecked, "Default value");
            Assert.IsFalse(eventControlPage.DueDateCalc.RecalcEventDate.IsChecked, "Default value");
            Assert.True(eventControlPage.DueDateCalc.ExtendDueDate.IsHidden, "Should be hidden");
            Assert.False(eventControlPage.DueDateCalc.SuppressDueDateCalc.IsChecked, "Default value");

            eventControlPage.DueDateCalc.LatestDateToUse.Click();
            eventControlPage.DueDateCalc.SaveDueDateYes.Click();
            eventControlPage.DueDateCalc.RecalcEventDate.Click();
            eventControlPage.DueDateCalc.SuppressDueDateCalc.Click();

            eventControlPage.DueDateCalc.ExtendDueDateYes.Click();
            Assert.True(eventControlPage.DueDateCalc.LatestDateToUse.IsChecked, "Unchanged");
            Assert.True(eventControlPage.DueDateCalc.SaveDueDateNo.IsChecked, "Extend due date sets save due date to no");
            Assert.True(eventControlPage.DueDateCalc.RecalcEventDate.IsChecked, "Unchanged");
            Assert.True(eventControlPage.DueDateCalc.ExtendDueDate.Element.Displayed, "Field is now displayed");
            Assert.True(eventControlPage.DueDateCalc.SuppressDueDateCalc.IsChecked, "Unchanged");

            eventControlPage.DueDateCalc.ExtendDueDate.Text = "4";
            eventControlPage.DueDateCalc.ExtendDueDate.OptionText = "Months";

            eventControlPage.DueDateCalc.ExtendDueDateNo.Click();
            eventControlPage.EventOccurrence.OnDueDateCheckBox.Click();
            Assert.True(eventControlPage.EventOccurrence.OnDueDateCheckBox.IsChecked);

            #endregion

            #region Load Event

            var loadEvent = eventControlPage.SyncEvent;
            loadEvent.NavigateTo();
            Assert.True(loadEvent.NotApplicableOption.IsChecked, "Default option");
            Assert.False(loadEvent.SameCaseUseEvent.Displayed, "Fields hidden");
            Assert.False(loadEvent.RelatedCaseUseEvent.Displayed);
            Assert.False(loadEvent.SameCaseDateAdjustment.IsDisplayed);
            Assert.False(loadEvent.RelatedCaseDateAdjustment.IsDisplayed);
            Assert.False(loadEvent.Relationship.Displayed);
            Assert.False(loadEvent.CycleUseCaseRelationship.IsDisplayed);
            Assert.False(loadEvent.CycleUseRelatedCaseEvent.IsDisplayed);
            Assert.False(loadEvent.SyncOfficialNumber.Displayed);

            loadEvent.SameCaseOption.Click();
            Assert.True(loadEvent.SameCaseUseEvent.Displayed, "Check fields displayed");
            Assert.True(loadEvent.SameCaseDateAdjustment.IsDisplayed);
            Assert.False(loadEvent.Relationship.Displayed, "Fields hidden");
            Assert.False(loadEvent.CycleUseCaseRelationship.IsDisplayed);
            Assert.False(loadEvent.CycleUseRelatedCaseEvent.IsDisplayed);
            Assert.False(loadEvent.SyncOfficialNumber.Displayed);
            eventControlPage.SaveButton.ClickWithTimeout();
            new AlertModal(driver).Ok();
            Assert.True(loadEvent.SameCaseUseEvent.HasError, "Mandatory field");

            loadEvent.RelatedCaseOption.Click();
            eventControlPage.SaveButton.ClickWithTimeout();
            new AlertModal(driver).Ok();
            Assert.True(loadEvent.RelatedCaseUseEvent.HasError, "Mandatory field");
            Assert.True(loadEvent.Relationship.HasError, "Mandatory field");
            loadEvent.RelatedCaseUseEvent.SelectItem(data.UseEventId.ToString());
            loadEvent.RelatedCaseDateAdjustment.Text = data.AdjustDate.Description;
            loadEvent.NavigateTo();
            loadEvent.Relationship.SelectItem(data.WithRelationship);
            loadEvent.CycleUseRelatedCaseEvent.Click();
            loadEvent.SyncOfficialNumber.SelectItem(data.OfficialNumber);

            #endregion

            #region Status Change

            eventControlPage.ChangeStatus.NavigateTo();
            eventControlPage.ChangeStatus.CaseStatus.EnterAndSelect(data.CaseStatus.Name);
            eventControlPage.ChangeStatus.RenewalStatus.EnterAndSelect(data.RenewalStatus.Name);
            eventControlPage.ChangeStatus.UserDefinedStatus.Text = data.UserDefinedStatus;

            #endregion

            #region Report To CPA

            eventControlPage.Report.NavigateTo();
            Assert.True(eventControlPage.Report.NoChange.IsChecked, "Selected by default");
            eventControlPage.Report.TurnOn.Click();

            #endregion

            #region Action Control

            eventControlPage.ChangeAction.NavigateTo();
            eventControlPage.ChangeAction.OpenAction.EnterAndSelect(data.ActionId);
            Assert.True(eventControlPage.ChangeAction.RelativeCycle.IsDisabled, "Relative Cycle requires Close Action");
            eventControlPage.ChangeAction.CloseAction.EnterAndSelect(data.CloseActionId);
            Assert.AreEqual("0", eventControlPage.ChangeAction.RelativeCycle.Value, "Defaults for cyclical action");

            #endregion

            #region Name Change Settings

            eventControlPage.NameChange.NavigateTo();
            eventControlPage.NameChange.ChangeCaseNamePl.EnterAndSelect(data.ChangeNameType);
            eventControlPage.NameChange.CopyFromNamePl.EnterAndSelect(data.CopyFromNameType);
            eventControlPage.NameChange.DeleteCopyFromCheckbox.Click();
            eventControlPage.NameChange.MoveOldNameToNameTypePl.EnterAndSelect(data.MoveOldNameToNameType);

            #endregion

            #region Pta Delay

            eventControlPage.PtaDelay.NavigateTo();
            Assert.True(eventControlPage.PtaDelay.NotApplicable.IsChecked, "Pta Delay - Not Applicable selected by default");
            eventControlPage.PtaDelay.IpOfficeDelay.Click();

            #endregion

            #region Charges

            eventControlPage.Charges.NavigateTo();

            var chargeOne = eventControlPage.Charges.ChargeOne;
            var chargeTwo = eventControlPage.Charges.ChargeTwo;

            Assert.True(chargeOne.AreAllCheckboxesDisabled, "Disabled when no Charge Type");
            chargeOne.ChargeType.EnterAndSelect(data.Charge1.Description);
            Assert.True(chargeOne.RaiseCharge.IsChecked, "Checked by default when Charge Type is entered");
            chargeOne.RaiseCharge.Click();
            chargeOne.PayFee.Click();
            chargeOne.UseEstimate.Click();

            Assert.True(chargeTwo.AreAllCheckboxesDisabled, "Disabled when no Charge Type");
            chargeTwo.ChargeType.EnterAndSelect(data.Charge2.Description);
            Assert.True(chargeTwo.RaiseCharge.IsChecked, "Checked by default when Charge Type is entered");
            chargeTwo.DirectPay.Click();
            Assert.True(chargeTwo.PayFee.IsDisabled && !chargeTwo.RaiseCharge.IsChecked && chargeTwo.RaiseCharge.IsDisabled && chargeTwo.UseEstimate.IsDisabled, "Direct Pay disables other checkboxes");

            #endregion

            eventControlPage.SaveButton.ClickWithTimeout();

            Assert.True(eventControlPage.ChangeDueDateRespConfirm.ChangeDueDateResp, "Change due date responsibility checkbox should be ticked by default");
            eventControlPage.ChangeDueDateRespConfirm.Proceed();

            // confirm break inheritance with parent warning
            var confirmModal = commonPopups.ConfirmModal;
            confirmModal.PrimaryButton.ClickWithTimeout();

            Assert.True(eventControlPage.EventInheritanceConfirmation.ApplyToDescendants);
            var firstChildCriteria = eventControlPage.EventInheritanceConfirmation.GetFirstChildCriteriaLink();
            Assert.IsNotNull(firstChildCriteria);
            Assert.AreEqual(data.ChildId.ToString(), firstChildCriteria.Value.criteriaId);
            Assert.AreEqual(data.Child.Description, firstChildCriteria.Value.criteriaName);
            Assert.True(firstChildCriteria.Value.link.EndsWith(data.ChildId.ToString()));

            eventControlPage.EventInheritanceConfirmation.Proceed();

            Assert.True(commonPopups.FlashAlertIsDisplayed() || eventControlPage.IsSaveDisabled(), "Flash alert should've been displayed and save button disabled");

            using (var dbContext = new SqlDbContext())
            {
                var criteriaEvent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childEvent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                Assert.AreEqual("E2E Event", criteriaEvent.Description);
                Assert.AreEqual(9999, criteriaEvent.NumberOfCyclesAllowed);
                Assert.AreEqual("E2E Notes", criteriaEvent.Notes);
                Assert.AreEqual("E2", criteriaEvent.ImportanceLevel);
                Assert.AreEqual(data.Name.NameCode, criteriaEvent.Name.NameCode);
                Assert.AreEqual(4, criteriaEvent.SaveDueDate, "Save Due Date set to 4 (Update When Due)");
                Assert.AreEqual("L", criteriaEvent.DateToUse);
                Assert.True(criteriaEvent.RecalcEventDate);
                Assert.Null(criteriaEvent.ExtendPeriod);
                Assert.Null(criteriaEvent.ExtendPeriodType);
                Assert.True(criteriaEvent.SuppressDueDateCalculation);
                Assert.AreEqual(data.UseEventId, criteriaEvent.SyncedEvent.Id, "Load Event");
                Assert.AreEqual(data.AdjustDate.Id, criteriaEvent.SyncedEventDateAdjustmentId);
                Assert.AreEqual(data.WithRelationship, criteriaEvent.SyncedCaseRelationshipId);
                Assert.AreEqual(data.OfficialNumber, criteriaEvent.SyncedNumberTypeId);
                Assert.AreEqual(UseCycleOption.RelatedCaseEvent, criteriaEvent.UseCycle);
                Assert.True(criteriaEvent.IsThirdPartyOn, "Report to CPA");
                Assert.False(criteriaEvent.IsThirdPartyOff, "Report to CPA");
                Assert.AreEqual(data.CaseStatus.Id, criteriaEvent.ChangeStatusId, "Changed Case Status");
                Assert.AreEqual(data.CaseStatus.Id, criteriaEvent.ChangeStatusId, "Changed Renewal Status");
                Assert.AreEqual(data.UserDefinedStatus, criteriaEvent.UserDefinedStatus, "Changed user defined status");

                Assert.AreEqual(data.ActionId, criteriaEvent.OpenActionId, "Action Control");
                Assert.AreEqual(data.CloseActionId, criteriaEvent.CloseActionId, "Action Control");
                Assert.AreEqual(0, criteriaEvent.RelativeCycle, "Mapped value for Relative Cycle");
                // Charges
                Assert.AreEqual(data.Charge1.Id, criteriaEvent.InitialFeeId);
                Assert.True(criteriaEvent.IsPayFee && criteriaEvent.IsRaiseCharge && criteriaEvent.IsEstimate);
                Assert.False(criteriaEvent.IsDirectPay);
                Assert.AreEqual(data.Charge2.Id, criteriaEvent.InitialFee2Id);
                Assert.False(criteriaEvent.IsPayFee2 && criteriaEvent.IsRaiseCharge2 && criteriaEvent.IsEstimate2);
                Assert.True(criteriaEvent.IsDirectPay2);
                //Pta delay
                Assert.AreEqual(criteriaEvent.PtaDelay, (short) PtaDelayMode.IpOfficeDelay);

                Assert.AreEqual("E2E Event", childEvent.Description);
                Assert.AreEqual(9999, childEvent.NumberOfCyclesAllowed);
                Assert.AreEqual("E2E Notes", childEvent.Notes);
                Assert.AreEqual("E2", childEvent.ImportanceLevel);
                Assert.AreEqual(data.Name.NameCode, childEvent.Name.NameCode);
                Assert.AreEqual(4, childEvent.SaveDueDate, "Save Due Date saved as Update when Due");
                Assert.AreEqual("L", childEvent.DateToUse);
                Assert.True(childEvent.RecalcEventDate);
                Assert.Null(childEvent.ExtendPeriod);
                Assert.Null(childEvent.ExtendPeriodType);
                Assert.True(childEvent.SuppressDueDateCalculation);
                Assert.AreEqual(data.UseEventId, childEvent.SyncedEvent.Id, "Load Event");
                Assert.AreEqual(data.AdjustDate.Id, childEvent.SyncedEventDateAdjustmentId);
                Assert.AreEqual(data.WithRelationship, childEvent.SyncedCaseRelationshipId);
                Assert.AreEqual(data.OfficialNumber, childEvent.SyncedNumberTypeId);
                Assert.AreEqual(UseCycleOption.RelatedCaseEvent, childEvent.UseCycle);
                Assert.True(childEvent.IsThirdPartyOn, "Report to CPA");
                Assert.False(childEvent.IsThirdPartyOff, "Report to CPA");
                Assert.AreEqual(data.CaseStatus.Id, childEvent.ChangeStatusId, "Changed Case Status");
                Assert.AreEqual(data.CaseStatus.Id, childEvent.ChangeStatusId, "Changed Renewal Status");
                Assert.AreEqual(data.UserDefinedStatus, childEvent.UserDefinedStatus, "Changed user defined status");
                // Name Change
                Assert.AreEqual(data.ChangeNameType, criteriaEvent.ChangeNameTypeCode, "Name Change Saved");
                Assert.AreEqual(data.CopyFromNameType, criteriaEvent.CopyFromNameTypeCode);
                Assert.AreEqual(data.MoveOldNameToNameType, criteriaEvent.MoveOldNameToNameTypeCode);
                Assert.IsTrue(criteriaEvent.DeleteCopyFromName);
                // Action Control
                Assert.AreEqual(data.ActionId, childEvent.OpenActionId, "Action Control");
                Assert.AreEqual(data.CloseActionId, childEvent.CloseActionId, "Action Control");
                Assert.AreEqual(0, childEvent.RelativeCycle, "Mapped value for Relative Cycle");
                // Charges
                Assert.AreEqual(data.Charge1.Id, childEvent.InitialFeeId);
                Assert.True(childEvent.IsPayFee && childEvent.IsRaiseCharge && childEvent.IsEstimate);
                Assert.False(childEvent.IsDirectPay);
                Assert.AreEqual(data.Charge2.Id, childEvent.InitialFee2Id);
                Assert.False(childEvent.IsPayFee2 && childEvent.IsRaiseCharge2 && childEvent.IsEstimate2);
                Assert.True(childEvent.IsDirectPay2);
                //Pta delay
                Assert.AreEqual(criteriaEvent.PtaDelay, (short) PtaDelayMode.IpOfficeDelay);
            }
        }
    }
}