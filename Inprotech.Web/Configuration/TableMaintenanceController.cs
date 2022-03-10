using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Extentions;
using InprotechKaizen.Model.Components.Configuration.TableMaintenance;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration
{
    public class TableMaintenanceController<TEntity, TKey> : ApiController
        where TKey : IEquatable<TKey>
        where TEntity : class, ITableMaintenanceEntity<TKey>, new()
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ApplicationTask _task;
        readonly ITableMaintenanceValidator<TKey> _tableMaintenanceValidator;

        public TableMaintenanceController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider,
            ApplicationTask task, ITableMaintenanceValidator<TKey> tableMaintenanceValidator)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");
            if (tableMaintenanceValidator == null) throw new ArgumentNullException("tableMaintenanceValidator");

            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _task = task;
            _tableMaintenanceValidator = tableMaintenanceValidator;
        }

        public virtual dynamic GetAll()
        {
            return new
            {
                EntityList = GetEntities(),
                EntityType = typeof(TEntity).Name,
                ColumnDefinitions = ColumnDefinitions(),
                CanUpdate =
                    _taskSecurityProvider.HasAccessTo(_task,
                        ApplicationTaskAccessLevel.Modify),
                CanDelete =
                    _taskSecurityProvider.HasAccessTo(_task,
                        ApplicationTaskAccessLevel.Delete),
                CanCreate =
                    _taskSecurityProvider.HasAccessTo(_task,
                        ApplicationTaskAccessLevel.Create),
                SortOrder = GetSortOrder()
            };
        }

        public virtual dynamic Get(TKey id)
        {
            return GetDetachedEntity(id);
        }

        public virtual dynamic Delete(TKey id)
        {
            var entity = GetEntity(id);

            var validationResult = _tableMaintenanceValidator.ValidateOnDelete(id);
            if (!validationResult.IsValid) return new { Result = validationResult };

            try
            {
                _dbContext.Set<TEntity>().Remove(entity);
                _dbContext.SaveChanges();
            }
            catch (Exception ex)
            {
                var sqlException = ex.FindInnerException<SqlException>();
                if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                {
                    return
                        new
                        {
                            Result =
                                TableMaintenanceValidationResultHelper.FailureResult(new TableMaintenanceValidationMessage("entityAlreadyInUse", new []{"id"}))
                        };
                }
                throw;
            }

            return new { Result = validationResult };
        }

        public virtual dynamic Put(TKey id, TEntity t)
        {
            var entity = GetEntity(id);

            var validationResult = _tableMaintenanceValidator.ValidateOnPut(entity, t);
            if (!validationResult.IsValid) return new { Result = validationResult };

            foreach (var p in entity.GetType().GetProperties().Where(p => p.CanWrite))
            {
                var propValue = t.GetType().GetProperty(p.Name).GetValue(t);
                entity.GetType().GetProperty(p.Name).SetValue(entity, propValue, null);
            }
            
            _dbContext.SaveChanges();
            return new { Result = validationResult };
        }

        public virtual dynamic Post(TEntity t)
        {
            var validationResult = _tableMaintenanceValidator.ValidateOnPost(t);
            if (!validationResult.IsValid) return new { Result = validationResult };

            _dbContext.Set<TEntity>().Add(t);

            _dbContext.SaveChanges();

            return new { Result = validationResult, Entity = GetDetachedEntity(t.Id) };
        }

        public virtual dynamic ValidateOnDelete(TKey id)
        {
            var validationResult = _tableMaintenanceValidator.ValidateOnDelete(id);
            return new { Result = validationResult };
        }

        public virtual List<ColumnDefinition> ColumnDefinitions()
        {
            return new List<ColumnDefinition>();
        }

        public virtual dynamic GetEagerLoadedEntity(TKey id)
        {
            return GetEntity(id);
        }

        TEntity GetEntity(TKey id)
        {
            var entity = _dbContext.Set<TEntity>().FirstOrDefault(ent => ent.Id.Equals(id));

            if (entity == null)
                HttpResponseExceptionHelper.RaiseNotFound(typeof(TEntity).Name + " not found.");

            return entity;
        }

        TEntity GetDetachedEntity(TKey id)
        {
            var e = (TEntity)GetEagerLoadedEntity(id);
            var c = new TEntity();

            foreach (var p in e.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public).Where(p => p.CanWrite))
            {
                var propValue = e.GetType().GetProperty(p.Name).GetValue(e);

                if (propValue == null) continue;

                if (!propValue.GetType().IsPrimitive && !(propValue is string) && !(propValue is DateTime) && !(propValue is decimal))
                    _dbContext.Detach(propValue);

                c.GetType().GetProperty(p.Name).SetValue(c, propValue, null);
            }

            return c;
        }

        public virtual dynamic GetEntities()
        {
            var entities = _dbContext.Set<TEntity>().ToList();

            if (!entities.Any()) return entities;

            return entities.First().GetType().GetProperties().Any(p => p.GetAccessors()[0].IsVirtual) ?
                entities.Select(entity => GetDetachedEntity(entity.Id)).ToList()
                : entities;
        }

        public virtual dynamic GetSortOrder()
        {
            return new []{"+id"};
        }
    }
}
