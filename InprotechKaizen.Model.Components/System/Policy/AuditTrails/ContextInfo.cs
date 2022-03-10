using System.Data;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public class ContextInfo : IContextInfo
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IContextInfoSerializer _serializer;

        public ContextInfo(IDbContext dbContext, ISecurityContext securityContext,
                            IContextInfoSerializer serializer)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _serializer = serializer;
        }

        [SuppressMessage("Microsoft.Naming", "CA2204:Literals should be spelled correctly", MessageId = "bHexNumber")]
        public void EnsureUserContext(int? userId = null, int? transactionInfoId = null, int? batchId = null, int? componentId = null)
        {
            using(var command = _dbContext.CreateSqlCommand("Set CONTEXT_INFO @bHexNumber"))
            {
                var uId = userId ?? _securityContext.User.Id;

                var hexNumber = command.Parameters.Add("@bHexNumber", SqlDbType.VarBinary, 128);
                                       
                hexNumber.Value = _serializer.SerializeContextInfo(uId, transactionInfoId, batchId, componentId);

                command.ExecuteNonQuery();
            }
        }
    }
}