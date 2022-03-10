using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Configuration.Core
{
    public interface ICharacteristics
    {
        dynamic ForInstruction(short instructionCode);
        dynamic ForType(int id);
    }

    public class Characteristics : ICharacteristics
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public Characteristics(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public dynamic ForInstruction(short instructionCode)
        {
            var culture = _preferredCultureResolver.Resolve();
            return (from c in _dbContext.Set<Characteristic>()
                    join sc in _dbContext.Set<SelectedCharacteristic>() on c.Id equals sc.CharacteristicId into sc1
                    from sc in sc1.DefaultIfEmpty()
                    where sc.InstructionId == instructionCode && sc != null
                    select new
                           {
                               c.Id,
                               Description = DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture)
                           })
                .ToArray()
                .OrderBy(_ => _.Description);
        }

        public dynamic ForType(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            return (from c in _dbContext.Set<Characteristic>()
                    join i in _dbContext.Set<InstructionType>() on c.InstructionTypeCode equals i.Code into i1
                    from i in i1
                    where i.Id == id
                    select new
                           {
                               c.Id,
                               Description = DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture)
                           })
                .ToArray()
                .OrderBy(_ => _.Description);
        }
    }
}