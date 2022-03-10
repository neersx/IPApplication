using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.ChargeGeneration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Charge
{
    public interface IRatesCommand
    {
        List<BestChargeRates> GetRates(int caseId, int? chargeTypeId);
    }

    public class RatesCommand : IRatesCommand
    {
        readonly IDbContext _dbContext;

        public RatesCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public List<BestChargeRates> GetRates(int caseId, int? chargeTypeId)
        {
            return _dbContext.GetRates(caseId, chargeTypeId);
        }
    }
}
