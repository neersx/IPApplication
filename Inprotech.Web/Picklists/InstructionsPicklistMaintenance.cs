using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Picklists
{
    public interface IInstructionsPicklistMaintenance
    {
        dynamic Save(Instruction instruction, Operation operation);
        dynamic Delete(short instructionId);
    }

    public class InstructionsPicklistMaintenance : IInstructionsPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public InstructionsPicklistMaintenance(IDbContext dbContext,
            ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (lastInternalCodeGenerator == null) throw new ArgumentNullException("lastInternalCodeGenerator");

            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public dynamic Save(Instruction instruction, Operation operation)
        {
            if (instruction == null) throw new ArgumentNullException("instruction");

            var validationErrors = Validate(instruction, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var instructionTypes = _dbContext.Set<EntityModel.InstructionType>().ToArray();

                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.Instruction>()
                                    .Single(_ => _.Id == instruction.Id)
                        : _dbContext.Set<EntityModel.Instruction>()
                                    .Add(new EntityModel.Instruction());

                    if (operation == Operation.Add)
                    {
                        model.Id = (short) _lastInternalCodeGenerator
                            .GenerateLastInternalCode(KnownInternalCodeTable.Instructions);
                    }

                    model.Description = instruction.Description;
                    model.InstructionType = instructionTypes.Single(_ => _.Id == instruction.TypeId);
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

        public dynamic Delete(short instructionId)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    
                    var model = _dbContext
                        .Set<EntityModel.Instruction>()
                        .Single(_ => _.Id == instructionId);

                    _dbContext.Set<EntityModel.Instruction>().Remove(model);

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

        IEnumerable<ValidationError> Validate(Instruction instruction, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.Instruction>().ToArray();

            if (operation == Operation.Update &&
                (!instruction.Id.HasValue || all.All(_ => _.Id != instruction.Id)))
            {
                throw new ArgumentException("Unable to retrieve instruction for update.");
            }

            foreach (var validationError in CommonValidations.Validate(instruction))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != instruction.Id).ToArray() : all;
            if (others.Any(_ => _.Description.IgnoreCaseEquals(instruction.Description)))
            {
                yield return ValidationErrors.NotUnique("description");
            }
        }
    }
}