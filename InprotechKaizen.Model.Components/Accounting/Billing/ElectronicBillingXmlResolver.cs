using System.Data.Common;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IElectronicBillingXmlResolver
    {
        Task<ElectronicBillingData> Resolve(int userIdentityId, string culture, string openItemNo, int itemEntityId);
    }

    public class ElectronicBillingXmlResolver : IElectronicBillingXmlResolver
    {
        readonly IDbContext _dbContext;

        public ElectronicBillingXmlResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<ElectronicBillingData> Resolve(int userIdentityId, string culture, string openItemNo, int itemEntityId)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetEBillingXml,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", itemEntityId},
                                                                            {"@psOpenItemNo", openItemNo}
                                                                        });

            var data = new ElectronicBillingData();

            using var dr = await command.ExecuteReaderAsync();

            data.Header = await ReadHeader(dr);

            data.BillLine = await ReadBillLine(dr);

            data.Tax = await ReadTax(dr);

            data.CaseDataItem = await ReadCaseDataItem(dr);

            data.CopyTo = await ReadCopyTo(dr);

            return data;
        }

        static async Task<string> ReadHeader(DbDataReader dr)
        {
            if (await dr.ReadAsync())
            {
                return dr.GetString(0);
            }

            return null;
        }

        static async Task<string> ReadCopyTo(DbDataReader dr)
        {
            return await ReadFromNextResultSetAsync(dr);
        }

        static async Task<string> ReadCaseDataItem(DbDataReader dr)
        {
            return await ReadFromNextResultSetAsync(dr);
        }

        static async Task<string> ReadTax(DbDataReader dr)
        {
            return await ReadFromNextResultSetAsync(dr);
        }

        static async Task<string> ReadBillLine(DbDataReader dr)
        {
            return await ReadFromNextResultSetAsync(dr);
        }

        static async Task<string> ReadFromNextResultSetAsync(DbDataReader reader)
        {
            if (await reader.NextResultAsync() && await reader.ReadAsync())
            {
                return reader.IsDBNull(0) ? null : reader.GetString(0);
            }

            return null;
        }
    }

    public class ElectronicBillingData
    {
        public string Header { get; set; }

        public string BillLine { get; set; }
        
        public string Tax { get; set; }
        
        public string CopyTo { get; set; }
        
        public string CaseDataItem { get; set; }
    }
}
