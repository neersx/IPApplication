using System.Linq;
using System.Threading.Tasks;
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
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class AllOtherReferencesConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public AllOtherReferencesConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(AllOtherReferencesConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await UpdateActivityCallerName(to, from);

            await UpdateActivityStaffName(to, from);

            await UpdateActivityContactName(to, from);

            await UpdateActivityReferredToName(to, from);

            await UpdateCaseActivityRequestDebtor(to, from);

            await UpdateCaseActivityRequestDisbursementEmployee(to, from);

            await UpdateCaseActivityRequestEmployee(to, from);

            await UpdateCaseActivityRequestInstructor(to, from);

            await UpdateCaseActivityRequestOwner(to, from);

            await UpdateCaseActivityRequestServiceEmployee(to, from);

            await UpdateAlertRuleStaff(to, from);

            await UpdateBatchTypeRuleFromName(to, from);

            await UpdateBatchTypeRuleHeaderInstructor(to, from);

            await UpdateBatchTypeRuleHeaderStaffName(to, from);

            await UpdateBatchTypeRuleImportedInstructor(to, from);

            await UpdateBatchTypeRuleImportedStaffName(to, from);

            await UpdateBatchTypeRuleRejectedInstructor(to, from);

            await UpdateBatchTypeRuleRejectedStaffName(to, from);

            await UpdateBillFormatName(to, from);

            await UpdateBillRuleDebtor(to, from);

            await UpdateBudgetEntity(to, from);

            await UpdateCaseBudgetEmployee(to, from);

            await UpdateCaseChecklistEmployee(to, from);

            await UpdateCaseEventEmployee(to, from);

            await UpdateCaseLocationIssuedBy(to, from);

            await UpdateCaseNameRequestCurrentAttention(to, from);

            await UpdateCaseNameRequestCurrentName(to, from);

            await UpdateCaseNameRequestNewAttention(to, from);

            await UpdateCaseNameRequestNewName(to, from);

            await UpdateCaseProfitCentreInstructor(to, from);

            await UpdateCostRateEmployee(to, from);

            await UpdateCostTrackAgent(to, from);

            await UpdateCostTrackAllocDebtor(to, from);

            await UpdateCostTrackAllocDivision(to, from);

            await UpdateCostTrackLineDivision(to, from);

            await UpdateCostTrackLineForeignAgent(to, from);

            await UpdateCpaUpdateName(to, from);

            await UpdateCreditorHistoryRemittanceName(to, from);

            await UpdateCriteriaDataSourceName(to, from);

            await UpdateDataMapSource(to, from);

            await UpdateDataSourceSourceName(to, from);

            await UpdateDataValidationName(to, from);

            await UpdateDataWizardDefaultSource(to, from);

            await UpdateDebitNoteImageDebtor(to, from);

            await UpdateDocumentRequestRecipient(to, from);

            await UpdateEdeAddressBookName(to, from);

            await UpdateEdeFormattedAttnOfName(to, from);

            await UpdateEdeOutstandingIssuesName(to, from);

            await UpdateEdeSenderDetailsSenderName(to, from);

            await UpdateEdeTransactionContentDetailsAlternateSenderName(to, from);

            await UpdateValidEventDueDateRespName(to, from);

            await UpdateExpenseImportEmployee(to, from);

            await UpdateExpenseImportName(to, from);

            await UpdateExpenseImportSupplierName(to, from);

            await UpdateExternalNameDataSourceName(to, from);

            await UpdateExternalNameMappingInproName(to, from);

            await UpdateExternalNameMappingInstructorName(to, from);

            await UpdateFeeListFeeListName(to, from);

            await UpdateFeeListIpOffice(to, from);

            await UpdateFileRequestEmployee(to, from);

            await UpdateFunctionSecurityAccessStaff(to, from);

            await UpdateFunctionSecurityOwner(to, from);

            await UpdateGlAccountMappingWipEmployee(to, from);

            await UpdateIdentityNamesName(to, from);

            await UpdateImportBatchFromName(to, from);

            await UpdateCaseReferenceAllocationEmployee(to, from);

            await UpdateDocumentSubstituteName(to, from);

            await UpdateMarginAgent(to, from);

            await UpdateMarginInstructor(to, from);

            await UpdateNameAddressSnapAttnName(to, from);

            await UpdateNameAddressSnapName(to, from);

            await UpdateNameTypeDefaultName(to, from);

            await UpdateNameVariantName(to, from);

            await UpdateNameLocationName(to, from);

            await UpdateNarrativeRuleEmployee(to, from);

            await UpdateNarrativeRuleDebtor(to, from);

            await UpdateNarrativeSubstituteName(to, from);

            await UpdateOfficeOrganisation(to, from);

            await UpdatePolicingRequestEmployee(to, from);

            await UpdatePolicingRequestName(to, from);

            await UpdateQuotationName(to, from);

            await UpdateQuotationRaisedBy(to, from);

            await UpdateReciprocityName(to, from);

            await UpdateRecordalAffectedCaseAgent(to, from);

            await UpdateRelatedCaseAgent(to, from);

            await UpdateRelatedCaseTranslator(to, from);

            await UpdateReminderRuleRemindEmployee(to, from);

            await UpdateRfIdFileRequestEmployee(to, from);

            await UpdateRowAccessDetailName(to, from);

            await UpdateTimeCostingEmployee(to, from);

            await UpdateTimeCostingInstructor(to, from);

            await UpdateTimeCostingName(to, from);

            await UpdateTimeCostingOwner(to, from);

            await UpdateTransactionInfoName(to, from);

            await UpdateTransAdjustmentToEmployee(to, from);

            await UpdateUserName(to, from);

            await UpdateWorkHistoryAssociate(to, from);

            await UpdateWorkHistoryEmployee(to, from);

            await UpdateWorkHistoryAcctClient(to, from);

            await UpdateWorkInProgressAssociate(to, from);

            await UpdateWorkInProgressEmployee(to, from);

            await UpdateWorkInProgressAccountClient(to, from);
        }

        async Task UpdateActivityCallerName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Activity>() where _.CallerNameId == @from.Id select _, _ => new Activity {CallerNameId = to.Id});
        }

        async Task UpdateActivityStaffName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Activity>() where _.StaffNameId == @from.Id select _, _ => new Activity {StaffNameId = to.Id});
        }

        async Task UpdateActivityContactName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Activity>() where _.ContactNameId == @from.Id select _, _ => new Activity {ContactNameId = to.Id});
        }

        async Task UpdateActivityReferredToName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Activity>() where _.ReferredToNameId == @from.Id select _, _ => new Activity {ReferredToNameId = to.Id});
        }

        async Task UpdateCaseActivityRequestDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.Debtor == @from.Id select _, _ => new CaseActivityRequest {Debtor = to.Id});
        }

        async Task UpdateCaseActivityRequestDisbursementEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.DisbEmployeeNo == @from.Id select _, _ => new CaseActivityRequest {DisbEmployeeNo = to.Id});
        }

        async Task UpdateCaseActivityRequestEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.EmployeeNo == @from.Id select _, _ => new CaseActivityRequest {EmployeeNo = to.Id});
        }

        async Task UpdateCaseActivityRequestInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.Instructor == @from.Id select _, _ => new CaseActivityRequest {Instructor = to.Id});
        }

        async Task UpdateCaseActivityRequestOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.Owner == @from.Id select _, _ => new CaseActivityRequest {Owner = to.Id});
        }

        async Task UpdateCaseActivityRequestServiceEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseActivityRequest>() where _.ServiceEmployeeNo == @from.Id select _, _ => new CaseActivityRequest {ServiceEmployeeNo = to.Id});
        }

        async Task UpdateAlertRuleStaff(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<AlertRule>() where _.StaffId == @from.Id select _, _ => new AlertRule {StaffId = to.Id});
        }

        async Task UpdateBatchTypeRuleFromName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.FromNameNo == @from.Id select _, _ => new BatchTypeRule {FromNameNo = to.Id});
        }

        async Task UpdateBatchTypeRuleHeaderInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.HeaderInstructor == @from.Id select _, _ => new BatchTypeRule {HeaderInstructor = to.Id});
        }

        async Task UpdateBatchTypeRuleHeaderStaffName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.HeaderStaffName == @from.Id select _, _ => new BatchTypeRule {HeaderStaffName = to.Id});
        }

        async Task UpdateBatchTypeRuleImportedInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.ImportedInstructor == @from.Id select _, _ => new BatchTypeRule {ImportedInstructor = to.Id});
        }

        async Task UpdateBatchTypeRuleImportedStaffName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.ImportedStaffName == @from.Id select _, _ => new BatchTypeRule {ImportedStaffName = to.Id});
        }

        async Task UpdateBatchTypeRuleRejectedInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.RejectedInstructor == @from.Id select _, _ => new BatchTypeRule {RejectedInstructor = to.Id});
        }

        async Task UpdateBatchTypeRuleRejectedStaffName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BatchTypeRule>() where _.RejectedStaffName == @from.Id select _, _ => new BatchTypeRule {RejectedStaffName = to.Id});
        }

        async Task UpdateBillFormatName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BillFormat>() where _.NameId == @from.Id select _, _ => new BillFormat {NameId = to.Id});
        }

        async Task UpdateBillRuleDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<BillRule>() where _.DebtorId == @from.Id select _, _ => new BillRule {DebtorId = to.Id});
        }

        async Task UpdateBudgetEntity(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Budget>() where _.EntityNo == @from.Id select _, _ => new Budget {EntityNo = to.Id});
        }

        async Task UpdateCaseBudgetEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseBudget>() where _.EmployeeNo == @from.Id select _, _ => new CaseBudget {EmployeeNo = to.Id});
        }

        async Task UpdateCaseChecklistEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseChecklist>() where _.EmployeeId == @from.Id select _, _ => new CaseChecklist {EmployeeId = to.Id});
        }

        async Task UpdateCaseEventEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseEvent>() where _.EmployeeNo == @from.Id select _, _ => new CaseEvent {EmployeeNo = to.Id});
        }

        async Task UpdateCaseLocationIssuedBy(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseLocation>() where _.IssuedBy == @from.Id select _, _ => new CaseLocation {IssuedBy = to.Id});
        }

        async Task UpdateCaseNameRequestCurrentAttention(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseNameRequest>() where _.CurrentAttention == @from.Id select _, _ => new CaseNameRequest {CurrentAttention = to.Id});
        }

        async Task UpdateCaseNameRequestCurrentName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseNameRequest>() where _.CurrentNameNo == @from.Id select _, _ => new CaseNameRequest {CurrentNameNo = to.Id});
        }

        async Task UpdateCaseNameRequestNewAttention(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseNameRequest>() where _.NewAttention == @from.Id select _, _ => new CaseNameRequest {NewAttention = to.Id});
        }

        async Task UpdateCaseNameRequestNewName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseNameRequest>() where _.NewNameNo == @from.Id select _, _ => new CaseNameRequest {NewNameNo = to.Id});
        }

        async Task UpdateCaseProfitCentreInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseProfitCentre>() where _.Instructor == @from.Id select _, _ => new CaseProfitCentre {Instructor = to.Id});
        }

        async Task UpdateCostRateEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostRate>() where _.EmployeeNo == @from.Id select _, _ => new CostRate {EmployeeNo = to.Id});
        }

        async Task UpdateCostTrackAgent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostTrack>() where _.AgentNo == @from.Id select _, _ => new CostTrack {AgentNo = to.Id});
        }

        async Task UpdateCostTrackAllocDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostTrackAlloc>() where _.DebtorNo == @from.Id select _, _ => new CostTrackAlloc {DebtorNo = to.Id});
        }

        async Task UpdateCostTrackAllocDivision(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostTrackAlloc>() where _.DivisionNo == @from.Id select _, _ => new CostTrackAlloc {DivisionNo = to.Id});
        }

        async Task UpdateCostTrackLineDivision(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostTrackLine>() where _.DivisionNo == @from.Id select _, _ => new CostTrackLine {DivisionNo = to.Id});
        }

        async Task UpdateCostTrackLineForeignAgent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CostTrackLine>() where _.ForeignAgentNo == @from.Id select _, _ => new CostTrackLine {ForeignAgentNo = to.Id});
        }

        async Task UpdateCpaUpdateName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CpaUpdate>() where _.NameId == @from.Id select _, _ => new CpaUpdate {NameId = to.Id});
        }

        async Task UpdateCreditorHistoryRemittanceName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CreditorHistory>() where _.RemittanceNameNo == @from.Id select _, _ => new CreditorHistory {RemittanceNameNo = to.Id});
        }

        async Task UpdateCriteriaDataSourceName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Criteria>() where _.DataSourceNameId == @from.Id select _, _ => new Criteria {DataSourceNameId = to.Id});
        }

        async Task UpdateDataMapSource(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DataMap>() where _.SourceNo == @from.Id select _, _ => new DataMap {SourceNo = to.Id});
        }

        async Task UpdateDataSourceSourceName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DataSource>() where _.SourceNameNo == @from.Id select _, _ => new DataSource {SourceNameNo = to.Id});
        }

        async Task UpdateDataValidationName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DataValidation>() where _.NameId == @from.Id select _, _ => new DataValidation { NameId = to.Id });
        }

        async Task UpdateDataWizardDefaultSource(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DataWizard>() where _.DefaultSourceNo == @from.Id select _, _ => new DataWizard {DefaultSourceNo = to.Id});
        }

        async Task UpdateDebitNoteImageDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DebitNoteImage>() where _.DebtorId == @from.Id select _, _ => new DebitNoteImage {DebtorId = to.Id});
        }

        async Task UpdateDocumentRequestRecipient(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DocumentRequest>() where _.Recipient == @from.Id select _, _ => new DocumentRequest {Recipient = to.Id});
        }

        async Task UpdateEdeAddressBookName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<EdeAddressBook>() where _.NameId == @from.Id select _, _ => new EdeAddressBook {NameId = to.Id});
        }

        async Task UpdateEdeFormattedAttnOfName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<EdeFormattedAttnOf>() where _.NameId == @from.Id select _, _ => new EdeFormattedAttnOf {NameId = to.Id});
        }

        async Task UpdateEdeOutstandingIssuesName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<EdeOutstandingIssues>() where _.NameId == @from.Id select _, _ => new EdeOutstandingIssues {NameId = to.Id});
        }

        async Task UpdateEdeSenderDetailsSenderName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<EdeSenderDetails>() where _.SenderNameNo == @from.Id select _, _ => new EdeSenderDetails {SenderNameNo = to.Id});
        }

        async Task UpdateEdeTransactionContentDetailsAlternateSenderName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<EdeTransactionContentDetails>() where _.AlternateSenderNameId == @from.Id select _, _ => new EdeTransactionContentDetails {AlternateSenderNameId = to.Id});
        }

        async Task UpdateValidEventDueDateRespName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ValidEvent>() where _.DueDateRespNameId == @from.Id select _, _ => new ValidEvent {DueDateRespNameId = to.Id});
        }

        async Task UpdateExpenseImportEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExpenseImport>() where _.StaffId == @from.Id select _, _ => new ExpenseImport {StaffId = to.Id});
        }

        async Task UpdateExpenseImportName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExpenseImport>() where _.NameId == @from.Id select _, _ => new ExpenseImport {NameId = to.Id});
        }

        async Task UpdateExpenseImportSupplierName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExpenseImport>() where _.SupplierNameId == @from.Id select _, _ => new ExpenseImport {SupplierNameId = to.Id});
        }

        async Task UpdateExternalNameDataSourceName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExternalName>() where _.DataSourceNameId == @from.Id select _, _ => new ExternalName {DataSourceNameId = to.Id});
        }

        async Task UpdateExternalNameMappingInproName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExternalNameMapping>() where _.InproNameId == @from.Id select _, _ => new ExternalNameMapping {InproNameId = to.Id});
        }

        async Task UpdateExternalNameMappingInstructorName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ExternalNameMapping>() where _.InstructorNameId == @from.Id select _, _ => new ExternalNameMapping {InstructorNameId = to.Id});
        }

        async Task UpdateFeeListFeeListName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<FeeList>() where _.FeeListNameId == @from.Id select _, _ => new FeeList {FeeListNameId = to.Id});
        }

        async Task UpdateFeeListIpOffice(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<FeeList>() where _.IPOfficeId == @from.Id select _, _ => new FeeList {IPOfficeId = to.Id});
        }

        async Task UpdateFileRequestEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<FileRequest>() where _.EmployeeId == @from.Id select _, _ => new FileRequest {EmployeeId = to.Id});
        }

        async Task UpdateFunctionSecurityAccessStaff(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<FunctionSecurity>() where _.AccessStaffId == @from.Id select _, _ => new FunctionSecurity {AccessStaffId = to.Id});
        }

        async Task UpdateFunctionSecurityOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<FunctionSecurity>() where _.OwnerId == @from.Id select _, _ => new FunctionSecurity {OwnerId = to.Id});
        }

        async Task UpdateGlAccountMappingWipEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<GlAccountMapping>() where _.WipStaffId == @from.Id select _, _ => new GlAccountMapping {WipStaffId = to.Id});
        }

        async Task UpdateIdentityNamesName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<IdentityNames>() where _.NameId == @from.Id select _, _ => new IdentityNames {NameId = to.Id});
        }

        async Task UpdateImportBatchFromName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ImportBatch>() where _.FromNameId == @from.Id select _, _ => new ImportBatch {FromNameId = to.Id});
        }

        async Task UpdateCaseReferenceAllocationEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<CaseReferenceAllocation>() where _.EmployeeId == @from.Id select _, _ => new CaseReferenceAllocation {EmployeeId = to.Id});
        }

        async Task UpdateDocumentSubstituteName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<DocumentSubstitute>() where _.NameId == @from.Id select _, _ => new DocumentSubstitute {NameId = to.Id});
        }

        async Task UpdateMarginAgent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Margin>() where _.AgentId == @from.Id select _, _ => new Margin {AgentId = to.Id});
        }

        async Task UpdateMarginInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Margin>() where _.InstructorId == @from.Id select _, _ => new Margin {InstructorId = to.Id});
        }

        async Task UpdateNameAddressSnapAttnName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NameAddressSnapshot>() where _.AttentionNameId == @from.Id select _, _ => new NameAddressSnapshot {AttentionNameId = to.Id});
        }

        async Task UpdateNameAddressSnapName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NameAddressSnapshot>() where _.NameId == @from.Id select _, _ => new NameAddressSnapshot {NameId = to.Id});
        }

        async Task UpdateNameTypeDefaultName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NameType>() where _.DefaultNameId == @from.Id select _, _ => new NameType {DefaultNameId = to.Id});
        }

        async Task UpdateNameVariantName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NameVariant>() where _.NameId == @from.Id select _, _ => new NameVariant {NameId = to.Id});
        }

        async Task UpdateNameLocationName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NameLocation>() where _.NameId == @from.Id select _, _ => new NameLocation {NameId = to.Id});
        }

        async Task UpdateNarrativeRuleEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NarrativeRule>() where _.StaffId == @from.Id select _, _ => new NarrativeRule {StaffId = to.Id});
        }

        async Task UpdateNarrativeRuleDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NarrativeRule>() where _.DebtorId == @from.Id select _, _ => new NarrativeRule {DebtorId = to.Id});
        }

        async Task UpdateNarrativeSubstituteName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<NarrativeSubstitute>() where _.NameId == @from.Id select _, _ => new NarrativeSubstitute {NameId = to.Id});
        }

        async Task UpdateOfficeOrganisation(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Office>() where _.OrganisationId == @from.Id select _, _ => new Office {OrganisationId = to.Id});
        }

        async Task UpdatePolicingRequestEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<PolicingRequest>() where _.EmployeeId == @from.Id select _, _ => new PolicingRequest {EmployeeId = to.Id});
        }

        async Task UpdatePolicingRequestName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<PolicingRequest>() where _.NameNo == @from.Id select _, _ => new PolicingRequest {NameNo = to.Id});
        }

        async Task UpdateQuotationName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Quotation>() where _.NameId == @from.Id select _, _ => new Quotation {NameId = to.Id});
        }

        async Task UpdateQuotationRaisedBy(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Quotation>() where _.RaisedById == @from.Id select _, _ => new Quotation {RaisedById = to.Id});
        }

        async Task UpdateReciprocityName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<Reciprocity>() where _.NameId == @from.Id select _, _ => new Reciprocity {NameId = to.Id});
        }

        async Task UpdateRecordalAffectedCaseAgent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<RecordalAffectedCase>() where _.AgentId == @from.Id select _, _ => new RecordalAffectedCase {AgentId = to.Id});
        }

        async Task UpdateRelatedCaseAgent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<RelatedCase>() where _.AgentId == @from.Id select _, _ => new RelatedCase {AgentId = to.Id});
        }

        async Task UpdateRelatedCaseTranslator(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<RelatedCase>() where _.TranslatorId == @from.Id select _, _ => new RelatedCase {TranslatorId = to.Id});
        }

        async Task UpdateReminderRuleRemindEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<ReminderRule>() where _.RemindEmployeeId == @from.Id select _, _ => new ReminderRule {RemindEmployeeId = to.Id});
        }

        async Task UpdateRfIdFileRequestEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<RfIdFileRequest>() where _.EmployeeId == @from.Id select _, _ => new RfIdFileRequest {EmployeeId = to.Id});
        }

        async Task UpdateRowAccessDetailName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<RowAccessDetail>() where _.NameId == @from.Id select _, _ => new RowAccessDetail {NameId = to.Id});
        }

        async Task UpdateTimeCostingEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TimeCosting>() where _.EmployeeNo == @from.Id select _, _ => new TimeCosting {EmployeeNo = to.Id});
        }

        async Task UpdateTimeCostingInstructor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TimeCosting>() where _.Instructor == @from.Id select _, _ => new TimeCosting {Instructor = to.Id});
        }

        async Task UpdateTimeCostingName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TimeCosting>() where _.NameNo == @from.Id select _, _ => new TimeCosting {NameNo = to.Id});
        }

        async Task UpdateTimeCostingOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TimeCosting>() where _.Owner == @from.Id select _, _ => new TimeCosting {Owner = to.Id});
        }

        async Task UpdateTransactionInfoName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TransactionInfo>() where _.NameId == @from.Id select _, _ => new TransactionInfo {NameId = to.Id});
        }

        async Task UpdateTransAdjustmentToEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<TransAdjustment>() where _.ToStaffId == @from.Id select _, _ => new TransAdjustment {ToStaffId = to.Id});
        }

        async Task UpdateUserName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<User>() where _.NameId == @from.Id select _, _ => new User {NameId = to.Id});
        }

        async Task UpdateWorkHistoryAssociate(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkHistory>() where _.AssociateId == @from.Id select _, _ => new WorkHistory {AssociateId = to.Id});
        }

        async Task UpdateWorkHistoryEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkHistory>() where _.StaffId == @from.Id select _, _ => new WorkHistory {StaffId = to.Id});
        }

        async Task UpdateWorkHistoryAcctClient(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkHistory>() where _.AccountClientId == @from.Id select _, _ => new WorkHistory {AccountClientId = to.Id});
        }

        async Task UpdateWorkInProgressAssociate(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkInProgress>() where _.AssociateId == @from.Id select _, _ => new WorkInProgress {AssociateId = to.Id});
        }

        async Task UpdateWorkInProgressEmployee(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkInProgress>() where _.StaffId == @from.Id select _, _ => new WorkInProgress {StaffId = to.Id});
        }

        async Task UpdateWorkInProgressAccountClient(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from _ in _dbContext.Set<WorkInProgress>() where _.AccountClientId == @from.Id select _, _ => new WorkInProgress {AccountClientId = to.Id});
        }
    }
}