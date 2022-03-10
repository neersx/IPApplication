using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class ReverseBatchDbSetup : DbSetup
    {
        public bool TurnOnLoggingForCases()
        {
            var cases = DbContext.Set<AuditLogTable>().Single(_ => _.Name == "CASES");

            if (cases.IsLoggingRequired)
            {
                return false;
            }

            cases.IsLoggingRequired = true;
            DbContext.SaveChanges();

            return true;
        }

        public void TurnOffLoggingForCases()
        {
            var cases = DbContext.Set<AuditLogTable>().Single(_ => _.Name == "CASES");

            cases.IsLoggingRequired = false;

            DbContext.SaveChanges();
        }

        public (int BatchId, string BatchName, int[] CaseIds) CreateBatch(int userId)
        {
            int[] tableCodes =
            {
                EdeBatchStatus.Unprocessed,
                (int) ProcessRequestStatus.Processing,
                (int) TransactionStatus.Processed,
                (int) TransactionStatus.OperatorReview,
                (int) TransactionStatus.UnmappedCodes,
                (int) TransactionStatus.UnresolvedNames
            };

            var now = DateTime.Now;

            using (var tcs = DbContext.BeginTransaction())
            {
                var cdRowId = DbContext.Set<EdeCaseDetails>().DefaultIfEmpty().Max(_ => _.RowId) + 1;

                var codes = DbContext.Set<TableCode>()
                                     .Where(tc => tableCodes.Contains(tc.Id))
                                     .ToDictionary(k => k.Id, v => v);

                var processed = codes[(int)TransactionStatus.Processed];

                var unprocessed = codes[EdeBatchStatus.Unprocessed];

                var th = Insert(new EdeTransactionHeader { BatchStatus = unprocessed });

                EnsureCasesCreatedAreLoggedWithBatchId(userId, now, th.BatchId);

                var ids = new List<int>();

                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseAmended, processed, CreateCaseDetail("AU", "D", cdRowId++, "T@", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseAmended, processed, CreateCaseDetail("AU", "D", cdRowId++, "T1", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseRejected, processed, CreateCaseDetail("US", "D", cdRowId++, "T2", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.NoChangesMade, processed, CreateCaseDetail("DE", "P", cdRowId++, "T3", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.NoChangesMade, processed, CreateCaseDetail("NZ", "P", cdRowId++, "T4", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.OperatorReview], CreateCaseDetail("NZ", "P", cdRowId++, "T5", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnmappedCodes], CreateCaseDetail("NZ", "P", cdRowId++, "T6", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnresolvedNames], CreateCaseDetail("NZ", "P", cdRowId++, "T7", ids)));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnresolvedNames], CreateCaseDetail("NZ", "P", cdRowId, "T8", ids)));

                DbContext.SaveChanges();

                Insert(new EdeOutstandingIssues
                {
                    BatchId = th.BatchId,
                    StandardIssue = DbContext.Set<EdeStandardIssues>().Single(_ => _.Id == Issues.UnmappedCode)
                });

                var nameNo = DbContext.Set<Name>()
                                      .SingleOrDefault(n => n.NameCode == KnownNameWithAliasTypes.NameCodeWithAliasTypesE);

                var batchName = "E2E Batch - Reverse Test";

                Insert(new EdeSenderDetails
                {
                    LastModified = now,
                    Sender = "MYAC",
                    SenderRequestIdentifier = batchName,
                    SenderNameNo = nameNo?.Id,
                    SenderRequestType = KnownSenderRequestTypes.CaseImport,
                    TransactionHeader = th
                });

                Insert(new ProcessRequest
                {
                    User = "dbo",
                    Context = ProcessRequestContexts.ElectronicDataExchange,
                    RequestType = "EDE Resubmit Batch",
                    RequestDescription = "E2E Test",
                    Status = codes[(int)ProcessRequestStatus.Processing],
                    BatchId = th.BatchId
                });

                tcs.Complete();

                return (th.BatchId, batchName, ids.ToArray());
            }
        }

        void EnsureCasesCreatedAreLoggedWithBatchId(int userId, DateTime now, int batchId)
        {
            /* this is critical for reversal,
             because the reversal will pick cases created for a batch id to reverse */

            var transactionInfo = Insert(new TransactionInfo(now, batchId));

            var user = DbContext.Set<User>().Single(_ => _.Id == userId);

            var contextInfo = new ContextInfo(DbContext, new E2ESecurityContext(user), new ContextInfoSerializer(DbContext));
            contextInfo.EnsureUserContext(transactionInfoId: transactionInfo.Id, batchId: batchId);
        }

        static EdeTransactionBody WithTransactionBody(int? batchId, string returnCode, TableCode tableCode,
                                                      EdeCaseDetails caseDetails)
        {
            return new EdeTransactionBody
            {
                TransactionReturnCode = returnCode,
                TransactionStatus = tableCode,
                CaseDetails = caseDetails,
                BatchId = batchId,
                CaseMatch = null,
                TransactionIdentifier = Guid.NewGuid().ToString()
            };
        }

        EdeCaseDetails CreateCaseDetail(string countryCode, string propertyCode, int rowId, string irn, List<int> ids)
        {
            var caseId = GetCase(irn).Id;

            ids.Add(caseId);

            return new EdeCaseDetails
            {
                CaseCountryCode = countryCode,
                CasePropertyTypeCode = propertyCode,
                RowId = rowId,
                CaseId = caseId
            };
        }

        Case GetCase(string irn)
        {
            var prefixedIrn = Fixture.Prefix(irn);
            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn);
        }

        class E2ESecurityContext : ISecurityContext
        {
            public E2ESecurityContext(User user)
            {
                User = user;
            }

            public User User { get; }

            public int IdentityId => User.Id;
        }
    }
}