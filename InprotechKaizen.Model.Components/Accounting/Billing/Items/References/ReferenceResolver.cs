using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.References
{
    public interface IReferenceResolver
    {
        Task<BillReference> Resolve(int userIdentityId, string culture, int[] caseIds, int? languageId, bool useRenewalDebtor, int? debtorId, string openItemNo);
    }

    public class ReferenceResolver : IReferenceResolver
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly ISiteControlReader _siteControlReader;

        public ReferenceResolver(IDbContext dbContext, IDocItemRunner docItemRunner, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _docItemRunner = docItemRunner;
            _siteControlReader = siteControlReader;
        }
        
        public async Task<BillReference> Resolve(int userIdentityId, string culture, int[] caseIds, int? languageId, bool useRenewalDebtor, int? debtorId, string openItemNo)
        {
            var dataItems = _siteControlReader.ReadMany<string>(
                                                                SiteControls.BillRef_Single,
                                                                SiteControls.BillRef_Multi0,
                                                                SiteControls.BillRef_Multi1,
                                                                SiteControls.BillRef_Multi2,
                                                                SiteControls.BillRef_Multi3,
                                                                SiteControls.BillRef_Multi4,
                                                                SiteControls.BillRef_Multi5,
                                                                SiteControls.BillRef_Multi6,
                                                                SiteControls.BillRef_Multi7,
                                                                SiteControls.BillRef_Multi8,
                                                                SiteControls.BillRef_Multi9,
                                                                SiteControls.Statement_Single,
                                                                SiteControls.Statement_Multi0,
                                                                SiteControls.Statement_Multi1,
                                                                SiteControls.Statement_Multi2,
                                                                SiteControls.Statement_Multi3,
                                                                SiteControls.Statement_Multi4,
                                                                SiteControls.Statement_Multi5,
                                                                SiteControls.Statement_Multi6,
                                                                SiteControls.Statement_Multi7,
                                                                SiteControls.Statement_Multi8,
                                                                SiteControls.Statement_Multi9);

            var caseInfo = await (from c in _dbContext.Set<Case>()
                                  where caseIds.Contains(c.Id)
                                  select new { c.Id, c.Irn })
                .ToDictionaryAsync(k => k.Id, v => v.Irn);

            var debtorNameType = useRenewalDebtor
                ? KnownNameTypes.RenewalsDebtor
                : KnownNameTypes.Debtor;

            var billReference = new BillReference();

            if (caseIds.Length == 1)
            {
                var mainCaseRef = caseInfo[caseIds.First()];

                if (TryResolve(userIdentityId, culture,
                               mainCaseRef,
                               dataItems.Get(SiteControls.BillRef_Single),
                               debtorNameType, languageId, debtorId, openItemNo, out var billRefText))
                {
                    billReference.ReferenceText = billRefText;
                }

                if (TryResolve(userIdentityId, culture,
                               mainCaseRef,
                               dataItems.Get(SiteControls.Statement_Single),
                               debtorNameType, languageId, debtorId, openItemNo, out var statementRefText))
                {
                    billReference.StatementText = statementRefText;
                }
            }
            else
            {
                var allCaseRefCsv = string.Join(",", caseIds.Select(id => caseInfo[id]));
                var mainCaseRef = caseInfo[caseIds.First()];
                var billRefMulti = SiteControls.BillRef_Multi0.TrimEnd('0');
                var statementRefMulti = SiteControls.Statement_Multi0.TrimEnd('0');

                var allBillRefs = new List<string>();
                var allStatementRefs = new List<string>();

                foreach (var billRefMultiDataItem in dataItems.Where(_ => _.Key.StartsWith(billRefMulti)))
                {
                    if (string.IsNullOrWhiteSpace(billRefMultiDataItem.Value))
                    {
                        continue;
                    }

                    if (TryResolve(userIdentityId, culture,
                                   UseMainCaseRefOnly(billRefMultiDataItem.Key) ? mainCaseRef : allCaseRefCsv,
                                   billRefMultiDataItem.Value,
                                   debtorNameType, languageId, debtorId, openItemNo, out var billRefText))
                    {
                        allBillRefs.Add(billRefText);
                    }
                }

                foreach (var statementRefMultiDataItem in dataItems.Where(_ => _.Key.StartsWith(statementRefMulti)))
                {
                    if (string.IsNullOrWhiteSpace(statementRefMultiDataItem.Value))
                    {
                        continue;
                    }

                    if (TryResolve(userIdentityId, culture,
                                   UseMainCaseRefOnly(statementRefMultiDataItem.Key) ? mainCaseRef : allCaseRefCsv,
                                   statementRefMultiDataItem.Value,
                                   debtorNameType, languageId, debtorId, openItemNo, out var statementRefText))
                    {
                        allStatementRefs.Add(statementRefText);
                    }
                }

                billReference.ReferenceText = allBillRefs.Any() ? string.Join(Environment.NewLine, allBillRefs) : null;
                billReference.StatementText = allStatementRefs.Any() ? string.Join(Environment.NewLine, allStatementRefs) : null;
            }

            return billReference;
        }

        bool TryResolve(int userIdentityId, string culture,
                        string caseRef, string dataItem,
                        string nameType, int? languageId, int? debtorId, string openItemNo,
                        out string result)
        {
            result = null;

            if (string.IsNullOrWhiteSpace(dataItem))
            {
                return false;
            }

            var parameters = DefaultDocItemParameters.ForDocItemSqlQueries(caseRef, userIdentityId, culture);
            parameters["p1"] = languageId;
            parameters["p2"] = nameType;
            parameters["p3"] = debtorId;
            parameters["p4"] = openItemNo;

            var results = _docItemRunner.Run(dataItem, parameters)
                                        .MultipleScalarValueOrDefault<string>()
                                        .ToArray();

            result = string.Join(Environment.NewLine, results);

            return !string.IsNullOrWhiteSpace(result);
        }

        static bool UseMainCaseRefOnly(string siteControlName)
        {
            return siteControlName.EndsWith("0") || siteControlName.EndsWith("9");
        }
    }
}