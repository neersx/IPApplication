using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Linq.Expressions;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public interface IAuditLogs
    {
        IQueryable<TAuditEntity> AuditLogRows<TAuditEntity>(Expression<Func<TAuditEntity, bool>> whereExpression) where TAuditEntity : class;
        bool HasAuditEnabled<TAuditEntity>() where TAuditEntity : class;
    }

    public class AuditLogs : IAuditLogs
    {
        readonly IDbContext _dbContext;
        readonly IDbArtifacts _dbArtifacts;

        public AuditLogs(IDbArtifacts dbArtifacts, IDbContext dbContext)
        {
            _dbArtifacts = dbArtifacts;
            _dbContext = dbContext;
        }

        public IQueryable<TAuditEntity> AuditLogRows<TAuditEntity>(Expression<Func<TAuditEntity, bool>> whereExpression) where TAuditEntity : class
        {
            if (HasAuditEnabled<TAuditEntity>())
            {
                return _dbContext.Set<TAuditEntity>().Where(whereExpression);
            }

            return Enumerable.Empty<TAuditEntity>().AsQueryable();
        }

        public bool HasAuditEnabled<TAuditEntity>() where TAuditEntity : class
        {
            var auditTableName = ((TableAttribute)Attribute.GetCustomAttribute(typeof(TAuditEntity), typeof(TableAttribute))).Name;
            var tableName = auditTableName.Replace("_iLog", string.Empty);
            var auditLogRow = Queryable.SingleOrDefault<AuditLogTable>(_dbContext.Set<AuditLogTable>(), _ => _.Name == tableName);
            var hasLoggingTable = _dbArtifacts.Exists(auditTableName, SysObjects.Table, SysObjects.View);
            return hasLoggingTable && (auditLogRow?.IsLoggingRequired ?? false);
        }
    }
}
