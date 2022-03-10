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
    public interface ICharacteristicsSaveModel
    {
        void Save(string typeCode, Delta<DeltaCharacteristic> details);
    }

    public class CharacteristicsSaveModel : ICharacteristicsSaveModel
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public CharacteristicsSaveModel(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public void Save(string typeCode, Delta<DeltaCharacteristic> details)
        {
            if (details == null) throw new ArgumentNullException(nameof(details));

            Delete(details.Deleted);
            Add(typeCode, details.Added);
            Update(details.Updated);
        }

        void Add(string typeCode, IEnumerable<DeltaCharacteristic> characteristics)
        {
            foreach (var addCharacteristic in characteristics)
            {
                var newCharacteristicId = (short) _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.InstructionLabel);
                _dbContext.Set<Characteristic>()
                          .Add(new Characteristic
                               {
                                   Id = newCharacteristicId,
                                   Description = addCharacteristic.Description,
                                   InstructionTypeCode = typeCode
                               });

                addCharacteristic.CorrelationId = newCharacteristicId.ToString();
            }

            _dbContext.SaveChanges();
        }

        void Update(IEnumerable<DeltaCharacteristic> characteristics)
        {
            var list = characteristics.ToList();
            var idsToUpdate = list.Select(_ => short.Parse(_.Id));

            var characteristicsToUpdate = _dbContext.Set<Characteristic>().Where(_ => idsToUpdate.Contains(_.Id));
            foreach (var characteristic in characteristicsToUpdate)
                characteristic.Description = list.Single(_ => _.Id == characteristic.Id.ToString()).Description;

            _dbContext.SaveChanges();
        }

        void Delete(IEnumerable<DeltaCharacteristic> characteristics)
        {
            var characteristicIds = characteristics.Select(_ => short.Parse(_.Id)).ToArray();

            var removeSelections = _dbContext.Set<SelectedCharacteristic>()
                                             .Join(characteristicIds, selected => selected.CharacteristicId, id => id, (selected, id) => selected)
                                             .ToList();

            removeSelections.ForEach(_ => _dbContext.Set<SelectedCharacteristic>().Remove(_));

            var removeCharacteristics = _dbContext.Set<Characteristic>()
                                                  .Join(characteristicIds, characteristic => characteristic.Id, id => id, (remove, id) => remove)
                                                  .ToList();

            removeCharacteristics.ForEach(_ => _dbContext.Set<Characteristic>().Remove(_));

            _dbContext.SaveChanges();
        }
    }
}