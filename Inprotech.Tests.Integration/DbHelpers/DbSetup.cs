using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.DbHelpers
{
    public class DbSetup : IDisposable
    {
        public DbSetup(IDbContext dbContext = null)
        {
            DbContext = dbContext ?? new SqlDbContext();
        }

        internal IDbContext DbContext { get; }

        public virtual void Dispose()
        {
            var sqlDbContext = DbContext as SqlDbContext;

            sqlDbContext?.Dispose();
        }

        public TEntity Insert<TEntity>(TEntity entity) where TEntity : class
        {
            var r = DbContext.Set<TEntity>().Add(entity);

            DbContext.SaveChanges();

            return r;
        }

        public DataEntryTask Insert(DataEntryTask entity)
        {
            var maxId = DbContext.Set<DataEntryTask>()
                                 .OrderByDescending(x => x.Id)
                                 .Select(x => x.Id)
                                 .FirstOrDefault();
            entity.Id = (short) (maxId + 1);

            var r = DbContext.Set<DataEntryTask>().Add(entity);

            DbContext.SaveChanges();

            return r;
        }

        public CaseCategory Insert(CaseCategory entity)
        {
            if (string.IsNullOrEmpty(entity.CaseCategoryId))
            {
                entity.CaseCategoryId = RandomString(2, id => DbContext.Set<CaseCategory>().Any(_ => _.CaseCategoryId == id && _.CaseTypeId == entity.CaseTypeId));
            }

            var r = DbContext.Set<CaseCategory>().Add(entity);

            DbContext.SaveChanges();

            return r;
        }

        /// <summary>
        ///     Create a new entity with a single-column primary key
        /// </summary>
        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        public TEntity InsertWithNewId<TEntity>(TEntity entity, bool useAlphaNumericKey = false) where TEntity : class
        {
            var key = (from p in typeof(TEntity).GetProperties()
                       where p.GetCustomAttributes().OfType<KeyAttribute>().Any()
                       select new
                              {
                                  Property = p,
                                  TableName = typeof(TEntity).GetCustomAttributes().OfType<TableAttribute>().Select(x => x.Name).FirstOrDefault(),
                                  ColumnName = p.GetCustomAttributes().OfType<ColumnAttribute>().Select(x => x.Name).FirstOrDefault(),
                                  MaxLength = p.GetCustomAttributes().OfType<MaxLengthAttribute>().Select(x => x.Length).FirstOrDefault()
                              }).SingleOrDefault();

            if (key == null) throw new Exception("Cannot find key property on type " + typeof(TEntity));
            
            object id;
            if (key.Property.PropertyType == typeof(string))
            {
                if (key.Property.PropertyType == typeof(string) && key.MaxLength < 1)
                {
                    throw new Exception("Unable to find MaxLengthAttribute associated with string identity column");
                }

                id = RandomString(key.MaxLength,
                                  x => DbContext.SqlQuery<int>("SELECT CASE WHEN EXISTS(SELECT 1 FROM " + key.TableName + " where " + key.ColumnName + "={0}) then 1 else 0 end", x)
                                                .Single() == 1, useAlphaNumericKey);
            }
            else
            {
                var ctx = (SqlDbContext) DbContext;
                var conn = (SqlConnection) ctx.Database.Connection;
                if (conn.State != ConnectionState.Open) conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT ISNULL(MAX(" + key.ColumnName + ")+1, 0) FROM " + key.TableName;
                    var obj = cmd.ExecuteScalar();
                    id = Convert.ChangeType(obj, key.Property.PropertyType);
                }
            }

            key.Property.SetValue(entity, id, null);

            var r = DbContext.Set<TEntity>().Add(entity);

            DbContext.SaveChanges();

            UpdateLastInternalCode(key);

            return r;
        }
        
        public TEntity InsertWithNewAlphaNumericId<TEntity>(TEntity entity) where TEntity : class
        {
            return InsertWithNewId(entity, true);
        }

        /// <summary>
        /// Insert entry with specific key generation and exists checking
        /// </summary>
        /// <typeparam name="TEntity"></typeparam>
        /// <param name="generateEntityFunc">Func to generate the entity</param>
        /// <param name="existsCheck">Func to check if entity already exists. NOTE: use .ToUpper() because db is case insensitive.</param>
        /// <param name="maxRetries">Maximum number of retries</param>
        /// <returns></returns>
        public TEntity InsertWithRetry<TEntity>(Func<TEntity> generateEntityFunc, Func<TEntity, TEntity, bool> existsCheck, short maxRetries = 10) where TEntity : class
        {
            var entity = generateEntityFunc();
            var existing = DbContext.Set<TEntity>().ToArray();
            for (var i = 0; i <= maxRetries; i++)
            {
                if (!existing.Any(_ => existsCheck(_, entity)))
                    break;

                if (i == maxRetries)
                    throw new Exception($"Could not generate entity {typeof(TEntity).Name} within {maxRetries} attempts.");

                entity = generateEntityFunc();
            }

            return Insert(entity);
        }

        public TEntity InsertWithNewId<TEntity>(TEntity entity, Expression<Func<TEntity, string>> keyPropertySelector, int maxLength = 1, bool useAlphaNumeric = false) where TEntity : class
        {
            var expr = keyPropertySelector.Body as MemberExpression ?? (MemberExpression)((UnaryExpression)keyPropertySelector.Body).Operand;

            var property = (PropertyInfo)expr.Member;
            
            var key = new
            {
                TableName = typeof(TEntity).GetCustomAttributes().OfType<TableAttribute>().Select(x => x.Name).FirstOrDefault(),
                ColumnName = property.GetCustomAttributes().OfType<ColumnAttribute>().Select(x => x.Name).FirstOrDefault()
            };

            var id = RandomString(maxLength,
                                    x => DbContext.SqlQuery<int>("SELECT CASE WHEN EXISTS(SELECT 1 FROM " + key.TableName + " where " + key.ColumnName + "={0}) then 1 else 0 end", x)
                                                .Single() == 1, useAlphaNumeric);

            property.SetValue(entity, id, null);
         
            var r = DbContext.Set<TEntity>().Add(entity);

            DbContext.SaveChanges();

            UpdateLastInternalCode(key);

            return r;
        }

        public TEntity InsertWithNewId<TEntity>(TEntity entity, Expression<Func<TEntity, short?>> keyPropertySelector, Expression<Func<TEntity, bool>> whereExpression = null) where TEntity : class
        {
            var expr = keyPropertySelector.Body as MemberExpression ?? (MemberExpression)((UnaryExpression)keyPropertySelector.Body).Operand;

            var property = (PropertyInfo)expr.Member;

            var key = new
            {
                TableName = typeof(TEntity).GetCustomAttributes().OfType<TableAttribute>().Select(x => x.Name).FirstOrDefault(),
                ColumnName = property.GetCustomAttributes().OfType<ColumnAttribute>().Select(x => x.Name).FirstOrDefault()
            };

            var entities = whereExpression != null
                ? DbContext.Set<TEntity>().Where(whereExpression)
                : DbContext.Set<TEntity>();

            var max = (short)((entities.DefaultIfEmpty().Max(keyPropertySelector) ?? 0) + 1);

            property.SetValue(entity, max, null);
        
            var r = DbContext.Set<TEntity>().Add(entity);

            DbContext.SaveChanges();

            UpdateLastInternalCode(key);

            return r;
        }

        public TEntity InsertWithNewId<TEntity>(TEntity entity, Expression<Func<TEntity, int?>> keyPropertySelector, Expression<Func<TEntity, bool>> whereExpression = null) where TEntity : class
        {
            var expr = keyPropertySelector.Body as MemberExpression ?? (MemberExpression)((UnaryExpression)keyPropertySelector.Body).Operand;

            var property = (PropertyInfo)expr.Member;

            var key = new
            {
                TableName = typeof(TEntity).GetCustomAttributes().OfType<TableAttribute>().Select(x => x.Name).FirstOrDefault(),
                ColumnName = property.GetCustomAttributes().OfType<ColumnAttribute>().Select(x => x.Name).FirstOrDefault()
            };

            var entities = whereExpression != null
                ? DbContext.Set<TEntity>().Where(whereExpression)
                : DbContext.Set<TEntity>();

            var max = (entities.DefaultIfEmpty().Max(keyPropertySelector) ?? 0) + 1;

            property.SetValue(entity, max, null);
        
            var r = DbContext.Set<TEntity>().Add(entity);

            DbContext.SaveChanges();

            UpdateLastInternalCode(key);

            return r;
        }

        void UpdateLastInternalCode(dynamic key)
        {
            var ctx = (SqlDbContext) DbContext;
            var conn = (SqlConnection) ctx.Database.Connection;
            if (conn.State != ConnectionState.Open) conn.Open();
            using (var cmd = conn.CreateCommand())
            {
                cmd.CommandText = $@"
if exists (select * from LASTINTERNALCODE where TABLENAME = '{key.TableName}')
begin
    Update LASTINTERNALCODE
    set     INTERNALSEQUENCE = (select ISNULL(max({key.ColumnName}), 500) from {key.TableName})
    where TABLENAME = '{key.TableName}'
end";
                cmd.ExecuteNonQuery();
            }
        }

        public void Delete<T>(T entity) where T : class
        {
            DbContext.Set<T>().Remove(entity);
            DbContext.SaveChanges();
        }

        public static T Do<T>(Func<DbSetup, T> func)
        {
            using (var setup = new DbSetup())
            {
                return func(setup);
            }
        }

        public static void Do(Action<DbSetup> action)
        {
            using (var setup = new DbSetup())
            {
                action(setup);
            }
        }

        static string RandomString(int length, Func<string, bool> shouldRetry, bool useAlphaNumeric = false)
        {
            var ignores = new List<string>();

            for (var i = 0; i < 16; i++)
            {
                var str = useAlphaNumeric ? Fixture.AlphaNumericString(length, ignores) : Fixture.String(length, ignores);

                if (str == null)
                {
                    break;
                }

                if (!shouldRetry(str))
                {
                    return str;
                }

                ignores.Add(str);
            }

            throw new Exception("Failed to generate new random string");
        }
    }
}