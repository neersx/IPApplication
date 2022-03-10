using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    public interface IDeliveryDestinationResolver
    {
        Task<DeliveryDestination> Resolve(int activityId, int caseId, short letterId);

        Task<DeliveryDestination> ResolveForCaseNames(int? caseId, int? nameId, short letterId);
    }

    public class DeliveryDestinationResolver : IDeliveryDestinationResolver
    {
        readonly IDbContext _dbContext;
        readonly IDeliveryDestinationStoredProcedureRunner _deliveryDestinationStoredProcedureRunner;

        public DeliveryDestinationResolver(IDbContext dbContext, IDeliveryDestinationStoredProcedureRunner deliveryDestinationStoredProcedureRunner)
        {
            _dbContext = dbContext;
            _deliveryDestinationStoredProcedureRunner = deliveryDestinationStoredProcedureRunner;
        }

        public async Task<DeliveryDestination> Resolve(int activityId, int caseId, short letterId)
        {
            return await ResolveInternal(activityId, caseId, null, letterId);
        }

        public async Task<DeliveryDestination> ResolveForCaseNames(int? caseId, int? nameId, short letterId)
        {
            return await ResolveInternal(null, caseId, nameId, letterId);
        }

        async Task<DeliveryDestination> ResolveInternal(int? activityId, int? caseId, int? nameId, short letterId)
        {
            var details = await (from dm in _dbContext.Set<DeliveryMethod>()
                                 join l in _dbContext.Set<Document>() on dm.Id equals l.DeliveryMethodId into l1
                                 from l in l1
                                 where l.Id == letterId
                                 select new
                                 {
                                     dm.DestinationStoredProcedure,
                                     dm.FileDestination
                                 }).SingleOrDefaultAsync();

            if (details == null)
            {
                return new DeliveryDestination();
            }

            if (!string.IsNullOrWhiteSpace(details.FileDestination))
            {
                return new DeliveryDestination
                {
                    DirectoryName = details.FileDestination
                };
            }

            if (!string.IsNullOrWhiteSpace(details.DestinationStoredProcedure))
            {
                return await _deliveryDestinationStoredProcedureRunner.Run(caseId, nameId, letterId, activityId, details.DestinationStoredProcedure);
            }

            return new DeliveryDestination();
        }
    }
}