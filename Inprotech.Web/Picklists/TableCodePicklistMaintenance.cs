using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public static class TableTypeHelper
    {
        internal static short MatchingType(string tableTypeName)
        {
            short matchingType;
            TableTypes tableTypeId;
            ProtectedTableTypes protectedTableTypeId;

            if (Enum.TryParse(tableTypeName, true, out tableTypeId))
                matchingType = (short)tableTypeId;
            else if (Enum.TryParse(tableTypeName, true, out protectedTableTypeId))
                matchingType = (short)protectedTableTypeId;
            else
                throw new ArgumentException("The tabletype does not exist.");
            return matchingType;
        }
    }

    public interface ITableCodePicklistMaintenance
    {
        dynamic Update(TableCodePicklistController.TableCodePicklistItem tableCode);
        dynamic Add(TableCodePicklistController.TableCodePicklistItem tableCode);
        dynamic Delete(int tableCode);
    }

    public class TableCodePicklistMaintenance : ITableCodePicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly ISqlHelper _sqlHelper;

        public TableCodePicklistMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator, ISqlHelper sqlHelper)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _sqlHelper = sqlHelper;
        }

        public dynamic Update(TableCodePicklistController.TableCodePicklistItem tableCode)
        {
            if (tableCode == null) throw new ArgumentNullException(nameof(tableCode));

            var validationErrors = Validate(tableCode).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();

            using (var tcs = _dbContext.BeginTransaction())
            {
                var model = _dbContext.Set<TableCode>().SingleOrDefault(_ => _.Id == tableCode.Key);
                if (model == null) throw new ArgumentNullException();

                model.Name = tableCode.Value;
                model.UserCode = tableCode.Code;
                _dbContext.SaveChanges();
                tcs.Complete();

                return new
                {
                    Result = "success",
                    Key = model.Id
                };
            }
        }

        public dynamic Add(TableCodePicklistController.TableCodePicklistItem tableCode)
        {
            if (tableCode == null) throw new ArgumentNullException(nameof(tableCode));

            var matchingType = TableTypeHelper.MatchingType(tableCode.Type);

            var validationErrors = ValidateNew(matchingType, tableCode).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();

            using (var tcs = _dbContext.BeginTransaction())
            {
                var tableCodeId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.TableCodes);
                var model = new TableCode(tableCodeId,
                                          matchingType,
                                          tableCode.Value,
                                          tableCode.Code);

                _dbContext.Set<TableCode>().Add(model);

                _dbContext.SaveChanges();
                tcs.Complete();

                return new
                {
                    Result = "success",
                    Key = model.Id
                };
            }
        }

        bool IsValidProcedureName(TableCodePicklistController.TableCodePicklistItem tableCode)
        {
            return _sqlHelper.IsValidProcedureName(tableCode.Value);
        }

        IEnumerable<ValidationError> ValidateNew(short tableType, TableCodePicklistController.TableCodePicklistItem tableCode)
        {
            if (tableCode.Value.Length > 80)
                yield return ValidationErrors.SetError("value", "maxlength");

            if (tableCode.Code?.Length > 50)
                yield return ValidationErrors.SetError("code", "maxlength");

            if (_dbContext.Set<TableCode>().Any(_ => _.TableTypeId == tableType && _.Name == tableCode.Value))
            {
                yield return ValidationErrors.NotUnique("value");
            }
            if (tableType == KnownAdditionalNumberPatternTypes.AdditionalNumberPatternValidation && !IsValidProcedureName(tableCode))
            {
                yield return ValidationErrors.SetError(null, "value", "field.errors.invalidproc", true);
            }
        }
        IEnumerable<ValidationError> Validate(TableCodePicklistController.TableCodePicklistItem tableCode)
        {
            if (tableCode.Value.Length > 80)
                yield return ValidationErrors.SetError("value", "maxlength");

            if (tableCode.Code?.Length > 50)
                yield return ValidationErrors.SetError("code", "maxlength");

            if (_dbContext.Set<TableCode>().Any(_ => _.TableTypeId == tableCode.TypeId && _.Name == tableCode.Value && _.Id != tableCode.Key))
            {
                yield return ValidationErrors.NotUnique("value");
            }

            if (tableCode.TypeId == KnownAdditionalNumberPatternTypes.AdditionalNumberPatternValidation && !IsValidProcedureName(tableCode))
            {
                yield return ValidationErrors.SetError(null, "value", "field.errors.invalidproc", true);
            }
        }

        public dynamic Delete(int tableCode)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<TableCode>()
                        .SingleOrDefault(_ => _.Id == tableCode);

                    if (model == null) throw new ArgumentNullException();

                    _dbContext.Set<TableCode>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }
    }
}