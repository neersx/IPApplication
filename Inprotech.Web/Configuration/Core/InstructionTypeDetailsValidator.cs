using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Configuration.Core
{
    public interface IInstructionTypeDetailsValidator
    {
        bool Validate(string typecode, DeltaInstructionTypeDetails d, out ValidationResult result);
    }

    public class InstructionTypeDetailsValidator : IInstructionTypeDetailsValidator
    {
        readonly IDbContext _dbContext;

        public InstructionTypeDetailsValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool Validate(string typecode, DeltaInstructionTypeDetails details, out ValidationResult result)
        {
            if (details == null) throw new ArgumentNullException(nameof(details));

            result = ValidateInstructionType(typecode);
            if (result != null)
            {
                return false;
            }

            result = ValidateInstructions(typecode, details.Instructions) ?? ValidateCharacteristics(typecode, details.Characteristics);

            return result == null;
        }

        static ValidationResult ValidateInstructionType(string typeCode)
        {
            if (string.IsNullOrEmpty(typeCode))
            {
                return ValidationResult.Error(Resources.InstructionTypeNotFound, null);
            }

            return null;
        }

        ValidationResult ValidateInstructions(string typecode, Delta<DeltaInstruction> details)
        {
            var errors = CheckUniquenessForInstructions(typecode, details.Added.Union(details.Updated)).ToList();
            if (errors.Any())
            {
                return ValidationResult.Error(Resources.InstructionsErrorTitle, errors, "I");
            }

            var instructionIds = details.Deleted.Select(_ => short.Parse(_.Id)).ToList();
            errors = ValidateInstructionsInUse(instructionIds).ToList();
            return errors.Any() ? ValidationResult.Error(Resources.InstructionTypeInstructionsInUse, errors, "I") : null;
        }

        IEnumerable<ValidationError> CheckUniquenessForInstructions(string typecode, IEnumerable<DeltaInstruction> modifiedInstructions)
        {
            var existingInstrs = _dbContext.Set<Instruction>()
                                           .Where(_ => string.Equals(_.InstructionTypeCode, typecode))
                                           .ToList();

            foreach (var modifiedInstr in modifiedInstructions)
            {
                var isIdAvailable = short.TryParse(modifiedInstr.Id, out short modifiedId);
                if (existingInstrs.Count(_ => string.Equals(_.Description, modifiedInstr.Description) && !(isIdAvailable && _.Id == modifiedId)) > 0)
                {
                    yield return new ValidationError
                                 {
                                     Id = modifiedInstr.Id,
                                     Message = string.Format(Resources.DescriptionNotUnique, modifiedInstr.Description)
                                 };
                }
            }
        }

        IEnumerable<ValidationError> ValidateInstructionsInUse(ICollection<short> instructionIds)
        {
            if (!instructionIds.Any())
            {
                yield break;
            }

            var instructions = _dbContext.Set<Instruction>()
                                         .Include(_ => _.CaseInstructions)
                                         .Include(_ => _.NameInstructions)
                                         .Where(_ => instructionIds.Contains(_.Id))
                                         .ToList();

            var instructionsUsed = instructions.Where(i => i.NameInstructions != null && i.NameInstructions.Any())
                                               .Select(i => new
                                                            {
                                                                i.Id,
                                                                i.Description
                                                            })
                                               .ToArray();

            foreach (var usedInstruction in instructionsUsed)
            {
                yield return new ValidationError
                             {
                                 Id = usedInstruction.Id.ToString(),
                                 Message = string.Format(Resources.InstructionTypeInstructionsInUseErrorMessage, usedInstruction.Description)
                             };
            }
        }

        ValidationResult ValidateCharacteristics(string typecode, Delta<DeltaCharacteristic> details)
        {
            var errors = CheckUniquenessForCharacteristics(typecode, details.Added.Union(details.Updated)).ToList();
            if (errors.Any())
            {
                return ValidationResult.Error(Resources.CharacteristicsErrorTitle, errors, "C");
            }

            var charIds = details.Deleted.Select(_ => short.Parse(_.Id)).ToList();
            errors = ValidateCharacteristicsInUse(charIds).ToList();
            return errors.Any() ? ValidationResult.Error(Resources.InstructionTypeCharacteristicsInUse, errors, "C") : null;
        }

        IEnumerable<ValidationError> CheckUniquenessForCharacteristics(string typeCode, IEnumerable<DeltaCharacteristic> modifiedCharacteristics)
        {
            var existingChars = _dbContext.Set<Characteristic>()
                                          .Where(_ => string.Equals(_.InstructionTypeCode, typeCode))
                                          .ToList();

            foreach (var modifiedCharacteristic in modifiedCharacteristics)
            {
                var isIdAvailable = short.TryParse(modifiedCharacteristic.Id, out short modifiedId);
                if (existingChars.Count(_ => string.Equals(_.Description, modifiedCharacteristic.Description) && !(isIdAvailable && _.Id == modifiedId)) > 0)
                {
                    yield return new ValidationError
                                 {
                                     Id = modifiedCharacteristic.Id,
                                     Message = string.Format(Resources.DescriptionNotUnique, modifiedCharacteristic.Description)
                                 };
                }
            }
        }

        IEnumerable<ValidationError> ValidateCharacteristicsInUse(ICollection<short> charIds)
        {
            if (!charIds.Any())
            {
                return Enumerable.Empty<ValidationError>();
            }

            const string eventsArea = "Events";
            const string dataValidationArea = "Data Validation";
            const string chargeRatesArea = "Charge Rates";

            var characteristics = _dbContext.Set<Characteristic>()
                                            .Include(_ => _.ChargeRates)
                                            .Include(_ => _.DataValidations)
                                            .Include(_ => _.ValidEvents)
                                            .Where(_ => charIds.Contains(_.Id))
                                            .ToList();

            var usedByChargeRates = characteristics.Where(c => c.ChargeRates != null && c.ChargeRates.Any())
                                                   .Select(c => new CharacteristicInUseError
                                                                {
                                                                    Characteristic = c,
                                                                    UsedBy = string.Join(", ", c.ChargeRates.Select(r => r.ChargeTypeNo)),
                                                                    Area = chargeRatesArea
                                                                });

            var usedByValidEvent = characteristics.Where(c => c.ValidEvents != null && c.ValidEvents.Any())
                                                  .Select(c => new CharacteristicInUseError
                                                               {
                                                                   Characteristic = c,
                                                                   UsedBy = string.Join(", ", c.ValidEvents.Select(v => v.EventId).Distinct()),
                                                                   Area = eventsArea
                                                               });

            var usedByDataValidation = characteristics.Where(c => c.DataValidations != null && c.DataValidations.Any())
                                                      .Select(c => new CharacteristicInUseError
                                                                   {
                                                                       Characteristic = c,
                                                                       UsedBy = string.Join(", ", c.DataValidations.Select(d => d.Id)),
                                                                       Area = dataValidationArea
                                                                   });

            var invalid = usedByChargeRates.Concat(usedByValidEvent).Concat(usedByDataValidation).ToList();

            if (invalid.Any())
            {
                return invalid.GroupBy(_ => _.Characteristic)
                              .Select(group => new {characteristics = group.Key, errors = group.ToList()})
                              .AsEnumerable()
                              .Select(_ => new ValidationError
                                           {
                                               Id = _.characteristics.Id.ToString(),
                                               Message =
                                                   string.Format(Resources.InstructionTypeCharacteristicsInUseErrorMessage,
                                                                 _.characteristics.Description,
                                                                 string.Join(", ", _.errors.Select(e => e.Area + ": " + e.UsedBy)))
                                           });
            }
            return Enumerable.Empty<ValidationError>();
        }
    }

    public class ValidationResult
    {
        public IEnumerable<ValidationError> Errors;
        public string Message;
        public string Result;
        public string Type;

        public static ValidationResult Error(string message, IEnumerable<ValidationError> errors, string type = "")
        {
            return new ValidationResult
                   {
                       Result = "Error",
                       Message = message,
                       Errors = errors,
                       Type = type
                   };
        }
    }

    public class ValidationError
    {
        public string Id;
        public string Message;
    }

    internal class CharacteristicInUseError
    {
        public string Area;
        public Characteristic Characteristic;
        public string UsedBy;
    }
}