using System.Data.SqlClient;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IDerivedAttention
    {
        Task<int> Recalculate(int userIdentityId,
                              int mainNameKey,
                              int? oldAttentionKey = null, int? newAttentionKey = null, int? associatedNameKey = null, string associatedRelation = null, short? associatedSequence = null);
    }

    public class DerivedAttention : IDerivedAttention
    {
        readonly IDbContext _dbContext;

        public DerivedAttention(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<int> Recalculate(int userIdentityId,
                                           int mainNameKey,
                                           int? oldAttentionKey = null, int? newAttentionKey = null, int? associatedNameKey = null, string associatedRelation = null, short? associatedSequence = null)
        {
            using (var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.RecalculateDerivedAttention))
            {
                command.Parameters.AddRange(
                                            new[]
                                            {
                                                new SqlParameter("@pnRowCount", null),
                                                new SqlParameter("@pnUserIdentityId", userIdentityId),
                                                new SqlParameter("@pnMainNameKey", mainNameKey),
                                                new SqlParameter("@pnNewAttentionKey", newAttentionKey),
                                                new SqlParameter("@pnOldAttentionKey", oldAttentionKey),
                                                new SqlParameter("@psAssociatedRelation", associatedRelation),
                                                new SqlParameter("@pnAssociatedNameKey", associatedNameKey),
                                                new SqlParameter("@pnAssociatedSequence", associatedSequence),
                                                new SqlParameter("@pbCalledFromCentura", false)
                                            });

                return await command.ExecuteNonQueryAsync();
            }
        }
    }
}