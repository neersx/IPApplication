using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Picklists
{
    public interface IInstructionTypesPicklistMaintenance
    {
        dynamic Save(InstructionType instructionType, Operation operation);
        dynamic Delete(int typeId);
    }

    public class InstructionTypesPicklistMaintenance : IInstructionTypesPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public InstructionTypesPicklistMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public dynamic Save(InstructionType instructionType, Operation operation)
        {
            if (instructionType == null) throw new ArgumentNullException("instructionType");

            var validationErrors = Validate(instructionType, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {

                    var nameTypes = _dbContext.Set<NameType>().ToArray();

                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.InstructionType>()
                                    .Single(_ => _.Id == instructionType.Key)
                        : _dbContext.Set<EntityModel.InstructionType>()
                                    .Add(new EntityModel.InstructionType
                                             {
                                                 Code = instructionType.Code
                                             });

                    model.Description = instructionType.Value;
                    model.NameType = nameTypes.Single(_ => _.NameTypeCode == instructionType.RecordedAgainstId);
                    model.RestrictedByType =
                        string.IsNullOrWhiteSpace(instructionType.RestrictedById)
                            ? null
                            : nameTypes.SingleOrDefault(_ => _.NameTypeCode == instructionType.RestrictedById);

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                               {
                                   Result = "success",
                                   Key = model.Id
                               };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(int typeId)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    
                    var model = _dbContext
                        .Set<EntityModel.InstructionType>()
                        .Single(_ => _.Id == typeId);

                    _dbContext.Set<EntityModel.InstructionType>().Remove(model);

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

        IEnumerable<ValidationError> Validate(InstructionType instructionType, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.InstructionType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != instructionType.Key))
            {
                throw new ArgumentException("Unable to retrieve instruction type for update.");
            }
            
            foreach (var validationError in CommonValidations.Validate(instructionType))
                yield return validationError;
            
            var others = operation == Operation.Update ? all.Where(_ => _.Id != instructionType.Key).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(instructionType.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Description.IgnoreCaseEquals(instructionType.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}