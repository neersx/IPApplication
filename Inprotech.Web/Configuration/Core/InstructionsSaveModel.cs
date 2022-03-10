using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Configuration.Core
{
    public interface IInstructionsSaveModel
    {
        void Save(string typeCode, Delta<DeltaInstruction> instructions);
    }

    public class InstructionsSaveModel : IInstructionsSaveModel
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public InstructionsSaveModel(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public void Save(string typeCode, Delta<DeltaInstruction> instructions)
        {
            if (instructions == null) throw new ArgumentNullException(nameof(instructions));

            Delete(instructions.Deleted);
            Add(typeCode, instructions.Added);
            Update(instructions.Updated);
        }

        void Add(string typeCode, IEnumerable<DeltaInstruction> instructions)
        {
            foreach (var addInstruction in instructions)
            {
                var charIds = addInstruction.Characteristics.Where(_ => _.Selected).Select(_ => short.Parse(_.Id)).ToList();
                var newInstructionId = (short) _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Instructions);
                var newInstruction = _dbContext.Set<Instruction>()
                                               .Add(new Instruction
                                                    {
                                                        Id = newInstructionId,
                                                        Description = addInstruction.Description,
                                                        InstructionTypeCode = typeCode,
                                                        Characteristics = new List<SelectedCharacteristic>()
                                                    });
                addInstruction.CorrelationId = newInstructionId.ToString();
                charIds.ForEach(_ => newInstruction.Characteristics.Add(new SelectedCharacteristic
                                                                        {
                                                                            CharacteristicId = _
                                                                        }));
            }

            _dbContext.SaveChanges();
        }

        void Update(IEnumerable<DeltaInstruction> instructions)
        {
            foreach (var updateInstruction in instructions)
            {
                var idToUpdate = short.Parse(updateInstruction.Id);
                var instr = _dbContext.Set<Instruction>().Single(_ => _.Id == idToUpdate);
                instr.Description = updateInstruction.Description;

                var charIdsToUnSelect =
                    updateInstruction.Characteristics.Where(_ => !_.Selected).Select(_ => short.Parse(_.Id)).ToArray();
                var removeSelections = _dbContext.Set<SelectedCharacteristic>()
                                                 .Join(charIdsToUnSelect, selected => selected.CharacteristicId, id => id, (selected, id) => selected)
                                                 .ToList();

                removeSelections.ForEach(_ => _dbContext.Set<SelectedCharacteristic>().Remove(_));

                var charIdsToSelect =
                    updateInstruction.Characteristics.Where(_ => _.Selected).Select(_ => short.Parse(_.Id)).ToList();
                charIdsToSelect.ForEach(_ => _dbContext.Set<SelectedCharacteristic>()
                                                       .Add(new SelectedCharacteristic
                                                            {
                                                                InstructionId = idToUpdate,
                                                                CharacteristicId = _
                                                            })
                                       );
            }
            _dbContext.SaveChanges();
        }

        void Delete(IEnumerable<DeltaInstruction> instructions)
        {
            var instructionIds = instructions.Select(_ => short.Parse(_.Id)).ToArray();

            var removeSelections = _dbContext.Set<SelectedCharacteristic>()
                                             .Join(instructionIds, selected => selected.InstructionId, id => id, (selected, id) => selected)
                                             .ToList();

            removeSelections.ForEach(_ => _dbContext.Set<SelectedCharacteristic>().Remove(_));

            var removeInstructions = _dbContext.Set<Instruction>()
                                               .Join(instructionIds, instruction => instruction.Id, id => id, (remove, id) => remove)
                                               .ToList();

            removeInstructions.ForEach(_ => _dbContext.Set<Instruction>().Remove(_));

            _dbContext.SaveChanges();
        }
    }
}