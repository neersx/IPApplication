using System.Linq;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Configuration.Core
{
    public interface IInstructionTypeSaveModel
    {
        bool Save(DeltaInstructionTypeDetails details, out ValidationResult result);
    }

    public class InstructionTypeSaveModel : IInstructionTypeSaveModel
    {
        readonly ICharacteristicsSaveModel _characteristicsSaveModel;
        readonly IDbContext _dbContext;
        readonly IInstructionsSaveModel _instructionsSaveModel;
        readonly IInstructionTypeDetailsValidator _validator;

        public InstructionTypeSaveModel(IDbContext dbContext, IInstructionTypeDetailsValidator validator, ICharacteristicsSaveModel characteristicsSaveModel, IInstructionsSaveModel instructionsSaveModel)
        {
            _dbContext = dbContext;
            _validator = validator;
            _characteristicsSaveModel = characteristicsSaveModel;
            _instructionsSaveModel = instructionsSaveModel;
        }

        public bool Save(DeltaInstructionTypeDetails details, out ValidationResult result)
        {
            var instructionType = _dbContext.Set<InstructionType>().SingleOrDefault(_ => _.Id == details.Id);
            var typeCode = instructionType != null ? instructionType.Code : string.Empty;

            if (!_validator.Validate(typeCode, details, out result))
            {
                return false;
            }

            using (var tcs = _dbContext.BeginTransaction())
            {
                _characteristicsSaveModel.Save(typeCode, details.Characteristics);

                UpdateAddedCharacteristicsIds(details);

                _instructionsSaveModel.Save(typeCode, details.Instructions);

                tcs.Complete();
            }

            return true;
        }

        static void UpdateAddedCharacteristicsIds(DeltaInstructionTypeDetails details)
        {
            if (!details.Characteristics.Added.Any())
            {
                return;
            }

            foreach (var c in details.Characteristics.Added)
            {
                foreach (var i in details.Instructions.Added.Concat(details.Instructions.Updated))
                {
                    var selectedChar = i.Characteristics.SingleOrDefault(_ => _.Id == c.Id);
                    if (selectedChar != null)
                    {
                        selectedChar.Id = c.CorrelationId;
                    }
                }
            }
        }
    }
}