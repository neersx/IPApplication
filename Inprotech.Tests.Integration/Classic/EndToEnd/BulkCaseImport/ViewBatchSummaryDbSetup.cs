using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class ViewBatchSummaryDbSetup : DbSetup
    {
        public Tuple<int, Dictionary<string, int>> CreateBatch()
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

            using (var tcs = DbContext.BeginTransaction())
            {
                var cdRowId = DbContext.Set<EdeCaseDetails>().DefaultIfEmpty().Max(_ => _.RowId) + 1;

                var codes = DbContext.Set<TableCode>()
                                     .Where(tc => tableCodes.Contains(tc.Id))
                                     .ToDictionary(k => k.Id, v => v);

                var processed = codes[(int)TransactionStatus.Processed];

                var unprocessed = codes[EdeBatchStatus.Unprocessed];

                var th = Insert(new EdeTransactionHeader
                {
                    BatchStatus = unprocessed
                });

                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseAmended, processed, CreateCaseDetail("AU", "D", cdRowId++, "T@")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseAmended, processed, CreateCaseDetail("AU", "D", cdRowId++, "T1")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.CaseRejected, processed, CreateCaseDetail("US", "D", cdRowId++, "T2")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.NoChangesMade, processed, CreateCaseDetail("DE", "P", cdRowId++, "T3")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, TransactionReturnCodes.NoChangesMade, processed, CreateCaseDetail("NZ", "P", cdRowId++, "T4")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.OperatorReview], CreateCaseDetail("NZ", "P", cdRowId++, "T5")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnmappedCodes], CreateCaseDetail("NZ", "P", cdRowId++, "T6")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnresolvedNames], CreateCaseDetail("NZ", "P", cdRowId++, "T7")));
                th.TransactionBodies.Add(WithTransactionBody(th.BatchId, null, codes[(int)TransactionStatus.UnresolvedNames], CreateCaseDetail("NZ", "P", cdRowId, "T8")));

                DbContext.SaveChanges();

                Insert(new EdeOutstandingIssues
                {
                    BatchId = th.BatchId,
                    StandardIssue = DbContext.Set<EdeStandardIssues>().Single(_ => _.Id == Issues.UnmappedCode)
                });

                var nameNo = DbContext.Set<Name>()
                                      .SingleOrDefault(n => n.NameCode == KnownNameWithAliasTypes.NameCodeWithAliasTypesE);

                Insert(new EdeSenderDetails
                {
                    LastModified = DateTime.Now,
                    Sender = "MYAC",
                    SenderRequestIdentifier = "E2E Batch - 911",
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

                return new Tuple<int, Dictionary<string, int>>(th.BatchId, new Dictionary<string, int>
                                                                           {
                                                                               {"amended", 2},
                                                                               {"rejected", 1},
                                                                               {"unchanged", 2},
                                                                               {"total", 9},
                                                                               {"incomplete", 1},
                                                                               {"mapping-issues", 1},
                                                                               {"name-issues", 2}
                                                                           });
            }
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

        EdeCaseDetails CreateCaseDetail(string countryCode, string propertyCode, int rowId, string irn = null)
        {
            var caseId = string.IsNullOrWhiteSpace(irn) ? (int?)null : GetCase(irn).Id;

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
    }
}