using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.System.Compatibility;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IDefaultTaxCodeResolver
    {
        Task<string> Resolve(int userIdentityId, string culture, int debtorId, int? caseId, string wipCode, int? staffId, int? entityId);
    }

    public class DefaultTaxCodeResolver : IDefaultTaxCodeResolver
    {
        readonly IDbContext _dbContext;
        readonly IStoredProcedureParameterHandler _compatibleParameterHandler;

        public DefaultTaxCodeResolver(IDbContext dbContext, IStoredProcedureParameterHandler compatibilityHandler)
        {
            _dbContext = dbContext;
            _compatibleParameterHandler = compatibilityHandler;
        }

        public async Task<string> Resolve(int userIdentityId, string culture, int debtorId, int? caseId, string wipCode, int? staffId, int? entityId)
        {
            var parameters = new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@pnCaseKey", caseId },
                { "@psWIPCode", wipCode },
                { "@pnDebtorKey", debtorId },
                { "@pnStaffKey", staffId },
                { "@pnEntityKey", entityId }
            };

            _compatibleParameterHandler.Handle(StoredProcedures.Billing.GetDefaultTaxCodeForWip, parameters);

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetDefaultTaxCodeForWip, parameters);

            return await command.ExecuteScalarAsync() as string;
        }
    }
}
