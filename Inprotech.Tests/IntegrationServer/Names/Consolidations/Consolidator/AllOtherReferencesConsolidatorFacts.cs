using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Budget;
using InprotechKaizen.Model.Accounting.Cost;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class AllOtherReferencesConsolidatorFacts : FactBase
    {
        public AllOtherReferencesConsolidatorFacts()
        {
            _from = new Name().In(Db);
            _to = new Name().In(Db);

            _subject = new AllOtherReferencesConsolidator(Db);
        }

        readonly Name _from;
        readonly Name _to;
        readonly AllOtherReferencesConsolidator _subject;
        readonly ConsolidationOption _option = new ConsolidationOption(false, false, false);

        [Fact]
        public async Task ShouldUpdateActivityCallerName()
        {
            var a = new Activity {CallerNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.CallerNameId);
        }

        [Fact]
        public async Task ShouldUpdateActivityContactName()
        {
            var a = new Activity {ContactNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ContactNameId);
        }

        [Fact]
        public async Task ShouldUpdateActivityReferredToName()
        {
            var a = new Activity {ReferredToNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ReferredToNameId);
        }

        [Fact]
        public async Task ShouldUpdateActivityStaffName()
        {
            var a = new Activity {StaffNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffNameId);
        }

        [Fact]
        public async Task ShouldUpdateAlertRuleStaff()
        {
            var a = new AlertRule {StaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffId);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleFromName()
        {
            var a = new BatchTypeRule {FromNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.FromNameNo);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleHeaderInstructor()
        {
            var a = new BatchTypeRule {HeaderInstructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.HeaderInstructor);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleHeaderStaffName()
        {
            var a = new BatchTypeRule {HeaderStaffName = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.HeaderStaffName);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleImportedInstructor()
        {
            var a = new BatchTypeRule {ImportedInstructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ImportedInstructor);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleImportedStaffName()
        {
            var a = new BatchTypeRule {ImportedStaffName = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ImportedStaffName);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleRejectedInstructor()
        {
            var a = new BatchTypeRule {RejectedInstructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.RejectedInstructor);
        }

        [Fact]
        public async Task ShouldUpdateBatchTypeRuleRejectedStaffName()
        {
            var a = new BatchTypeRule {RejectedStaffName = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.RejectedStaffName);
        }

        [Fact]
        public async Task ShouldUpdateBillFormatName()
        {
            var a = new BillFormat {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateBillRuleDebtor()
        {
            var a = new BillRule {DebtorId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DebtorId);
        }

        [Fact]
        public async Task ShouldUpdateBudgetEntity()
        {
            var a = new Budget {EntityNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EntityNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestDebtor()
        {
            var a = new CaseActivityRequest {Debtor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Debtor);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestDisbEmployee()
        {
            var a = new CaseActivityRequest {DisbEmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DisbEmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestEmployee()
        {
            var a = new CaseActivityRequest {EmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestInstructor()
        {
            var a = new CaseActivityRequest {Instructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Instructor);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestOwner()
        {
            var a = new CaseActivityRequest {Owner = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Owner);
        }

        [Fact]
        public async Task ShouldUpdateCaseActivityRequestServiceEmployee()
        {
            var a = new CaseActivityRequest {ServiceEmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ServiceEmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseBudgetEmployee()
        {
            var a = new CaseBudget {EmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseChecklistEmployee()
        {
            var a = new CaseChecklist {EmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeId);
        }

        [Fact]
        public async Task ShouldUpdateCaseEventEmployee()
        {
            var a = new CaseEvent {EmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseLocationIssuedBy()
        {
            var a = new CaseLocation {IssuedBy = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.IssuedBy);
        }

        [Fact]
        public async Task ShouldUpdateCaseNameRequestCurrentAttention()
        {
            var a = new CaseNameRequest {CurrentAttention = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.CurrentAttention);
        }

        [Fact]
        public async Task ShouldUpdateCaseNameRequestCurrentName()
        {
            var a = new CaseNameRequest {CurrentNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.CurrentNameNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseNameRequestNewAttention()
        {
            var a = new CaseNameRequest {NewAttention = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NewAttention);
        }

        [Fact]
        public async Task ShouldUpdateCaseNameRequestNewName()
        {
            var a = new CaseNameRequest {NewNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NewNameNo);
        }

        [Fact]
        public async Task ShouldUpdateCaseProfitCentreInstructor()
        {
            var a = new CaseProfitCentre {Instructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Instructor);
        }

        [Fact]
        public async Task ShouldUpdateCaseReferenceAllocationEmployee()
        {
            var a = new CaseReferenceAllocation {EmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeId);
        }

        [Fact]
        public async Task ShouldUpdateCostRateEmployee()
        {
            var a = new CostRate {EmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateCostTrackAgent()
        {
            var a = new CostTrack {AgentNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AgentNo);
        }

        [Fact]
        public async Task ShouldUpdateCostTrackAllocDebtor()
        {
            var a = new CostTrackAlloc {DebtorNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DebtorNo);
        }

        [Fact]
        public async Task ShouldUpdateCostTrackAllocDivision()
        {
            var a = new CostTrackAlloc {DivisionNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DivisionNo);
        }

        [Fact]
        public async Task ShouldUpdateCostTrackLineDivision()
        {
            var a = new CostTrackLine {DivisionNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DivisionNo);
        }

        [Fact]
        public async Task ShouldUpdateCostTrackLineForeignAgent()
        {
            var a = new CostTrackLine {ForeignAgentNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ForeignAgentNo);
        }

        [Fact]
        public async Task ShouldUpdateCpaUpdateName()
        {
            var a = new CpaUpdate {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateCreditorHistoryRemittanceName()
        {
            var a = new CreditorHistory {RemittanceNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.RemittanceNameNo);
        }

        [Fact]
        public async Task ShouldUpdateCriteriaDataSourceName()
        {
            var a = new Criteria {DataSourceNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DataSourceNameId);
        }

        [Fact]
        public async Task ShouldUpdateDataMapSource()
        {
            var a = new DataMap {SourceNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.SourceNo);
        }

        [Fact]
        public async Task ShouldUpdateDataSourceSourceName()
        {
            var a = new DataSource {SourceNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.SourceNameNo);
        }

        [Fact]
        public async Task ShouldUpdateDataValidationName()
        {
            var a = new DataValidation { NameId = _from.Id }.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateDataWizardDefaultSource()
        {
            var a = new DataWizard {DefaultSourceNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DefaultSourceNo);
        }

        [Fact]
        public async Task ShouldUpdateDebitNoteImageDebtor()
        {
            var a = new DebitNoteImage {DebtorId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DebtorId);
        }

        [Fact]
        public async Task ShouldUpdateDocumentRequestRecipient()
        {
            var a = new DocumentRequest {Recipient = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Recipient);
        }

        [Fact]
        public async Task ShouldUpdateDocumentSubstituteName()
        {
            var a = new DocumentSubstitute {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateEdeAddressBookName()
        {
            var a = new EdeAddressBook {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateEdeFormattedAttnOfName()
        {
            var a = new EdeFormattedAttnOf {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateEdeOutstandingIssuesName()
        {
            var a = new EdeOutstandingIssues {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateEdeSenderDetailsSenderName()
        {
            var a = new EdeSenderDetails {SenderNameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.SenderNameNo);
        }

        [Fact]
        public async Task ShouldUpdateEdeTransactionContentDetailsAlternateSenderName()
        {
            var a = new EdeTransactionContentDetails {AlternateSenderNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AlternateSenderNameId);
        }

        [Fact]
        public async Task ShouldUpdateExpenseImportEmployee()
        {
            var a = new ExpenseImport {StaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffId);
        }

        [Fact]
        public async Task ShouldUpdateExpenseImportName()
        {
            var a = new ExpenseImport {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateExpenseImportSupplierName()
        {
            var a = new ExpenseImport {SupplierNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.SupplierNameId);
        }

        [Fact]
        public async Task ShouldUpdateExternalNameDataSourceName()
        {
            var a = new ExternalName {DataSourceNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DataSourceNameId);
        }

        [Fact]
        public async Task ShouldUpdateExternalNameMappingInproName()
        {
            var a = new ExternalNameMapping {InproNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.InproNameId);
        }

        [Fact]
        public async Task ShouldUpdateExternalNameMappingInstructorName()
        {
            var a = new ExternalNameMapping {InstructorNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.InstructorNameId);
        }

        [Fact]
        public async Task ShouldUpdateFeeListFeeListName()
        {
            var a = new FeeList {FeeListNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.FeeListNameId);
        }

        [Fact]
        public async Task ShouldUpdateFeeListIpOffice()
        {
            var a = new FeeList {IPOfficeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.IPOfficeId);
        }

        [Fact]
        public async Task ShouldUpdateFileRequestEmployee()
        {
            var a = new FileRequest {EmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeId);
        }

        [Fact]
        public async Task ShouldUpdateFunctionSecurityAccessStaff()
        {
            var a = new FunctionSecurity {AccessStaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AccessStaffId);
        }

        [Fact]
        public async Task ShouldUpdateFunctionSecurityOwner()
        {
            var a = new FunctionSecurity {OwnerId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.OwnerId);
        }

        [Fact]
        public async Task ShouldUpdateGlAccountMappingWipEmployee()
        {
            var a = new GlAccountMapping {WipStaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.WipStaffId);
        }

        [Fact]
        public async Task ShouldUpdateIdentityNamesName()
        {
            var a = new IdentityNames {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateImportBatchFromName()
        {
            var a = new ImportBatch {FromNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.FromNameId);
        }

        [Fact]
        public async Task ShouldUpdateMarginAgent()
        {
            var a = new Margin {AgentId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AgentId);
        }

        [Fact]
        public async Task ShouldUpdateMarginInstructor()
        {
            var a = new Margin {InstructorId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.InstructorId);
        }

        [Fact]
        public async Task ShouldUpdateNameAddressSnapAttnName()
        {
            var a = new NameAddressSnapshot {AttentionNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AttentionNameId);
        }

        [Fact]
        public async Task ShouldUpdateNameAddressSnapName()
        {
            var a = new NameAddressSnapshot {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateNameLocationName()
        {
            var a = new NameLocation {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateNameTypeDefaultName()
        {
            var a = new NameType {DefaultNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DefaultNameId);
        }

        [Fact]
        public async Task ShouldUpdateNameVariantName()
        {
            var a = new NameVariant {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateNarrativeRuleDebtor()
        {
            var a = new NarrativeRule {DebtorId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DebtorId);
        }

        [Fact]
        public async Task ShouldUpdateNarrativeRuleEmployee()
        {
            var a = new NarrativeRule {StaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffId);
        }

        [Fact]
        public async Task ShouldUpdateNarrativeSubstituteName()
        {
            var a = new NarrativeSubstitute {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateOfficeOrganisation()
        {
            var a = new Office {OrganisationId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.OrganisationId);
        }

        [Fact]
        public async Task ShouldUpdatePolicingRequestEmployee()
        {
            var a = new PolicingRequest {EmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeId);
        }

        [Fact]
        public async Task ShouldUpdatePolicingRequestName()
        {
            var a = new PolicingRequest {NameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameNo);
        }

        [Fact]
        public async Task ShouldUpdateQuotationName()
        {
            var a = new Quotation {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateQuotationRaisedBy()
        {
            var a = new Quotation {RaisedById = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.RaisedById);
        }

        [Fact]
        public async Task ShouldUpdateReciprocityName()
        {
            var a = new Reciprocity {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateRecordalAffectedCaseAgent()
        {
            var a = new RecordalAffectedCase {AgentId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AgentId);
        }

        [Fact]
        public async Task ShouldUpdateRelatedCaseAgent()
        {
            var a = new RelatedCase {AgentId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AgentId);
        }

        [Fact]
        public async Task ShouldUpdateRelatedCaseTranslator()
        {
            var a = new RelatedCase {TranslatorId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.TranslatorId);
        }

        [Fact]
        public async Task ShouldUpdateReminderRuleRemindEmployee()
        {
            var a = new ReminderRule {RemindEmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.RemindEmployeeId);
        }

        [Fact]
        public async Task ShouldUpdateRfIdFileRequestEmployee()
        {
            var a = new RfIdFileRequest {EmployeeId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeId);
        }

        [Fact]
        public async Task ShouldUpdateRowAccessDetailName()
        {
            var a = new RowAccessDetail {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateTimeCostingEmployee()
        {
            var a = new TimeCosting {EmployeeNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.EmployeeNo);
        }

        [Fact]
        public async Task ShouldUpdateTimeCostingInstructor()
        {
            var a = new TimeCosting {Instructor = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Instructor);
        }

        [Fact]
        public async Task ShouldUpdateTimeCostingName()
        {
            var a = new TimeCosting {NameNo = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameNo);
        }

        [Fact]
        public async Task ShouldUpdateTimeCostingOwner()
        {
            var a = new TimeCosting {Owner = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.Owner);
        }

        [Fact]
        public async Task ShouldUpdateTransactionInfoName()
        {
            var a = new TransactionInfo {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateTransAdjustmentToEmployee()
        {
            var a = new TransAdjustment {ToStaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.ToStaffId);
        }

        [Fact]
        public async Task ShouldUpdateUserName()
        {
            var a = new User {NameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.NameId);
        }

        [Fact]
        public async Task ShouldUpdateValidEventDueDateRespName()
        {
            var a = new ValidEvent {DueDateRespNameId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.DueDateRespNameId);
        }

        [Fact]
        public async Task ShouldUpdateWorkHistoryAcctClient()
        {
            var a = new WorkHistory {AccountClientId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AccountClientId);
        }

        [Fact]
        public async Task ShouldUpdateWorkHistoryAssociate()
        {
            var a = new WorkHistory {AssociateId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AssociateId);
        }

        [Fact]
        public async Task ShouldUpdateWorkHistoryEmployee()
        {
            var a = new WorkHistory {StaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffId);
        }

        [Fact]
        public async Task ShouldUpdateWorkInProgressAccountClient()
        {
            var a = new WorkInProgress {AccountClientId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AccountClientId);
        }

        [Fact]
        public async Task ShouldUpdateWorkInProgressAssociate()
        {
            var a = new WorkInProgress {AssociateId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.AssociateId);
        }

        [Fact]
        public async Task ShouldUpdateWorkInProgressEmployee()
        {
            var a = new WorkInProgress {StaffId = _from.Id}.In(Db);

            await _subject.Consolidate(_to, _from, _option);

            Assert.Equal(_to.Id, a.StaffId);
        }
    }
}